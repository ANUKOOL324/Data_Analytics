"""Honest evaluation against the labeled entity groups.

Metrics:
    blocking pair-completeness  share of true duplicate pairs that
                                survived into the candidate set (a pair
                                lost here can never be found later)
    pairwise precision/recall/F1  on the accepted pairs vs truth
    cluster exactness           share of predicted clusters exactly
                                equal to a true entity's record set
    trap merges                 how many seeded distinct-provider traps
                                were wrongly merged (the chain-merge
                                score; must be 0 with the guard on)

    python -m linker.evaluate --data data/
"""

from __future__ import annotations

import argparse
import json
from itertools import combinations
from pathlib import Path

import pandas as pd

from linker import pipeline


def true_pairs(df: pd.DataFrame, truth: pd.DataFrame) -> set[tuple[int, int]]:
    entity = truth.set_index("record_id")["entity_id"]
    groups: dict[str, list[int]] = {}
    for idx, rid in df["record_id"].items():
        groups.setdefault(entity[rid], []).append(idx)
    out = set()
    for members in groups.values():
        for i, j in combinations(sorted(members), 2):
            out.add((i, j))
    return out


def evaluate(data_dir: Path, budget: int = 2000, seed: int = 42) -> dict:
    df = pd.read_csv(data_dir / "providers.csv", keep_default_na=False)
    truth = pd.read_csv(data_dir / "ground_truth.csv")
    result = pipeline.link(df, truth, budget=budget, seed=seed)

    tp_pairs = true_pairs(df, truth)
    candidates = set(map(tuple, result.pairs[["i", "j"]].to_numpy()))
    pair_completeness = len(tp_pairs & candidates) / len(tp_pairs)

    accepted = set(map(tuple, result.pairs.loc[result.pairs["accepted"],
                                               ["i", "j"]].to_numpy()))
    tp = len(accepted & tp_pairs)
    precision = tp / len(accepted) if accepted else 0.0
    recall = tp / len(tp_pairs)
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0

    # Cluster exactness + trap check
    entity = truth.set_index("record_id")["entity_id"]
    frame = pd.DataFrame({
        "cluster": result.clusters,
        "entity": [entity[r] for r in df["record_id"]],
    })
    exact = 0
    for _, grp in frame.groupby("cluster"):
        if grp["entity"].nunique() == 1:
            entity_id = grp["entity"].iloc[0]
            if len(grp) == (frame["entity"] == entity_id).sum():
                exact += 1
    n_clusters = frame["cluster"].nunique()

    trap_frame = frame[frame["entity"].str.startswith("TRAP")]
    trap_merged = 0
    n_traps = trap_frame["entity"].str.extract(r"(TRAP\d+)_")[0].nunique()
    for _trap, grp in trap_frame.groupby(
        trap_frame["entity"].str.extract(r"(TRAP\d+)_")[0]
    ):
        clusters_a = set(grp.loc[grp["entity"].str.endswith("_0"), "cluster"])
        clusters_b = set(grp.loc[grp["entity"].str.endswith("_1"), "cluster"])
        if clusters_a & clusters_b:
            trap_merged += 1

    return {
        "records": len(df),
        "blocking_pair_completeness": round(pair_completeness, 4),
        "reduction_ratio": round(result.blocking_stats["reduction_ratio"], 5),
        "pairwise_precision": round(precision, 4),
        "pairwise_recall": round(recall, 4),
        "pairwise_f1": round(f1, 4),
        "heldout_pair_f1": round(result.heldout_f1, 4),
        "threshold": result.threshold,
        "clusters": int(n_clusters),
        "cluster_exactness": round(exact / n_clusters, 4),
        "chain_guard_dropped_pairs": result.guard_dropped,
        "trap_pairs_total": int(n_traps),
        "trap_pairs_wrongly_merged": int(trap_merged),
        "labeled_budget": budget,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=Path("data"))
    parser.add_argument("--budget", type=int, default=2000)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    report = evaluate(args.data, args.budget)
    text = json.dumps(report, indent=2)
    print(text)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text)


if __name__ == "__main__":
    main()
