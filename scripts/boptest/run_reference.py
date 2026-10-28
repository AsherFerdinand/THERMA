"""Run the unchanged pinned BOPTEST Co-Simulation FMU, one instance per process.

This is an FMI driver/data exporter, not a Python thermal solver. Run --help.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.metadata
import json
import os
import platform
import subprocess
import sys
import tempfile
import time
import traceback
import xml.etree.ElementTree as ET
from datetime import UTC, datetime
from pathlib import Path
from zipfile import ZipFile

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "configs/references/boptest_bestest_hydronic.json"
SCENARIOS = ROOT / "configs/references/boptest_scenarios.json"
REQUIRED_UNITS = {"reaTRoo_y": "K", "reaQHea_y": "W", "reaPPum_y": "W", "reaCO2RooAir_y": "ppm"}
# Optional INTERNAL names are selected only if actually present in this FMU XML.
INTERNAL = [
    "mod.case900Template.TAir",
    "mod.case900Template.TRad",
    "mod.yOcc.y",
    "mod.hea.Q_flow",
    "mod.rad.Q_flow",
    "mod.rad.QCon_flow",
    "mod.rad.QRad_flow",
    "mod.case900Template.intGaiOcc.portCon.Q_flow",
    "mod.case900Template.intGaiOcc.portRad.Q_flow",
    "mod.case900Template.airModel.preHeaFloLat.Q_flow",
    "mod.rad.m_flow",
    "mod.eta",
    "mod.rad.UAEle",
    "mod.case900Template.n50_int",
    "mod.case900Template.interzonalAirFlow.rho_default",
    "mod.case900Template.interzonalAirFlow.m_flow_nominal_airLea",
    *[f"mod.rad.vol[{i}].T" for i in range(1, 6)],
]


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def write_json(path: Path, value: object) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")
    temporary.replace(path)


def verify_fmu(path: Path, spec: dict) -> dict:
    """Verify bytes and packaged resources BEFORE any native binary is loaded."""
    source = spec["stored_fmu"]["source_id"]
    actual = digest(path)
    if actual != spec["sources"][source]["sha256"]:
        raise ValueError("FMU SHA-256 mismatch; do not substitute or rebuild silently")
    members = []
    with ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("FMU archive CRC failure")
        for expected in spec["stored_fmu"]["members"]:
            data = archive.read(expected["member"])
            sha = hashlib.sha256(data).hexdigest()
            if sha != expected["sha256"]:
                raise ValueError(f"Resource hash mismatch: {expected['member']}")
            members.append({"member": expected["member"], "sha256": sha})
        model = ET.fromstring(archive.read("modelDescription.xml"))
        cs = model.find("CoSimulation")
        if model.get("fmiVersion") != "2.0" or cs is None:
            raise ValueError("Requires original FMI 2.0 Co-Simulation mode")
        if cs.get("needsExecutionTool") != "false":
            raise ValueError("FMU requires an external execution tool")
        if "binaries/linux64/wrapped.so" not in archive.namelist():
            raise ValueError("Missing original Linux x86-64 binary")
    return {
        "sha256": actual,
        "members": members,
        "fmi_mode": "CoSimulation",
        "capabilities": cs.attrib,
    }


def scenario_bounds(scenario: dict, interval: int) -> tuple[int, int, int]:
    start = scenario["evaluation_start_day"] * 86400
    end = scenario["evaluation_end_day"] * 86400
    warmup_start = max(start - scenario["warmup_days"] * 86400, 0)
    if interval <= 0 or not (warmup_start < start < end):
        raise ValueError("Invalid interval or warm-up/evaluation boundaries")
    if (start - warmup_start) % interval or (end - start) % interval:
        raise ValueError("Sampling must land exactly on warm-up/evaluation boundaries")
    if start != (scenario["center_day"] - 7) * 86400 or end - start != 14 * 86400:
        raise ValueError("Scenario differs from pinned BOPTEST window semantics")
    return warmup_start, start, end


def check_data(
    data: np.ndarray, names: list[str], units: dict[str, str], start: int, end: int, interval: int
) -> dict:
    """Contract checks, with no invented model-accuracy acceptance thresholds."""
    if interval <= 0 or start >= end or not names or names[0] != "time_s":
        raise ValueError("Invalid time contract")
    if data.ndim != 2 or data.shape[1] != len(names) or len(set(names)) != len(names):
        raise ValueError("Signal shape or duplicate column names")
    if not np.isfinite(data).all():
        raise ValueError("Unexpected NaN or infinite data")
    t = data[:, 0]
    if len(t) != (end - start) // interval + 1 or t[0] != start or t[-1] != end:
        raise ValueError("Incomplete coverage or incorrect warm-up/evaluation boundaries")
    if not np.all(np.diff(t) == interval):
        raise ValueError("Missing, duplicate, non-monotonic or off-grid timestamps")
    for name, expected in REQUIRED_UNITS.items():
        if name not in names or units.get(name) != expected:
            raise ValueError(f"Missing signal or incorrect unit: {name}")
    for name in ["reaQHea_y", "reaPPum_y"]:
        if (data[:, names.index(name)] < 0).any():
            raise ValueError(f"Negative nonnegative-contract power: {name}")
    for name in ["reaTRoo_y", "weaSta_reaWeaTDryBul_y"]:
        if name not in names or units.get(name) != "K" or (data[:, names.index(name)] <= 0).any():
            raise ValueError(f"Missing/invalid absolute temperature: {name}")
    if (data[:, names.index("reaCO2RooAir_y")] < 0).any():
        raise ValueError("Negative CO2 concentration")
    for name in names:
        if name.endswith("_activate") and np.any(data[:, names.index(name)] != 0):
            raise ValueError("Baseline control override activated")
    if "ovePum_y" in names and not np.isin(data[:, names.index("ovePum_y")], [0, 1]).all():
        raise ValueError("Non-binary pump stage")
    return {
        "status": "passed",
        "samples": len(t),
        "start_s": float(t[0]),
        "end_s": float(t[-1]),
        "interval_s": interval,
        "tolerance_policy": (
            "Exact integer-second grid, exact units and boolean contracts; "
            "powers strictly nonnegative; no fitted accuracy tolerances."
        ),
    }


def energy_kwh(t: np.ndarray, watts: np.ndarray) -> np.ndarray:
    return np.r_[0.0, np.cumsum(0.5 * (watts[1:] + watts[:-1]) * np.diff(t))] / 3_600_000


def make_plots(directory: Path, data: np.ndarray, names: list[str]) -> dict:
    os.environ.setdefault("MPLCONFIGDIR", str(directory / "plot_cache"))
    os.environ.setdefault("XDG_CACHE_HOME", str(directory / "cache"))
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    days = (data[:, 0] - data[0, 0]) / 86400

    def series(name: str) -> np.ndarray:
        return data[:, names.index(name)]

    plots = [
        (
            "operative_temperature",
            [(series("reaTRoo_y") - 273.15, "Operative")],
            "Temperature (degC)",
        ),
        ("gas_input_power", [(series("reaQHea_y"), "Gas input")], "Power (W)"),
        ("pump_electrical_power", [(series("reaPPum_y"), "Pump electrical")], "Power (W)"),
        (
            "outdoor_and_operative",
            [
                (series("reaTRoo_y") - 273.15, "Operative"),
                (series("weaSta_reaWeaTDryBul_y") - 273.15, "Outdoor"),
            ],
            "Temperature (degC)",
        ),
    ]
    gas = energy_kwh(data[:, 0], series("reaQHea_y"))
    pump = energy_kwh(data[:, 0], series("reaPPum_y"))
    plots.append(
        ("cumulative_energy", [(gas, "Gas input"), (pump, "Pump electricity")], "Energy (kWh)")
    )
    for stem, values, ylabel in plots:
        figure, ax = plt.subplots(figsize=(9, 3.5))
        for y, label in values:
            ax.plot(days, y, label=label, linewidth=0.8)
        ax.set(xlabel="Days since evaluation start", ylabel=ylabel, title=directory.name)
        ax.grid(alpha=0.25)
        ax.legend()
        figure.tight_layout()
        figure.savefig(directory / f"{stem}.png", dpi=140)
        plt.close(figure)
    return {
        "gas_input_energy_kwh": float(gas[-1]),
        "pump_electricity_kwh": float(pump[-1]),
        "operative_temperature_min_K": float(series("reaTRoo_y").min()),
        "operative_temperature_max_K": float(series("reaTRoo_y").max()),
        "gas_power_peak_W": float(series("reaQHea_y").max()),
        "pump_power_peak_W": float(series("reaPPum_y").max()),
        "energy_method": (
            "Composite trapezoid of recorded power samples; gas input is "
            "not delivered radiator heat. Event/sampling quadrature error is "
            "not independently bounded."
        ),
    }


def compare_repeat(data: np.ndarray, names: list[str], previous: Path, manifest: dict) -> dict:
    prior = json.loads((previous / "manifest.json").read_text())
    if prior.get("status") != "success":
        raise ValueError("Repeat source was not a successful run")
    for field in [
        "fmu",
        "scenario",
        "sampling",
        "runtime_versions",
        "solver_settings",
        "runner_sha256",
        "source_spec_sha256",
        "scenario_config_sha256",
        "python_version",
        "platform",
        "native_library_hashes",
    ]:
        if prior[field] != manifest[field]:
            raise ValueError(f"Repeat provenance differs: {field}")
    with (previous / "evaluation.csv").open() as stream:
        header = next(csv.reader(stream))
    other = np.loadtxt(previous / "evaluation.csv", delimiter=",", skiprows=1)
    if header != names or data.shape != other.shape or not np.array_equal(data[:, 0], other[:, 0]):
        raise ValueError("Repeat coverage/columns differ")
    return {
        "previous_run": str(previous),
        "exact_numeric_equal": bool(np.array_equal(data, other)),
        "max_absolute_difference": {
            name: float(np.abs(data[:, i] - other[:, i]).max()) for i, name in enumerate(names)
        },
        "tolerance_policy": (
            "No acceptance threshold invented; exact equality is reported, "
            "otherwise differences are reported without a model-accuracy claim."
        ),
    }


def run(args: argparse.Namespace, directory: Path, manifest: dict) -> None:
    from fmpy import extract, read_model_description
    from fmpy.fmi2 import FMU2Slave

    spec = json.loads(SPEC.read_text())
    config = json.loads(SCENARIOS.read_text())
    manifest.update(boptest_commit=config["boptest_commit"], ideas_commit=config["ideas_commit"])
    if (
        config["boptest_commit"] != spec["repositories"]["boptest"]["commit"]
        or config["ideas_commit"] != spec["repositories"]["ideas"]["commit"]
    ):
        raise ValueError("Scenario/source revision mismatch")
    manifest["fmu"] = verify_fmu(args.fmu, spec)
    if platform.system() != "Linux" or platform.machine() not in ["x86_64", "AMD64"]:
        raise ValueError("Stored FMU supports Linux x86-64 only")
    scenario = config["scenarios"][args.scenario]
    interval = config["communication_step_s"]
    warmup_start, start, end = scenario_bounds(scenario, interval)
    manifest["scenario"] = dict(
        name=args.scenario,
        **scenario,
        initialization_time_s=warmup_start,
        evaluation_start_s=start,
        evaluation_end_s=end,
        reset_at_evaluation_start=False,
    )
    manifest["sampling"] = {
        "communication_step_s": interval,
        "measurement_interval_s": interval,
        "internal_integration_step": "Adaptive/embedded; not the communication or resource grid",
    }
    manifest["runtime_versions"] = {
        name: importlib.metadata.version(name) for name in ["fmpy", "numpy", "matplotlib"]
    }
    manifest["python_version"] = sys.version
    manifest["platform"] = platform.platform()
    manifest["runtime_requirements_sha256"] = digest(Path(__file__).with_name("requirements.txt"))
    model = read_model_description(str(args.fmu))
    by_name = {v.name: v for v in model.modelVariables}
    selected = [v for v in model.modelVariables if v.causality in ["output", "input"]]
    selected += [by_name[name] for name in INTERNAL if name in by_name]
    selected = list({v.name: v for v in selected}.values())
    if any(v.type not in ["Real", "Boolean", "Integer", "Enumeration"] for v in selected):
        raise ValueError("Unsupported exported variable type")
    names = ["time_s", *[v.name for v in selected]]
    units = {
        v.name: (
            v.unit or ("1" if v.type in ["Boolean", "Integer", "Enumeration"] else "unspecified")
        )
        for v in selected
    }
    registry = [
        {
            "name": v.name,
            "unit": units[v.name],
            "type": v.type,
            "causality": v.causality,
            "value_reference": v.valueReference,
            "description": v.description,
            "internal": v.name in INTERNAL,
        }
        for v in selected
    ]
    write_json(directory / "signals.json", registry)
    manifest["internal_unavailable"] = [name for name in INTERNAL if name not in by_name]
    manifest["expected_samples"] = (end - warmup_start) // interval + 1
    write_json(directory / "manifest.json", manifest)
    with tempfile.TemporaryDirectory(prefix="therma-boptest-") as temporary:
        extract(str(args.fmu), unzipdir=temporary)
        binary = Path(temporary) / "binaries/linux64/wrapped.so"
        linkage = subprocess.run(["ldd", str(binary)], capture_output=True, text=True, check=False)
        manifest["native_linkage"] = linkage.stdout
        if linkage.returncode or "not found" in linkage.stdout:
            raise RuntimeError(
                "Missing native runtime library; see native_linkage and prepare_native_runtime.sh"
            )
        manifest["native_library_hashes"] = {}
        for line in linkage.stdout.splitlines():
            for part in line.split():
                if part.startswith("/") and Path(part).is_file():
                    manifest["native_library_hashes"][part] = digest(Path(part))
                    provenance = Path(part).parent / "provenance.json"
                    if Path(part).name == "libgfortran.so.4" and provenance.is_file():
                        manifest["native_compatibility_provenance"] = json.loads(
                            provenance.read_text()
                        )
        fmu = FMU2Slave(
            guid=model.guid,
            unzipDirectory=temporary,
            modelIdentifier=model.coSimulation.modelIdentifier,
            instanceName="therma_reference",
        )
        instantiated = False
        try:
            fmu.instantiate()
            instantiated = True
            # No tolerance, state, weather, control, or parameter override is supplied.
            fmu.setupExperiment(startTime=warmup_start, stopTime=end)
            fmu.enterInitializationMode()
            fmu.exitInitializationMode()
            solver_settings = {}
            for v in model.modelVariables:
                if v.name.startswith(("_cs_", "_events_", "_nle_solver_", "_time_events_")):
                    getter = {
                        "Real": fmu.getReal,
                        "Integer": fmu.getInteger,
                        "Boolean": fmu.getBoolean,
                    }.get(v.type)
                    if getter:
                        solver_settings[v.name] = getter([v.valueReference])[0]
            manifest["solver_settings"] = solver_settings
            manifest["tolerance_override"] = None
            manifest["solver_identity"] = (
                "FMU embedded JModelica Co-Simulation solver; numeric ID retained, "
                "not replaced by a Python integrator"
            )
            manifest["initialized_internal_values"] = {
                name: fmu.getReal([by_name[name].valueReference])[0]
                for name in INTERNAL
                if name in by_name
            }
            if "mod.sim.filNam" in by_name:
                weather_name = fmu.getString([by_name["mod.sim.filNam"].valueReference])[0]
                if isinstance(weather_name, bytes):
                    weather_name = weather_name.decode("utf-8")
                manifest["active_weather_resource"] = Path(weather_name).name
                if manifest["active_weather_resource"] != "Brussels.mos":
                    raise ValueError("Unexpected active weather resource")
            write_json(directory / "manifest.json", manifest)
            data = np.empty((manifest["expected_samples"], len(names)), dtype=float)
            groups = [
                (
                    getattr(fmu, method),
                    [(i + 1, v.valueReference) for i, v in enumerate(selected) if v.type in types],
                )
                for method, types in [
                    ("getReal", ["Real"]),
                    ("getBoolean", ["Boolean"]),
                    ("getInteger", ["Integer", "Enumeration"]),
                ]
            ]
            with (directory / "trajectory.csv").open("w", newline="") as stream:
                writer = csv.writer(stream)
                writer.writerow(names)
                for row, t in enumerate(range(warmup_start, end + 1, interval)):
                    if row:
                        fmu.doStep(
                            currentCommunicationPoint=t - interval, communicationStepSize=interval
                        )
                    data[row, 0] = t
                    for getter, variables in groups:
                        if variables:
                            data[row, [i for i, _ in variables]] = getter(
                                [vr for _, vr in variables]
                            )
                    writer.writerow([format(x, ".17g") for x in data[row]])
                    if (t - warmup_start) % 86400 == 0:
                        print(
                            f"{args.scenario}: completed day {t // 86400}, "
                            f"{'evaluation' if t >= start else 'warm-up'}",
                            flush=True,
                        )
                        stream.flush()
            manifest["quality_full"] = check_data(data, names, units, warmup_start, end, interval)
            evaluation = data[data[:, 0] >= start]
            manifest["quality_evaluation"] = check_data(
                evaluation, names, units, start, end, interval
            )
            np.savetxt(
                directory / "evaluation.csv",
                evaluation,
                delimiter=",",
                header=",".join(names),
                comments="",
                fmt="%.17g",
            )
            manifest["metrics"] = make_plots(directory, evaluation, names)
            if args.repeat_of:
                manifest["repeatability"] = compare_repeat(
                    evaluation, names, args.repeat_of, manifest
                )
            fmu.terminate()
        finally:
            if instantiated:
                fmu.freeInstance()
    if digest(args.fmu) != manifest["fmu"]["sha256"]:
        raise ValueError("Source FMU changed during execution")
    manifest["source_fmu_unchanged"] = True
    manifest["artifacts"] = {
        p.name: digest(p) for p in directory.iterdir() if p.is_file() and p.name != "manifest.json"
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fmu", type=Path, required=True)
    parser.add_argument("--scenario", choices=["typical_heat_day", "peak_heat_day"], required=True)
    parser.add_argument("--output-root", type=Path, default=ROOT / "outputs/boptest/runs")
    parser.add_argument("--repeat-of", type=Path)
    args = parser.parse_args()
    args.output_root.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix=args.scenario + "_", dir=args.output_root))
    manifest = {
        "status": "running",
        "started_utc": datetime.now(UTC).isoformat(),
        "runner_sha256": digest(Path(__file__)),
        "scenario_config_sha256": digest(SCENARIOS),
        "source_spec_sha256": digest(SPEC),
    }
    write_json(directory / "manifest.json", manifest)
    print(f"Run directory: {directory}", flush=True)
    started = time.monotonic()
    try:
        run(args, directory, manifest)
        manifest["status"] = "success"
    except Exception as error:
        manifest["status"] = "failed"
        manifest["error"] = {
            "type": type(error).__name__,
            "message": str(error),
            "traceback": traceback.format_exc(),
        }
        print(manifest["error"]["traceback"], file=sys.stderr)
    manifest["elapsed_wall_s"] = time.monotonic() - started
    manifest["finished_utc"] = datetime.now(UTC).isoformat()
    write_json(directory / "manifest.json", manifest)
    print(
        json.dumps(
            {
                "status": manifest["status"],
                "output": str(directory),
                "wall_s": manifest["elapsed_wall_s"],
            }
        ),
        flush=True,
    )
    return 0 if manifest["status"] == "success" else 1


if __name__ == "__main__":
    raise SystemExit(main())
