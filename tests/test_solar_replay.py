"""Small independently constructed synthetic contracts; never simulation evidence."""

import json
from pathlib import Path

import numpy as np
import pytest

from therma.validation.archive import sha256
from therma.validation.replay import INPUTS, prepare, validate_matrix
from therma.validation.solar import (
    C2_INDICES,
    C2_ORDER,
    OPAQUE_VRS,
    PREFIX,
    SOLAR_NAMES,
    distribution,
    prepare_solar,
    verify_packet,
)


def write(path, data):
    path.write_text(json.dumps(data))


def solar_fixture():
    # Independent nonuniform shares distinguish every face and glazing.
    wd = np.array([1, 2, 3, 4, 5, 6, 7], dtype=float) / 28
    wf = wd[::-1]
    wg = np.ones(7) / 7
    direct = np.array([0.0, 100.0, 200.0])
    diffuse = np.array([20.0, 30.0, 40.0])
    gains = np.array([7.0, 14.0, 21.0])
    values = [direct, diffuse, gains]
    values += [np.repeat(x, 3) for weights in [wd, wf, wg] for x in weights]
    values += [-(direct * wd[i] + diffuse * wf[i] + gains * wg[i]) for i in range(7)]
    data = dict(zip(SOLAR_NAMES, values, strict=True))
    units = {n: ("1" if "weightFactor" in n else "W") for n in SOLAR_NAMES}
    return data, units


@pytest.fixture
def runs(tmp_path):
    actual = tmp_path / "source"
    base = tmp_path / "baseline"
    actual.mkdir()
    base.mkdir()
    data, units = solar_fixture()
    t = np.array([0.0, 30.0, 60.0])
    common = {r[0]: np.repeat(293.15 if i == 0 else -10.0, 3) for i, r in enumerate(INPUTS)}
    common["mod.case900Template.TAir"] = np.array([293.15, 294.0, 295.0])
    for root, columns in [(base, common), (actual, common | data)]:
        np.savetxt(
            root / "trajectory.csv",
            np.column_stack([t, *columns.values()]),
            delimiter=",",
            comments="",
            header=",".join(["time_s", *columns]),
        )
        signals = [
            {
                "name": n,
                "unit": units.get(
                    n, "K" if n in [INPUTS[0][0], "mod.case900Template.TAir"] else "W"
                ),
            }
            for n in columns
        ]
        write(root / "signals.json", signals)
        matrix = validate_matrix()
        manifest = {
            "status": "success",
            "source_fmu_unchanged": True,
            "fmu": {"sha256": matrix["fmu_sha256"]},
            "boptest_commit": matrix["boptest_commit"],
            "ideas_commit": "synthetic dependency identity",
            "scenario": {
                "name": "synthetic_contract_fixture",
                "initialization_time_s": 0,
                "evaluation_start_s": 30,
                "evaluation_end_s": 60,
            },
            "artifacts": {
                n: sha256((root / n).read_bytes()) for n in ["trajectory.csv", "signals.json"]
            },
        }
        if root == actual:
            vrs = [
                2509,
                2510,
                2511,
                1601,
                1602,
                1603,
                1604,
                1348,
                1605,
                1606,
                *range(1511, 1525),
                *range(2512, 2519),
            ]
            rows = [
                {"name": n, "unit": units[n], "value_reference": v}
                for n, v in zip(SOLAR_NAMES, vrs, strict=True)
            ]
            states = [
                {
                    "name": f"synthetic_state_{v}",
                    "value_reference": v,
                    "declared_state": True,
                    "unit": "K"
                    if v <= 2044
                    else ("kg" if 2046 <= v <= 2048 else ("1" if v == 2054 else "J")),
                }
                for v in range(2016, 2055)
            ]
            mapping = [
                {"face": face, **next(r for r in states if r["value_reference"] == v)}
                for face, refs in zip(C2_ORDER, OPAQUE_VRS, strict=True)
                for v in refs
            ]
            rows += states + [
                {"name": "mod.case900Template.TAir", "unit": "K", "value_reference": 2439}
            ]
            initial = {r["name"]: 293.15 for r in rows}
            manifest["solar_observability"] = {
                "variables": rows,
                "c2_opaque_mapping": mapping,
                "state_names": [r["name"] for r in states],
                "restorable_fmu_state": False,
                "snapshots": [
                    {"label": "initialized", "time_s": 0, "values": initial},
                    {"label": "evaluation_start", "time_s": 30, "values": initial},
                ],
            }
        write(root / "manifest.json", manifest)
    return actual, base


def test_source_equation_separates_gains_and_preserves_glazing():
    data, units = solar_fixture()
    solar, checks = distribution(data, units)
    np.testing.assert_allclose(solar.sum(axis=1), [20, 130, 240])
    assert checks["status"] == "passed"
    assert solar[1, 6] == pytest.approx(100 * 7 / 28 + 30 / 28)
    assert not np.array_equal(solar[:, 0], -data[PREFIX + "radSurfTot[1].Q_flow"])


@pytest.mark.parametrize("case", ["units", "nan", "negative", "weights", "double_count"])
def test_distribution_rejects_invalid_inputs(case):
    data, units = solar_fixture()
    if case == "units":
        units[SOLAR_NAMES[0]] = "W/m2"
    if case == "nan":
        data[SOLAR_NAMES[0]][1] = np.nan
    if case == "negative":
        data[SOLAR_NAMES[0]][1] = -1
    if case == "weights":
        data[PREFIX + "weightFactorDir[1]"][1] = 2
    if case == "double_count":
        data[PREFIX + "radSurfTot[1].Q_flow"][1] += 10
    with pytest.raises(ValueError):
        distribution(data, units)


def test_packet_opt_in_mapping_and_baseline_preservation(runs, tmp_path):
    run, base = runs
    before = {p: sha256(p.read_bytes()) for d in runs for p in d.iterdir()}
    old = tmp_path / "old"
    prepare(base, old, partial=True)
    old_hash = {p: sha256(p.read_bytes()) for p in old.iterdir()}
    packet = tmp_path / "solar"
    m = prepare_solar(run, base, packet)
    checks = verify_packet(packet)
    inputs = np.loadtxt(packet / "inputs.csv", delimiter=",", skiprows=1)
    solar, _ = distribution(*solar_fixture())
    np.testing.assert_allclose(inputs[:, 6:], solar[:, C2_INDICES])
    assert checks["samples"] == 3 and m["schema_version"] == 2
    assert checks["evaluation_solar_hold_energy_J"]["glazing"] == pytest.approx(solar[1, 6] * 30)
    assert all(sha256(p.read_bytes()) == v for p, v in (before | old_hash).items())
    with pytest.raises(FileExistsError):
        prepare_solar(run, base, packet)


@pytest.mark.parametrize(
    "case", ["schema", "order", "units", "policy", "vr", "scenario", "hash", "grid", "glazing"]
)
def test_packet_rejects_contract_drift(runs, tmp_path, case):
    packet = tmp_path / "packet"
    prepare_solar(*runs, packet)
    m = json.loads((packet / "replay.json").read_text())
    if case == "schema":
        m["schema_version"] = 3
    if case == "order":
        m["c2_solar_order"] = C2_ORDER[::-1]
    if case == "units":
        m["channels"][5]["unit"] = "W/m2"
    if case == "policy":
        m["channels"][5]["interpolation"] = "linear"
    if case == "vr":
        m["solar_signals"][0]["value_reference"] = 999
    if case == "scenario":
        m["source_scenario"]["name"] = "wrong"
    if case == "hash":
        m["inputs_sha256"] = "0" * 64
    if case in ["grid", "glazing"]:
        filename = "inputs.csv" if case == "grid" else "solar_seven.csv"
        path = packet / filename
        header = path.read_text().splitlines()[0]
        data = np.loadtxt(path, delimiter=",", skiprows=1)
        if case == "grid":
            data[1, 0] = 0
        else:
            data[1, -1] = 0
        np.savetxt(path, data, delimiter=",", comments="", header=header)
        m["inputs_sha256" if case == "grid" else "solar_seven_sha256"] = sha256(path.read_bytes())
    write(packet / "replay.json", m)
    with pytest.raises(ValueError):
        verify_packet(packet)


def test_baseline_or_state_mismatch_rejected(runs, tmp_path):
    run, base = runs
    m = json.loads((run / "manifest.json").read_text())
    m["solar_observability"]["snapshots"][0]["values"]["mod.case900Template.TAir"] = 290
    write(run / "manifest.json", m)
    with pytest.raises(ValueError, match="uniform-start"):
        prepare_solar(run, base, tmp_path / "bad")


def test_matlab_solar_schema_and_energy_exports_are_present():
    root = Path(__file__).resolve().parents[1] / "scripts/matlab/boptest"
    loader = (root / "load_boptest_replay.m").read_text()
    assert "ismember(metadata.schema_version,[1 2])" in loader
    assert "seven(:,[2 4 5 3 7 6])" in loader
    assert "all(diff(data(:,1))==30)" in loader
    runner = (root / "run_boptest_zone_replay.m").read_text()
    for name in ["net_external_power", "stored_energy_derivative", "absorbed_solar_power"]:
        assert name in runner
    assert "'q_net_W','dE_dt_W'" in runner


def test_observation_dimensions_and_snapshot_identity(runs, tmp_path):
    run, base = runs
    manifest = json.loads((run / "manifest.json").read_text())
    states = [r for r in manifest["solar_observability"]["variables"] if r.get("declared_state")]
    states[0]["unit"] = "J"
    write(run / "manifest.json", manifest)
    with pytest.raises(ValueError, match="dimension"):
        prepare_solar(run, base, tmp_path / "wrong")


def test_reference_report_is_explicitly_pending_not_simulation_evidence(runs, tmp_path):
    from therma.validation.solar import report_packet

    packet = tmp_path / "packet"
    prepare_solar(*runs, packet)
    result = report_packet(packet, tmp_path / "report", plots=False)
    assert result["solar_resolved_MATLAB_metrics"] is None
    assert result["status"] == "reference_extracted_verified_MATLAB_replay_pending"
