"""linker CLI.

    linker run --data data/ --budget 2000 --out out/

Reads providers.csv (+ ground_truth.csv for the labeled training
budget), writes canonical.csv (one row per entity, survivorship
applied), accepted_pairs.csv, and metrics.json (the honest numbers).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from linker import evaluate


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="linker", description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("run")
    p.add_argument("--data", type=Path, required=True)
    p.add_argument("--budget", type=int, default=2000)
    p.add_argument("--out", type=Path, default=Path("out"))

    args = parser.parse_args(argv)
    try:
        import pandas as pd

        from linker import pipeline

        df = pd.read_csv(args.data / "providers.csv", keep_default_na=False)
        truth = pd.read_csv(args.data / "ground_truth.csv")
        result = pipeline.link(df, truth, budget=args.budget)
        metrics = evaluate.evaluate(args.data, budget=args.budget)
    except (FileNotFoundError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    args.out.mkdir(parents=True, exist_ok=True)
    result.canonical.to_csv(args.out / "canonical.csv", index=False)
    result.pairs[result.pairs["accepted"]].to_csv(
        args.out / "accepted_pairs.csv", index=False
    )
    (args.out / "metrics.json").write_text(json.dumps(metrics, indent=2))

    print(f"{metrics['records']} records -> {metrics['clusters']} entities")
    print(f"precision {metrics['pairwise_precision']:.3f}, "
          f"recall {metrics['pairwise_recall']:.3f}, "
          f"blocking completeness {metrics['blocking_pair_completeness']:.3f}")
    print(f"trap merges: {metrics['trap_pairs_wrongly_merged']}/"
          f"{metrics['trap_pairs_total']}")
    print(f"outputs -> {args.out}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
