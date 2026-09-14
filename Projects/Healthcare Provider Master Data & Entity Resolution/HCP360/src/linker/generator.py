"""Provider registry with labeled duplicate groups.

Each true provider gets 1-4 registry records, mutated the way real
provider data actually diverges: name variants (initials, dropped
middle names, credential suffixes, typos), address abbreviation wars
(Street/St/St.), phone format chaos, missing NPI-style identifiers,
and specialty synonyms. Ground truth (record -> entity id) ships in a
separate file so precision/recall claims are measurable, and a
'hub trap' is seeded deliberately: two DISTINCT providers sharing a
practice address and similar names, the classic chain-merge bait.

    python -m linker.generator --entities 4000 --out data/
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd

FIRST = ["James", "Priya", "Wei", "Sarah", "Mohammed", "Elena", "David", "Amara",
         "Rajesh", "Fatima", "John", "Grace", "Omar", "Lucy", "Chen", "Aisha"]
LAST = ["Smith", "Patel", "Khan", "Jones", "Williams", "Sharma", "Brown", "Taylor",
        "Ahmed", "Wilson", "Davies", "Evans", "Thomas", "Roberts", "Nguyen", "Ali"]
SPECIALTY = {
    "cardiology": ["cardiology", "cardiovascular medicine"],
    "gp": ["general practice", "family medicine", "gp"],
    "orthopedics": ["orthopedics", "orthopaedics", "ortho surgery"],
    "pediatrics": ["pediatrics", "paediatrics"],
}
STREETS = ["High Street", "Station Road", "Church Lane", "Park Avenue", "Victoria Road"]
CITIES = ["Middlesbrough", "Leeds", "York", "Durham", "Newcastle"]
SUFFIXES = ["", "", "", " MD", " Dr", " Jr"]

ABBREV = {"Street": "St", "Road": "Rd", "Avenue": "Ave", "Lane": "Ln"}


def _typo(s: str, rng) -> str:
    if len(s) < 4:
        return s
    i = rng.integers(1, len(s) - 1)
    return s[:i] + s[i + 1] + s[i] + s[i + 2:]


def _variant(base: dict, rng: np.random.Generator) -> dict:
    rec = dict(base)
    # 15% are MOVED providers: new practice, new address/postcode/phone,
    # half of them a new city. Only name (and NPI when present) still
    # links them, which is what makes real-world recall a ceiling, not
    # a rounding error. Added after the first run scored F1 0.999,
    # which said the data was easy, not the linker good.
    if rng.random() < 0.15:
        rec["address"] = f"{rng.integers(1, 300)} {rng.choice(STREETS)}"
        rec["postcode"] = f"TS{rng.integers(1, 30)} {rng.integers(1, 9)}XX"
        rec["phone"] = "".join(str(d) for d in rng.integers(0, 10, 11))
        if rng.random() < 0.5:
            rec["city"] = str(rng.choice(CITIES))
    # name mutations
    roll = rng.random()
    first, last = rec["first_name"], rec["last_name"]
    if roll < 0.25:
        rec["first_name"] = first[0] + "."
    elif roll < 0.4:
        rec["first_name"] = _typo(first, rng)
    elif roll < 0.5:
        rec["last_name"] = _typo(last, rng)
    rec["name_suffix"] = str(rng.choice(SUFFIXES))
    # address mutations
    if rng.random() < 0.5:
        for full, ab in ABBREV.items():
            rec["address"] = rec["address"].replace(full, ab)
    if rng.random() < 0.2:
        rec["address"] = rec["address"].lower()
    # phone format chaos
    digits = rec["phone"]
    fmt = rng.random()
    if fmt < 0.33:
        rec["phone"] = f"{digits[:4]} {digits[4:7]} {digits[7:]}"
    elif fmt < 0.6:
        rec["phone"] = f"({digits[:4]}) {digits[4:]}"
    # npi sometimes missing or fat-fingered
    r = rng.random()
    if r < 0.25:
        rec["npi"] = ""
    elif r < 0.32:
        npi = list(rec["npi"])
        i = int(rng.integers(0, len(npi)))
        npi[i] = str(rng.integers(0, 10))
        rec["npi"] = "".join(npi)
    # specialty synonym
    rec["specialty"] = str(rng.choice(SPECIALTY[rec["_spec_key"]]))
    return rec


def generate(n_entities: int = 4000, seed: int = 42) -> tuple[pd.DataFrame, pd.DataFrame, dict]:
    rng = np.random.default_rng(seed)
    records, truth = [], []
    rid = 0

    def emit(entity_id: str, rec: dict) -> None:
        nonlocal rid
        row = {k: v for k, v in rec.items() if not k.startswith("_")}
        row["record_id"] = f"R{rid:07d}"
        records.append(row)
        truth.append({"record_id": row["record_id"], "entity_id": entity_id})
        rid += 1

    for e in range(n_entities):
        spec_key = str(rng.choice(list(SPECIALTY)))
        street_no = int(rng.integers(1, 300))
        base = {
            "first_name": str(rng.choice(FIRST)),
            "last_name": str(rng.choice(LAST)),
            "name_suffix": "",
            "npi": "".join(str(d) for d in rng.integers(0, 10, 10)),
            "address": f"{street_no} {rng.choice(STREETS)}",
            "city": str(rng.choice(CITIES)),
            "postcode": f"TS{rng.integers(1, 30)} {rng.integers(1, 9)}XX",
            "phone": "".join(str(d) for d in rng.integers(0, 10, 11)),
            "specialty": "",
            "_spec_key": spec_key,
        }
        base["specialty"] = str(rng.choice(SPECIALTY[spec_key]))
        entity = f"E{e:06d}"
        emit(entity, {k: v for k, v in base.items()})
        for _ in range(int(rng.choice([0, 1, 1, 2, 3], p=[0.35, 0.3, 0.2, 0.1, 0.05]))):
            emit(entity, _variant(base, rng))

    # The hub trap: pairs of DISTINCT providers sharing address+postcode
    # with confusable names (same surname, different first names). A
    # linker that chains through shared-address similarity merges them.
    n_traps = max(4, n_entities // 200)
    for t in range(n_traps):
        street_no = int(rng.integers(1, 300))
        shared = {
            "address": f"{street_no} {rng.choice(STREETS)}",
            "city": str(rng.choice(CITIES)),
            "postcode": f"TS{rng.integers(1, 30)} {rng.integers(1, 9)}XX",
        }
        last = str(rng.choice(LAST))
        practice_phone = "".join(str(d) for d in rng.integers(0, 10, 11))
        for j, first in enumerate(rng.choice(FIRST, 2, replace=False)):
            spec_key = str(rng.choice(list(SPECIALTY)))
            base = {
                "first_name": str(first),
                "last_name": last,
                "name_suffix": "",
                "npi": "".join(str(d) for d in rng.integers(0, 10, 10)),
                # Shared practice LINE, not just address: both distinct
                # providers answer the same phone, which is how real
                # group practices bait chain-merges.
                "phone": practice_phone,
                "specialty": str(rng.choice(SPECIALTY[spec_key])),
                "_spec_key": spec_key,
                **shared,
            }
            entity = f"TRAP{t:03d}_{j}"
            emit(entity, base)
            emit(entity, _variant(base, rng))
            # The bridge: an initials-only record ("J. Smith" at the
            # shared practice). It is legitimately ambiguous between the
            # two providers and is what makes transitive chain-merges a
            # real threat instead of a strawman.
            bridge = dict(base)
            bridge["first_name"] = base["first_name"][0] + "."
            emit(entity, bridge)

    df = pd.DataFrame(records).sample(frac=1.0, random_state=seed).reset_index(drop=True)
    truth_df = pd.DataFrame(truth)
    sizes = truth_df.groupby("entity_id").size()
    ledger = {
        "entities": int(sizes.size),
        "records": len(df),
        "duplicate_records": int((sizes - 1).sum()),
        "trap_pairs": n_traps,
    }
    return df, truth_df, ledger


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--entities", type=int, default=4000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--out", type=Path, default=Path("data"))
    args = parser.parse_args()

    df, truth, ledger = generate(args.entities, args.seed)
    args.out.mkdir(parents=True, exist_ok=True)
    df.to_csv(args.out / "providers.csv", index=False)
    truth.to_csv(args.out / "ground_truth.csv", index=False)
    (args.out / "ledger.json").write_text(json.dumps(ledger, indent=2))
    print(json.dumps(ledger, indent=2))


if __name__ == "__main__":
    main()
