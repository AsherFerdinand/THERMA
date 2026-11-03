"""Actual-only C2.7 same-release analysis. No solver or synthetic benchmark generation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path, PurePosixPath
from typing import Any

import numpy as np
from numpy.typing import NDArray

from therma.comparison import resample
from therma.validation.analysis import (
    _pyplot,
    analyze_run,
    file_hash,
    load_replay,
)
from therma.validation.benchmark import day_metrics, metrics, paired
from therma.validation.replay import reference_run

EXPERIMENTS = {"no_solar_30": 30, "solar_30": 30, "solar_15": 15, "solar_5": 5}
REQUIRED = {
    "evaluation.csv",
    "comparison_metadata.json",
    "replay_run.json",
    "solver_metadata.json",
    "energy_events.csv",
}


def load_study(index_file: Path) -> dict[str, Path]:
    """Verify portable receipts and actual metadata before reading candidate data."""
    index = json.loads(index_file.read_text())
    contract_hash = file_hash(index_file.parent / "contract.json")
    if index.get("status") != "completed" or index["contract_sha256"] != contract_hash:
        raise ValueError("Study incomplete or contract hash mismatch")
    if set(index["experiments"]) != set(EXPERIMENTS):
        raise ValueError("Four prescribed experiments required")
    contract = json.loads((index_file.parent / "contract.json").read_text())
    directories = {}
    for name, step in EXPERIMENTS.items():
        item = index["experiments"][name]
        relative = PurePosixPath(item["folder"])
        if (
            relative.is_absolute()
            or ".." in relative.parts
            or "\\" in item["folder"]
            or ":" in item["folder"]
        ):
            raise ValueError("Unsafe study folder")
        folder = index_file.parent.parent / relative
        receipt_path = folder / "completion.json"
        if item["status"] != "completed" or file_hash(receipt_path) != item["completion_sha256"]:
            raise ValueError("Completion receipt mismatch")
        receipt = json.loads(receipt_path.read_text())
        expected = receipt["expected"]
        if (
            receipt["status"] != "completed"
            or expected["experiment_id"] != name
            or expected["contract_sha256"] != contract_hash
            or expected["max_step_s"] != step
            or expected["matlab_version"] != contract["matlab_version"]
        ):
            raise ValueError("Experiment contract mismatch")
        artifacts = receipt["artifacts"]
        names = [a["name"] for a in artifacts]
        if len(set(names)) != len(names) or not REQUIRED <= set(names):
            raise ValueError("Incomplete/duplicate export list")
        for a in artifacts:
            if Path(a["name"]).name != a["name"] or "\\" in a["name"] or ":" in a["name"]:
                raise ValueError("Unsafe artifact filename")
            if file_hash(folder / a["name"]) != a["sha256"]:
                raise ValueError("Export hash mismatch: " + a["name"])
        _, _, report = load_replay(folder)
        solver = json.loads((folder / "solver_metadata.json").read_text())
        if (
            report["matlab_version"] != contract["matlab_version"]
            or report["simulink"] != contract["simulink"]
            or report["replay_packet_sha256"] != expected["packet_sha256"]
            or float(report["solver"]["MaxStep_s"]) != step
            or solver["solver"] != report["solver"]
            or solver["status"] != report["status"]
            or solver["elapsed_simulation_s"] != report["elapsed_simulation_s"]
        ):
            raise ValueError("Mixed release, solver metadata or packet identity")
        directories[name] = folder
    reports = {
        name: json.loads((folder / "replay_run.json").read_text())
        for name, folder in directories.items()
    }
    source_hashes = {r["name"]: r["sha256"] for r in contract["sources"]}
    base = reports["solar_30"]
    for name, r in reports.items():
        if (
            r["driver_source_sha256"] != source_hashes["run_boptest_zone_replay.m"]
            or r["registry_sha256"] != contract["frozen_registry_sha256"]
            or r["assumptions_sha256"] != contract["assumptions_sha256"]
            or not np.isfinite(r["elapsed_simulation_s"])
            or r["elapsed_simulation_s"] < 0
        ):
            raise ValueError("Runtime/source provenance differs from contract")
        for k in ["registry_sha256", "assumptions_sha256", "model_version", "driver_source_sha256"]:
            if r[k] != base[k]:
                raise ValueError("Mixed implementation/parameters: " + k)
        for k in ["name", "RelTol", "AbsTol"]:
            if r["solver"][k] != base["solver"][k]:
                raise ValueError("Solver family/tolerances differ")
        if name.startswith("solar") and r["replay_packet_sha256"] != base["replay_packet_sha256"]:
            raise ValueError("Solar packets differ")
    return directories


def event_balance(path: Path) -> tuple[dict[str, Any], NDArray[np.float64]]:
    """Preserve duplicate event records; zero-width intervals add no spurious heat."""
    names = [
        "stored_thermal_energy",
        "net_external_power",
        "stored_energy_derivative",
        "prescribed_power",
        "power_balance_residual",
    ]
    # Parse ordered event records separately to preserve duplicate timestamps.
    with path.open() as f:
        header = f.readline().strip().split(",")
    if header != ["time_s", *names]:
        raise ValueError("Event export columns differ")
    data = np.loadtxt(path, delimiter=",", skiprows=1, ndmin=2)
    if (
        data.shape[1] != 6
        or len(data) < 2
        or not np.isfinite(data).all()
        or np.any(np.diff(data[:, 0]) < 0)
    ):
        raise ValueError("Invalid ordered event data")
    t, e, q, derivative, _, residual = data.T
    dt = np.diff(t)
    integrated = np.r_[0.0, np.cumsum(dt * (q[:-1] + q[1:]) / 2)]
    discrepancy = e - e[0] - integrated
    if t[-1] <= t[0]:
        raise ValueError("Zero event interval")
    return {
        "method": "trapezoid of ordered original logs; duplicate event intervals have zero width",
        "start_s": float(t[0]),
        "end_s": float(t[-1]),
        "samples": len(t),
        "duplicate_timestamps": int(np.sum(dt == 0)),
        "maximum_absolute_discrepancy_J": float(np.max(abs(discrepancy))),
        "final_discrepancy_J": float(discrepancy[-1]),
        "maximum_instantaneous_residual_W": float(np.max(abs(residual))),
        "derivative_accounting_discrepancy_W": float(np.max(abs(derivative - q - residual))),
        "limitation": "Event sides retained where logged; no convergence pass inferred.",
    }, np.column_stack([t, e - e[0], integrated, discrepancy])


def analyze_study(
    index: Path, reference: Path, output: Path, *, plots: bool = True
) -> dict[str, Any]:
    folders = load_study(index)
    collections = {name: load_replay(folder)[0] for name, folder in folders.items()}
    reports = {name: load_replay(folder)[2] for name, folder in folders.items()}
    ref_manifest, ref_data, units = reference_run(reference, "evaluation.csv")
    sp = reports["solar_30"]["replay_metadata"]
    if (
        file_hash(reference / "manifest.json") != sp["reference_manifest_sha256"]
        or units["mod.case900Template.TAir"] != "K"
        or ref_manifest["scenario"] != sp["source_scenario"]
    ):
        raise ValueError("Reference identity mismatch")
    t = np.asarray(ref_data["time_s"], dtype=float)
    if (
        not np.all(np.diff(t) == 30)
        or t[0] != sp["evaluation_start_s"]
        or t[-1] != sp["evaluation_end_s"]
    ):
        raise ValueError("Native evaluation grid mismatch")
    ref = np.asarray(ref_data["mod.case900Template.TAir"], dtype=float)
    aligned = {name: resample(s["air_temperature"], t) for name, s in collections.items()}
    balances = {}
    traces = {}
    for name, folder in folders.items():
        balances[name], traces[name] = event_balance(folder / "energy_events.csv")
        if balances[name]["start_s"] != t[0] or balances[name]["end_s"] != t[-1]:
            raise ValueError("Energy log evaluation coverage differs")
    result = {
        "status": "actual_controlled_benchmark_not_real_world_validation",
        "matlab_version": reports["solar_30"]["matlab_version"],
        "temperature_metrics": {name: metrics(y - ref) for name, y in aligned.items()},
        "daily_errors": {name: day_metrics(t, y - ref) for name, y in aligned.items()},
        "step_differences": {
            name + "_minus_solar_5": metrics(aligned[name] - aligned["solar_5"])
            for name in ["solar_30", "solar_15"]
        },
        "successive_refinement_difference": metrics(aligned["solar_30"] - aligned["solar_15"]),
        "energy_balances": balances,
        "simulation_runtime_s": {name: r["elapsed_simulation_s"] for name, r in reports.items()},
        "solver_settings": {name: r["solver"] for name, r in reports.items()},
        "reference_manifest_sha256": file_hash(reference / "manifest.json"),
        "limitations": [
            "The 5 s run is another numerical approximation, not an exact solution.",
            "No convergence threshold or order inferred from three adaptive maximum steps.",
            "Runtime is sim() wall time, excluding separate compile/export; PC load affects it.",
            "Stability evidence is finite full-period outputs, not a general stability proof.",
        ],
    }
    output.mkdir(parents=True, exist_ok=False)
    paired(
        folders["no_solar_30"], folders["solar_30"], reference, output / "controlled", plots=plots
    )
    for name in ["solar_15", "solar_5"]:
        analyze_run(folders[name], output / name, reference, plots=plots)
    if plots:
        import shutil

        plt = _pyplot(output)
        for old, new in [
            ("controlled_comparison", "figure_1_temperature"),
            ("temperature_errors", "figure_2_error"),
            ("daily_errors", "figure_4_daily"),
        ]:
            for ext in ["png", "pdf"]:
                shutil.copyfile(output / f"controlled/{old}.{ext}", output / f"{new}.{ext}")
        fig, ax = plt.subplots(figsize=(10, 4))
        for name in ["solar_30", "solar_15"]:
            ax.plot(
                (t - t[0]) / 86400,
                aligned[name] - aligned["solar_5"],
                lw=0.8,
                label=name + " minus solar_5",
            )
        ax.set(xlabel="Evaluation day", ylabel="Air temperature difference (K)")
        ax.grid(alpha=0.25)
        ax.legend()
        fig.tight_layout()
        for ext in ["png", "pdf"]:
            fig.savefig(output / f"figure_3_solver.{ext}", dpi=300)
        plt.close(fig)
        fig, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
        tr = traces["solar_30"]
        axes[0].plot((tr[:, 0] - t[0]) / 86400, tr[:, 1] / 1e6, label="Storage change")
        axes[0].plot((tr[:, 0] - t[0]) / 86400, tr[:, 2] / 1e6, label="Net-power integral")
        for name in ["solar_30", "solar_15", "solar_5"]:
            tr = traces[name]
            axes[1].plot((tr[:, 0] - t[0]) / 86400, tr[:, 3] / 1000, lw=0.8, label=name)
        axes[0].set(ylabel="Energy (MJ)")
        axes[1].set(ylabel="Closure discrepancy (kJ)", xlabel="Evaluation day")
        for ax in axes:
            ax.grid(alpha=0.25)
            ax.legend()
        fig.tight_layout()
        for ext in ["png", "pdf"]:
            fig.savefig(output / f"figure_5_energy.{ext}", dpi=300)
        plt.close(fig)
        fig, ax = plt.subplots(figsize=(10, 4))
        for quantity in ["delivered_heating_power", "absorbed_solar_power", "internal_gain_power"]:
            v = collections["solar_30"][quantity]
            ax.plot((v.time_s - t[0]) / 86400, v.values / 1000, lw=0.8, label=quantity)
        ax.set(xlabel="Evaluation day", ylabel="Prescribed power (kW)")
        ax.legend()
        ax.grid(alpha=0.25)
        fig.tight_layout()
        for ext in ["png", "pdf"]:
            fig.savefig(output / f"figure_6_inputs.{ext}", dpi=300)
        plt.close(fig)
    (output / "study_metrics.json").write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")
    return result


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--study-index", type=Path, required=True)
    p.add_argument("--reference", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    analyze_study(args.study_index, args.reference, args.output)


if __name__ == "__main__":
    main()
