"""An inaccessible Annex58 dataset must not inherit Annex71/default geometry."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_annex58_identity_and_explicit_unknowns():
    c = json.loads((ROOT / "configs/buildings/annex58_experiment1.json").read_text())
    assert c["dataset"]["annex"] == 58 and c["dataset"]["experiment"] == 1
    assert c["dataset"]["doi"] == "10.15129/8a86bbbb-7be8-4a87-be76-0372985ea228"
    assert c["dataset"]["reported_period"]["start_date"] == "2013-08-21"
    assert not c["ready_for_simulink_implementation"]
    assert c["geometry"]["footprint_m2"] is None
    assert c["geometry"]["storeys"] is None
    for field in ["zones", "surfaces", "constructions", "windows", "adjacent_zone_connections"]:
        assert c["geometry"][field] == []
    assert c["environment"]["initial_conditions"] is None
    assert c["measurements"]["signals"] == []
    assert c["measurements"]["sampling_interval_s"] is None
    assert len({frozenset(s) for s in c["source_files"]}) == 1  # MATLAB struct array
    for source in c["source_files"]:
        assert source["published_download_url"] is None and source["sha256"] is None


def test_missing_input_entry_cannot_fabricate_measurements():
    source = (ROOT / "run_c42_reference_inspection.m").read_text()
    for forbidden in ["sim(", "plot(", "writetable(", "savetxt", "rand("]:
        assert forbidden not in source
    assert "inspection_summary.json" in source
    assert "actual_zone_count_known',false" in source
    assert "content_verified',false" in source
    assert "processed_measurements_created',false" in source
