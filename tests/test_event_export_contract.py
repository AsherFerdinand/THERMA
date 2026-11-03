"""Static guards only; actual MATLAB IO regressions run in the offline package."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scripts/matlab/boptest"


def test_event_export_is_bounded_precision_checked_and_not_a_large_table():
    writer = (ROOT / "boptest_export_energy_events.m").read_text()
    assert "array2table" not in writer and "writetable" not in writer
    assert "%.17g,%.17g,%.17g,%.17g,%.17g,%.17g" in writer
    assert "options.ChunkRows" in writer
    assert "sum(logs.prescribed_inputs(indices,2:11),2)" in writer
    assert writer.index("boptest_verify_energy_csv(staging,expected)") < writer.index(
        "copyfile(staging,resources.TemporaryFile)"
    )
    assert "fwrite(fid,uint8(text),'uint8')" in writer
    assert "count==numel(text)" in writer and "writtenRows==expected" in writer
    assert "boptest_file_sha256(file),checksum" in writer


def test_streaming_verifier_keeps_duplicate_order_and_counts_columns():
    source = (ROOT / "boptest_verify_energy_csv.m").read_text()
    assert "fread(fid,requested,'*uint8')" in source
    assert "requested=min(1024*1024,fileBytes-position)" in source
    assert "rows==expectedRows" in source
    assert "all(diff(block(:,1))>=0)" in source
    assert "unique(" not in source
    assert "commas(endings)" in source
    assert "THERMA:EventCSVTruncated" in source
    assert "readmatrix" not in source


def test_export_failure_cannot_mark_run_completed_and_retains_diagnostics():
    runner = (ROOT / "run_boptest_zone_replay.m").read_text()
    assert "report.stage = 'export_energy_events'" in runner
    assert "report.status = 'failed'; report.export_completed = false" in runner
    catch = runner[runner.index("catch problem") :]
    assert "report.energy_event_export.status='failed'" in catch
    source = (ROOT / "boptest_export_energy_events.m").read_text()
    for field in [
        "matlab_version",
        "target_file",
        "directory_exists",
        "estimated_numeric_bytes",
        "available_disk_space_bytes",
        "row_count",
    ]:
        context = (ROOT / "boptest_event_export_context.m").read_text()
        assert field in context
    assert "boptest_exception_diagnostic(problem)" in source
    assert "failure=addCause(failure,problem)" in source
    assert "THERMA:EventDestinationExists" in source
    resume = (ROOT / "boptest_c27_completed.m").read_text()
    assert "isfield(report,'export_completed') && ~report.export_completed" in resume
    assert "exported.status,'verified'" in resume


def test_reader_is_count_and_position_bounded_not_numeric_eof_classification():
    source = (ROOT / "boptest_verify_energy_csv.m").read_text()
    assert "while position<fileBytes" in source
    assert "count~=requested || nextPosition~=position+requested" in source
    assert "ftell(fid)~=fileBytes" in source
    assert "number==-1" not in source and "number==-4" not in source
    assert "fgetl(" not in source
    assert "digest.update(typecast(bytes(:),'int8'))" in source
    assert "rows==expectedRows" in source and "isempty(pending)" in source
    writer = (ROOT / "boptest_export_energy_events.m").read_text()
    assert "strcmp(checksum,verified.sha256)" in writer


def test_plain_diagnostic_path_and_structured_metadata_both_preserve_original():
    writer = (ROOT / "boptest_export_energy_events.m").read_text()
    tests = (ROOT.parents[2] / "tests/matlab/test_boptest_event_export.m").read_text()
    assert "Event export failed for %s. Context: %s" in writer
    assert "diagnostic.target_file,file" in tests
    assert "diagnostic.original_exception.identifier,'THERMA:EventDirectory'" in tests


def test_cleanup_owns_state_without_capturing_destroyed_parent_variables():
    source = (ROOT / "boptest_export_energy_events.m").read_text()
    owner = (ROOT / "BoptestEventExportResources.m").read_text()
    assert "onCleanup(@() resources.cleanup())" in source
    assert "function cleanupOwned" not in source
    assert "function removeTemporary" not in source
    assert "onCleanup(@cleanupOwned)" not in source
    assert owner.index("obj.FileId=-1") < owner.index("fclose(fileId)")
    assert "verified final file" in owner
