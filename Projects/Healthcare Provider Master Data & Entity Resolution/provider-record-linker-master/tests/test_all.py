import json
import sys

import numpy as np
import pandas as pd
import pytest

from linker import evaluate, pipeline
from linker.generator import generate


@pytest.fixture(scope="module")
def demo():
    return generate(n_entities=1200, seed=5)


def test_normalizers():
    assert pipeline.normalize_name("James", "Smith", " MD") == "james smith"
    assert pipeline.normalize_address("12 High Street") == \
        pipeline.normalize_address("12 High St")
    assert pipeline.digits("(0164) 249 8x81") == "0164249881"


def test_blocking_completeness_and_reduction(demo):
    df, truth, _ = demo
    pairs, stats = pipeline.candidate_pairs(df)
    tp = evaluate.true_pairs(df, truth)
    candidates = set(map(tuple, pairs[["i", "j"]].to_numpy()))
    completeness = len(tp & candidates) / len(tp)
    assert completeness > 0.85
    assert stats["reduction_ratio"] > 0.95


def test_features_shape(demo):
    df, _, _ = demo
    pairs, _ = pipeline.candidate_pairs(df)
    feats = pipeline.pair_features(df, pairs)
    assert len(feats) == len(pairs)
    assert feats.notna().all().all()
    assert set(feats["first_conflict"].unique()) <= {0.0, 1.0}


def test_first_conflict_semantics(demo):
    df = pd.DataFrame(
        {
            "record_id": ["a", "b", "c"],
            "first_name": ["James", "John", "J."],
            "last_name": ["Smith"] * 3,
            "name_suffix": [""] * 3,
            "npi": [""] * 3,
            "address": ["1 High Street"] * 3,
            "city": ["Leeds"] * 3,
            "postcode": ["TS1 1XX"] * 3,
            "phone": ["01234567890"] * 3,
            "specialty": ["gp"] * 3,
        }
    )
    pairs = pd.DataFrame({"i": [0, 0, 1], "j": [1, 2, 2]})
    feats = pipeline.pair_features(df, pairs)
    # James vs John: conflict. James vs J.: compatible. John vs J.: compatible.
    assert list(feats["first_conflict"]) == [1.0, 0.0, 0.0]


def test_constraint_clustering_refuses_bridge_weld():
    """Two full-name providers + an initials bridge, all edges accepted:
    the cluster step must keep James and John apart."""
    df = pd.DataFrame(
        {
            "record_id": ["a", "b", "c"],
            "first_name": ["James", "John", "J."],
            "last_name": ["Smith"] * 3,
            "name_suffix": [""] * 3,
            "npi": [""] * 3,
            "address": ["1 High Street"] * 3,
            "city": ["Leeds"] * 3,
            "postcode": ["TS1 1XX"] * 3,
            "phone": ["01234567890"] * 3,
            "specialty": ["gp"] * 3,
        }
    )
    pairs = pd.DataFrame({"i": [0, 1, 0], "j": [2, 2, 1]})
    feats = pipeline.pair_features(df, pairs)
    scores = np.array([0.95, 0.90, 0.85])  # all above threshold
    labels, _, refused = pipeline.cluster(df, pairs, feats, scores, 0.5)
    assert labels.iloc[0] != labels.iloc[1], "James and John must not merge"
    assert refused >= 1


def test_npi_overrides_name_conflict():
    """Same NPI is proof of identity even when full names disagree
    (legal name change); the constraint must yield."""
    df = pd.DataFrame(
        {
            "record_id": ["a", "b"],
            "first_name": ["Priya", "Sarah"],
            "last_name": ["Patel", "Patel"],
            "name_suffix": [""] * 2,
            "npi": ["1234567890"] * 2,
            "address": ["1 High Street"] * 2,
            "city": ["Leeds"] * 2,
            "postcode": ["TS1 1XX"] * 2,
            "phone": ["01234567890"] * 2,
            "specialty": ["gp"] * 2,
        }
    )
    pairs = pd.DataFrame({"i": [0], "j": [1]})
    feats = pipeline.pair_features(df, pairs)
    labels, _, refused = pipeline.cluster(df, pairs, feats, np.array([0.9]), 0.5)
    assert labels.iloc[0] == labels.iloc[1]
    assert refused == 0


def test_end_to_end_metrics(demo, tmp_path):
    df, truth, ledger = demo
    df.to_csv(tmp_path / "providers.csv", index=False)
    truth.to_csv(tmp_path / "ground_truth.csv", index=False)
    (tmp_path / "ledger.json").write_text(json.dumps(ledger))
    report = evaluate.evaluate(tmp_path, budget=800)
    assert report["pairwise_precision"] > 0.9
    assert report["pairwise_recall"] > 0.8
    assert report["trap_pairs_wrongly_merged"] == 0


def test_survivorship_prefers_complete_records(demo):
    df, truth, _ = demo
    result = pipeline.link(df, truth, budget=800)
    canon = result.canonical
    assert len(canon) == result.clusters.nunique()
    assert (canon["members"] >= 1).all()


def test_generator_cli(tmp_path, monkeypatch):
    from linker import generator

    monkeypatch.setattr(sys, "argv",
                        ["gen", "--entities", "200", "--out", str(tmp_path)])
    generator.main()
    assert (tmp_path / "providers.csv").exists()
    ledger = json.loads((tmp_path / "ledger.json").read_text())
    assert ledger["duplicate_records"] > 0
