"""C4.0 is a presentation wrapper; verified equations and settings stay untouched."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_four_physical_subsystems_and_preserved_main_connections():
    builder = (ROOT / "scripts/matlab/c40/c40_build_model.m").read_text()
    for name in ["Building Thermal Zone", "Room Thermostat", "Control Valve", "Hydronic Radiator"]:
        assert name in builder
    assert "Simulink.BlockDiagram.createSubsystem(handles)" in builder
    assert "c38_build_case(folder,1,Z,P,room,baseline.source_model,baseline.names)" in builder
    assert "sourcePort(line)==a.Outport" in builder
    for forbidden in [
        "add_c3_radiator(",
        "add_c3_thermostat(",
        "'Solver',",
        "'RelTol',",
        "'MaxStep',",
    ]:
        assert forbidden not in builder


def test_one_simulation_one_plot_and_actual_baseline_gate():
    entry = (ROOT / "run_c40_heating_system.m").read_text()
    compare = (ROOT / "scripts/matlab/c40/c40_compare.m").read_text()
    assert entry.count("output=sim(") == 1
    assert entry.count("fig=figure(") == 1
    assert "c38_read_baseline(" in entry and "c38_check_trace(" in entry
    assert "assert(~isempty(baseline)" in entry
    assert "comparison.passed" in entry and "baseline.sources" in entry
    assert "demand_samples_identical" in compare
    assert "baseline_transitions==S.current_transitions" in compare
