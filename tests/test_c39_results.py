"""Reused actual C2.8 metrics and explicit quantity/energy qualifications."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_c39_preserves_c28_air_metrics_and_input_provenance():
    old = json.loads((ROOT / "docs/results/c28/metrics.json").read_text())
    new = json.loads((ROOT / "docs/results/c39/metrics.json").read_text())
    assert new["metrics"] == old["metrics"]["solar_30"]
    assert new["temperature_quantity"] == "air_temperature"
    assert new["reference_temperature_source"] == "mod.case900Template.TAir"
    assert new["excluded_operative_source"] == "reaTRoo_y"
    assert new["sample_count"] == old["sample_count"] == 40321
    assert not new["MATLAB_executed_in_cloud"]
    heat = new["heating_energy"]
    assert max(heat["component_max_discrepancy_W"].values()) < 1e-7
    assert abs(heat["reference_30s_hold_kWh"] - 529.3861941632234) < 1e-9
    assert abs(heat["THERMA_logged_hold_kWh"] - heat["reference_on_log_grid_hold_kWh"]) < 1e-9
    assert heat["source_negative_power_samples"] > 0
    provenance = json.loads((ROOT / "docs/results/c28/provenance.json").read_text())
    assert new["source_provenance"]["solar_30"] == provenance["solar_30"]


def test_readonly_entry_has_exactly_two_plots_and_reuses_quantity_checks():
    entry = (ROOT / "run_c39_boptest_comparison.m").read_text()
    helper = (ROOT / "scripts/matlab/c39/c39_metrics.m").read_text()
    assert entry.count("fig=figure(") == 2
    assert "sim(" not in entry and "compare_boptest_c28(" not in entry
    assert "boptest_temperature_metrics(" in helper
    assert "delivered_zone_heat" in helper
    assert "mod.case900Template.TAir" in helper
