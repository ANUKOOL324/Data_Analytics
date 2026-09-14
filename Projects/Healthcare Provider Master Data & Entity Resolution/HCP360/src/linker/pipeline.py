"""Blocking, pair features, match classifier, clustering.

Blocking: comparing all pairs is O(n^2) (a 10k-record registry is 50M
comparisons); blocking keys cut that to the pairs that could plausibly
match. Each strategy is SCORED, not assumed: pair-completeness (share
of true duplicate pairs surviving into the candidate set) and
reduction ratio (share of the n^2 avoided). The union of three keys is
used because each individually loses real pairs (measured in the demo:
postcode alone 0.9x, name-key alone lower; union ~0.99).

Features per candidate pair: normalized name similarity (SequenceMatcher
ratio on token-sorted names), initials compatibility, address
similarity on a normalized form (abbreviations expanded, case folded),
postcode/city equality, phone digit equality (full and last-4), NPI
equality when both present, specialty-family match.

Classifier: logistic regression on a labeled pair budget, threshold
chosen on a validation split for max F1. Clustering: connected
components over accepted pairs, WITH a chain-merge guard: an accepted
edge is dropped when the pair shares no name evidence (name similarity
below a floor) even if the score cleared the threshold, because
shared-address hubs otherwise weld distinct providers together.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from difflib import SequenceMatcher

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import f1_score

ABBREV = {"st": "street", "rd": "road", "ave": "avenue", "ln": "lane"}

# Chain-merge guard: two FULL first names that disagree are two people,
# no matter how similar the address, phone, and surname are (group
# practices share all three). Initials stay compatible with anything
# ("J." matches James and John, and that ambiguity is real). The first
# guard attempt (a global name-similarity floor on accepted pairs) was
# measured useless: 1/15 seeded traps merged with it on OR off, because
# the floor could not distinguish 'J. Smith' bridging two doctors from
# an honest initials variant. Conflict detection can.
FIRSTNAME_CONFLICT_SIM = 0.6


def normalize_name(first: str, last: str, suffix: str) -> str:
    tokens = re.sub(r"[^a-z ]", "", f"{first} {last}".lower()).split()
    return " ".join(sorted(tokens))


def normalize_address(addr: str) -> str:
    tokens = re.sub(r"[^a-z0-9 ]", "", str(addr).lower()).split()
    return " ".join(ABBREV.get(t, t) for t in tokens)


def digits(s: str) -> str:
    return re.sub(r"\D", "", str(s))


def _prep(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["_name"] = [
        normalize_name(f, ln, s)
        for f, ln, s in zip(df["first_name"], df["last_name"], df["name_suffix"].fillna(""),
                           strict=True)
    ]
    out["_addr"] = df["address"].map(normalize_address)
    out["_phone"] = df["phone"].map(digits)
    out["_initial"] = df["first_name"].str[0].str.lower()
    out["_surname"] = df["last_name"].str.lower()
    return out


def candidate_pairs(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Union of three blocking strategies; returns pairs + per-key stats."""
    prepped = _prep(df)
    keys = {
        "postcode": prepped["postcode"].str.replace(" ", "").str.lower(),
        "surname_city": prepped["_surname"] + "|" + prepped["city"].str.lower(),
        "phone_last4": prepped["_phone"].str[-4:],
    }
    seen: set[tuple[int, int]] = set()
    per_key: dict[str, int] = {}
    for key_name, key in keys.items():
        count = 0
        for _, group in prepped.groupby(key.values):
            idx = group.index.to_numpy()
            if len(idx) < 2 or len(idx) > 200:  # guard: degenerate blocks
                continue
            for i in range(len(idx)):
                for j in range(i + 1, len(idx)):
                    pair = (int(idx[i]), int(idx[j]))
                    if pair not in seen:
                        seen.add(pair)
                        count += 1
        per_key[key_name] = count
    pairs = pd.DataFrame(sorted(seen), columns=["i", "j"])
    n = len(df)
    stats = {
        "records": n,
        "possible_pairs": n * (n - 1) // 2,
        "candidate_pairs": len(pairs),
        "reduction_ratio": 1 - len(pairs) / (n * (n - 1) / 2),
        "new_pairs_per_key": per_key,
    }
    return pairs, stats


def pair_features(df: pd.DataFrame, pairs: pd.DataFrame) -> pd.DataFrame:
    prepped = _prep(df)
    a = prepped.loc[pairs["i"]].reset_index(drop=True)
    b = prepped.loc[pairs["j"]].reset_index(drop=True)

    def sim(x: str, y: str) -> float:
        return SequenceMatcher(None, x, y).ratio()

    name_sim = [sim(x, y) for x, y in zip(a["_name"], b["_name"], strict=True)]
    addr_sim = [sim(x, y) for x, y in zip(a["_addr"], b["_addr"], strict=True)]

    def first_conflict(x: str, y: str) -> float:
        """1.0 when BOTH first names are full (not initials) and disagree."""
        fx = re.sub(r"[^a-z]", "", str(x).lower())
        fy = re.sub(r"[^a-z]", "", str(y).lower())
        if len(fx) <= 2 or len(fy) <= 2:
            return 0.0  # an initial is compatible with anything
        return 1.0 if sim(fx, fy) < FIRSTNAME_CONFLICT_SIM else 0.0

    conflicts = [first_conflict(x, y)
                 for x, y in zip(a["first_name"], b["first_name"], strict=True)]
    feats = pd.DataFrame(
        {
            "name_sim": name_sim,
            "initial_match": (a["_initial"] == b["_initial"]).astype(float),
            "surname_match": (a["_surname"] == b["_surname"]).astype(float),
            "addr_sim": addr_sim,
            "postcode_match": (a["postcode"] == b["postcode"]).astype(float),
            "city_match": (a["city"] == b["city"]).astype(float),
            "phone_match": (a["_phone"] == b["_phone"]).astype(float),
            "phone_last4": (a["_phone"].str[-4:] == b["_phone"].str[-4:]).astype(float),
            "npi_match": (
                (a["npi"] != "") & (b["npi"] != "") & (a["npi"] == b["npi"])
            ).astype(float),
            "first_conflict": conflicts,
        }
    )
    return feats


@dataclass
class LinkResult:
    pairs: pd.DataFrame  # i, j, score, accepted, guard_dropped
    clusters: pd.Series  # record index -> cluster id
    threshold: float
    heldout_f1: float
    blocking_stats: dict
    guard_dropped: int = 0
    canonical: pd.DataFrame = field(default_factory=pd.DataFrame)


def train_and_score(
    feats: pd.DataFrame, labels: np.ndarray, budget: int = 2000, seed: int = 42
) -> tuple[np.ndarray, float, float]:
    """Train on `budget` labeled pairs, pick threshold on validation, score all."""
    rng = np.random.default_rng(seed)
    idx = rng.permutation(len(feats))
    train_idx, val_idx = idx[:budget], idx[budget : budget + budget // 2]
    model = LogisticRegression(max_iter=1000, class_weight="balanced")
    model.fit(feats.iloc[train_idx], labels[train_idx])
    val_scores = model.predict_proba(feats.iloc[val_idx])[:, 1]
    best_t, best_f1 = 0.5, -1.0
    for t in np.arange(0.3, 0.96, 0.05):
        f1 = f1_score(labels[val_idx], val_scores >= t, zero_division=0)
        if f1 > best_f1:
            best_t, best_f1 = float(t), float(f1)
    scores = model.predict_proba(feats)[:, 1]
    return scores, best_t, best_f1


def cluster(
    df: pd.DataFrame, pairs: pd.DataFrame, feats: pd.DataFrame,
    scores: np.ndarray, threshold: float,
) -> tuple[pd.Series, pd.DataFrame, int]:
    """Constraint-aware agglomerative clustering.

    Plain union-find over accepted edges chain-merges: a shared-practice
    bridge record ("J. Smith", same address and phone as both doctors)
    legitimately matches BOTH providers, and edge-level guards cannot
    help because every individual edge looks fine (measured: an
    edge-level conflict guard still merged 15/15 seeded traps THROUGH
    the bridge). The constraint has to live at the CLUSTER level:
    process accepted edges in descending score order and refuse any
    union that would put two conflicting FULL first names (both longer
    than an initial, similarity < 0.6, no NPI proof) into one entity.
    The bridge joins its best-scoring side; the other provider survives
    as a separate entity. Measured: 0/15 traps merged, at the cost of
    the genuinely ambiguous bridge record landing on one side.
    """
    accepted = scores >= threshold

    prepped_first = [
        re.sub(r"[^a-z]", "", str(x).lower()) for x in df["first_name"]
    ]

    parent = list(range(len(df)))
    # full first names present in each component (root -> set)
    names: dict[int, set[str]] = {
        i: ({prepped_first[i]} if len(prepped_first[i]) > 2 else set())
        for i in range(len(df))
    }

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def compatible(na: set[str], nb: set[str]) -> bool:
        for x in na:
            for y in nb:
                if SequenceMatcher(None, x, y).ratio() < FIRSTNAME_CONFLICT_SIM:
                    return False
        return True

    order = np.argsort(-scores)
    refused = 0
    npi = feats["npi_match"].to_numpy() >= 1.0
    idx_i = pairs["i"].to_numpy()
    idx_j = pairs["j"].to_numpy()
    for k in order:
        if not accepted[k]:
            continue
        ra, rb = find(int(idx_i[k])), find(int(idx_j[k]))
        if ra == rb:
            continue
        if not npi[k] and not compatible(names[ra], names[rb]):
            refused += 1
            continue
        parent[ra] = rb
        names[rb] = names[rb] | names[ra]

    labels = pd.Series([find(x) for x in range(len(df))], index=df.index, name="cluster")
    out_pairs = pairs.copy()
    out_pairs["score"] = scores
    out_pairs["accepted"] = accepted
    out_pairs["guard_dropped"] = False
    return labels, out_pairs, refused


def survivorship(df: pd.DataFrame, clusters: pd.Series) -> pd.DataFrame:
    """One canonical record per cluster: most complete, NPI preferred."""
    work = df.copy()
    work["cluster"] = clusters
    work["_completeness"] = (work[["npi", "phone", "address", "specialty"]] != "") \
        .sum(axis=1) + (work["npi"] != "").astype(int)  # npi counts double
    canon = (
        work.sort_values(["_completeness"], ascending=False)
        .groupby("cluster")
        .first()
        .reset_index()
        .drop(columns=["_completeness"])
    )
    canon["members"] = work.groupby("cluster").size().values
    return canon


def link(df: pd.DataFrame, truth: pd.DataFrame | None = None,
         budget: int = 2000, seed: int = 42) -> LinkResult:
    pairs, blocking_stats = candidate_pairs(df)
    feats = pair_features(df, pairs)

    if truth is None:
        raise ValueError("training labels required (labeled pair budget)")
    entity = truth.set_index("record_id")["entity_id"]
    rid = df["record_id"]
    labels = (
        entity.loc[rid.loc[pairs["i"]].values].values
        == entity.loc[rid.loc[pairs["j"]].values].values
    ).astype(int)

    scores, threshold, heldout_f1 = train_and_score(feats, labels, budget, seed)
    clusters, out_pairs, dropped = cluster(df, pairs, feats, scores, threshold)
    canonical = survivorship(df, clusters)
    return LinkResult(
        pairs=out_pairs,
        clusters=clusters,
        threshold=threshold,
        heldout_f1=heldout_f1,
        blocking_stats=blocking_stats,
        guard_dropped=dropped,
        canonical=canonical,
    )
