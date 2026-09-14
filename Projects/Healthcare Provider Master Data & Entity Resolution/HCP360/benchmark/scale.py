"""Linkage runtime and quality vs registry size.

    python benchmark/scale.py --sizes 2000 5000 10000
"""

from __future__ import annotations

import argparse
import json
import platform
import time
from pathlib import Path

from linker.evaluate import evaluate
from linker.generator import generate


def run(entities: int, tmp: Path) -> dict:
    df, truth, ledger = generate(n_entities=entities, seed=17)
    tmp.mkdir(parents=True, exist_ok=True)
    df.to_csv(tmp / "providers.csv", index=False)
    truth.to_csv(tmp / "ground_truth.csv", index=False)
    (tmp / "ledger.json").write_text(json.dumps(ledger))
    t0 = time.perf_counter()
    report = evaluate(tmp, budget=min(2000, len(df) // 3))
    seconds = time.perf_counter() - t0
    return {
        "entities": entities,
        "records": report["records"],
        "seconds": round(seconds, 1),
        "precision": report["pairwise_precision"],
        "recall": report["pairwise_recall"],
        "reduction_ratio": report["reduction_ratio"],
        "trap_merges": report["trap_pairs_wrongly_merged"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sizes", type=int, nargs="+", default=[2000, 5000, 10000])
    parser.add_argument("--out", type=Path, default=Path("benchmark/results/scale.json"))
    args = parser.parse_args()
    import tempfile

    results = []
    for s in args.sizes:
        with tempfile.TemporaryDirectory() as tmp:
            results.append(run(s, Path(tmp)))
            print(results[-1])
    payload = {
        "environment": {"python": platform.python_version(),
                        "note": "2-core cloud container"},
        "results": results,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
