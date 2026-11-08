"""Small metadata guards, not native MATLAB or empirical validation tests."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_authentic_inspection_provenance_and_contiguous_selection() -> None:
    audit = json.loads((ROOT / "docs/results/c42b/source_audit.json").read_text())
    assert audit["source_commit"] == "265312ec3843c97d5a24b7d5671ee2891f326af6"
    assert audit["selected_core_complete"]
    assert not audit["matlab_executed"]
    assert not audit["simulation_performed"]
    assert len(audit["selected_core_files"]) == 6
    assert len(audit["csv_audit"]) == 20
    for source in audit["files"]:
        assert source["bytes"] > 0
        assert len(source["sha256"]) == 64
        assert audit["source_commit"] in source["source"]
    for item in audit["csv_audit"]:
        assert item["selected_nonfinite_cells"] == 0
        assert item["selected_missing_cells"] == 0
        if item["path"].endswith("WestWall heat flux.csv"):
            assert item["selected_rows"] == 172
            assert item["selected_absent_timestamps"] == 549
        else:
            assert item["selected_rows"] == 721
            assert item["selected_absent_timestamps"] == 0


def test_native_entry_preserves_source_bytes_and_does_not_simulate() -> None:
    text = (ROOT / "run_c42b_flexlab_inspection.m").read_text()
    assert "boptest_file_sha256(file)" in text
    assert "isequal(times(selected),expected)" in text
    assert "all(isfinite(values(selected,:)),'all')" in text
    assert "'simulation_performed',false" in text
    assert "'empirical_validation_performed',false" in text
    assert "sim(" not in text
    assert "writetable(" not in text
