"""Read-only physical-check scope and source-derived static arithmetic."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_geometry_and_water_limited_power_from_existing_parameters():
    registry = json.loads((ROOT / "configs/references/boptest_bestest_hydronic.json").read_text())
    p = {entry["id"]: entry["value"] for entry in registry["parameters"]}
    assert p["building.floor_area"] == 48
    assert p["building.volume"] == 129.6
    assert p["building.window_area"] == 12
    radiator = json.loads((ROOT / "configs/c3/illustrative_components.json").read_text())[
        "parameters"
    ]
    h = radiator["nominal_flow_kg_s"]["value"] * radiator["water_cp_J_kgK"]["value"]
    power = [h * ua / (h + ua) * 34 for ua in [60, 180]]
    assert 1379 < power[0] < 1381
    assert 2512 < power[1] < 2514


def test_entrypoint_reads_existing_cases_without_simulation_and_has_only_two_plots():
    source = (ROOT / "run_c36_physical_check.m").read_text()
    for forbidden in ["sim(", "build_c34_model(", "run_c35_investigation(", "new_system("]:
        assert forbidden not in source
    assert source.count("fig=figure(") == 2
    assert "completion_sha256" in source and "integration_trajectory.csv" in source
    assert "A_UA_180" in source and "case_result.json" in source


def test_actual_case_reports_match_original_receipt_and_analysis():
    """Receipt checks cover supplied reports, not absent study contracts/logs."""
    import hashlib

    analysis = json.loads((ROOT / "docs/results/c36/physical_check.json").read_text())
    for case in analysis["cases"]:
        folder = ROOT / "verification/c3/c36" / case["case_id"]
        receipt_bytes = (folder / "completion.json").read_bytes()
        report_bytes = (folder / "case_result.json").read_bytes()
        receipt = json.loads(receipt_bytes)
        report = json.loads(report_bytes)
        hashes = {item["name"]: item["sha256"] for item in receipt["artifacts"]}
        assert hashlib.sha256(report_bytes).hexdigest() == hashes["case_result.json"]
        assert hashlib.sha256(receipt_bytes).hexdigest() == case["sha256"]["completion.json"]
        assert hashes["integration_trajectory.csv"] == case["sha256"]["integration_trajectory.csv"]
        assert receipt["expected"]["study_contract_sha256"] == analysis["study_contract_sha256"]
        assert report["case_definition"] == receipt["expected"]["case_definition"]
        assert report["metrics"]["checks_passed"]
        observed = report["metrics"]["reach_21_0_s"]
        if observed < 0:
            assert case["first_21C_h"] is None
        else:
            assert abs(observed / 3600 - case["first_21C_h"]) < 1e-10
        assert abs(case["delivered_kWh"] - case["loss_kWh"] - case["zone_storage_kWh"]) < 1e-8
