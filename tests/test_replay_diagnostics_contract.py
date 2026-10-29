"""Static MATLAB guards only; actual exception/source regressions live in MATLAB."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scripts/matlab/boptest"


def test_recursive_serialization_preserves_every_cause_and_stack():
    source = (ROOT / "boptest_exception_diagnostic.m").read_text()
    assert "boptest_exception_diagnostic(problem.cause{j})" in source
    for field in ("'identifier'", "'message'", "'stack'", "'causes'", "'extended_report'"):
        assert field in source
    for field in ("frames(j).file", "frames(j).name", "frames(j).line"):
        assert field in source
    assert "getReport(problem,'extended','hyperlinks','off')" in source


def test_runner_writes_diagnostic_before_throw_and_retains_original_cause():
    source = (ROOT / "run_boptest_zone_replay.m").read_text()
    catch = source[source.index("catch problem") :]
    assert catch.index("boptest_exception_diagnostic(problem)") < catch.index(
        "write_boptest_json(reportFile,report)"
    )
    assert catch.index("write_boptest_json(reportFile,report)") < catch.index(
        "print_boptest_exception(problem,reportFile)"
    )
    assert catch.index("print_boptest_exception(problem,reportFile)") < catch.index(
        "throw(failure)"
    )
    assert "failure = addCause(failure,problem)" in catch
    assert "assert(strcmp(report.status" not in source
    for stage in ("compile", "simulate", "export"):
        assert f"report.stage = '{stage}'" in source
    assert "result = sim(simulationInput)" in source


def test_driver_uses_explicit_timeseries_and_model_workspace_bindings():
    source = (ROOT / "configure_boptest_replay_sources.m").read_text()
    assert "signal = timeseries(values,time,'Name',variable)" in source
    assert "signal = setinterpmethod(signal,method)" in source
    assert "assignin(workspace,variable,signal)" in source
    assert "input.setVariable(variable,signal,'Workspace',model)" in source
    assert "interpolate = 'on'; method = 'linear'" in source
    assert "interpolate = 'off'; method = 'zoh'" in source
    assert "'SampleTime','0'" in source and "'ZeroCross','on'" in source
    assert "sprintf('Inputs/%d',channel)" in source
    assert "assignin(workspace,variable,[time values])" not in source


def test_from_workspace_final_hold_and_coverage_are_explicit():
    source = (ROOT / "configure_boptest_replay_sources.m").read_text()
    assert "'OutputAfterFinalValue','Holding final value'" in source
    assert "data(end,1)>=metadata.duration_s" in source
    assert "isfinite(metadata.duration_s)" in source
    assert source.index("'THERMA:ReplayDriverCoverage'") < source.index("add_block(")
    assert "'output_after_final_value','Holding final value'" in source
    assert "interpolate = 'off'; method = 'zoh'" in source
    assert "interpolate = 'on'; method = 'linear'" in source


def test_driver_coverage_uses_model_interval_before_binding():
    helper = (ROOT / "configure_boptest_replay_sources.m").read_text()
    assert "requestedStop==metadata.duration_s" in helper
    assert "data(end,1)>=requestedStop" in helper
    runner = (ROOT / "run_boptest_zone_replay.m").read_text()
    assert runner.index("set_param(model,'StartTime','0','StopTime'") < runner.index(
        "configure_boptest_replay_sources(model,metadata,data)"
    )
