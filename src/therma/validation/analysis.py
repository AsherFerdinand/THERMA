"""Read-only C2 replay analysis and original-FMU heating sign audit.

No thermal solver, calibration or clamping. Numerical analysis requires the actual
three MATLAB export files. The source-only audit never manufactures C2 outputs.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
import os
from dataclasses import replace
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from therma.comparison import Interpolation, Series, compare, convert, integrate, resample
from therma.validation.archive import REGISTRY_HASH, ROOT, digest, read_json
from therma.validation.replay import validate_matrix

Array = NDArray[np.float64]
REQUIRED = {
    "air_temperature": "K",
    "outdoor_temperature": "K",
    "delivered_heating_power": "W",
    "delivered_heating_convective_power": "W",
    "delivered_heating_radiative_power": "W",
    "ventilation_sensible_power": "W",
    "stored_thermal_energy": "J",
    "power_balance_residual": "W",
}
OPTIONAL = {
    "opaque_mean_surface_temperature": "K",
    "internal_convective_power": "W",
    "internal_radiative_power": "W",
    "net_external_power": "W",
}
SOURCE_CONV = "mod.rad.QCon_flow"
SOURCE_RAD = "mod.rad.QRad_flow"
SOURCE_AIR = "mod.case900Template.TAir"


def file_hash(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def numeric_columns(path: Path, columns: list[str]) -> tuple[Array, dict[str, Array]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        header = next(csv.reader(stream))
    if len(header) != len(set(header)):
        raise ValueError("Duplicate CSV column names")
    missing = set(["time_s", *columns]) - set(header)
    if missing:
        raise ValueError(f"Missing CSV columns: {sorted(missing)}")
    selected = [header.index(name) for name in ["time_s", *columns]]
    # Parse only needed numeric columns, not all FMU variables or simulation.mat.
    data = np.loadtxt(
        path, delimiter=",", skiprows=1, usecols=selected, ndmin=2, encoding="utf-8-sig"
    )
    if len(data) < 2 or not np.isfinite(data).all() or np.any(np.diff(data[:, 0]) <= 0):
        raise ValueError(
            "At least two finite samples and strictly increasing times "
            "required; do not average duplicate events"
        )
    return data[:, 0], {name: data[:, j + 1] for j, name in enumerate(columns)}


def statistics(values: Array) -> dict[str, float]:
    return {
        "minimum": float(np.min(values)),
        "maximum": float(np.max(values)),
        "mean_sample_weighted": float(np.mean(values)),
        "rms_sample_weighted": float(np.sqrt(np.mean(values**2))),
    }


def signed_power(time: Array, values: Array, policy: Interpolation) -> dict[str, Any]:
    # Signed negative-energy area is derived for diagnostics only. Raw powers stay
    # unchanged. For linear samples, split crossing intervals analytically.
    dt = np.diff(time)
    left, right = values[:-1], values[1:]
    if policy == "previous":
        negative_J = float(np.sum(dt[left < 0] * left[left < 0]))
        negative_duration = float(np.sum(dt[left < 0]))
    elif policy == "linear":
        negative_J = 0.0
        negative_duration = 0.0
        for a, b, duration in zip(left, right, dt, strict=True):
            if a <= 0 and b <= 0:
                negative_J += float((a + b) * duration / 2)
                if a < 0 or b < 0:
                    negative_duration += float(duration)
            elif a < 0 < b:
                fraction = float(-a / (b - a))
                width = float(duration * fraction)
                negative_J += float(a * width / 2)
                negative_duration += width
            elif b < 0 < a:
                fraction = float(-b / (a - b))
                width = float(duration * fraction)
                negative_J += float(b * width / 2)
                negative_duration += width
    else:
        raise ValueError("Unsupported power reconstruction")
    return {
        **statistics(values),
        "unit": "W",
        "negative_sample_count": int(np.sum(values < 0)),
        "negative_duration_s_reconstructed": negative_duration,
        "negative_signed_energy_J_reconstructed": negative_J,
        "signed_energy_J_reconstructed": integrate(time, values, policy),
        "interpolation": policy,
        "values_modified": False,
    }


def load_replay(run_dir: Path) -> tuple[dict[str, Series], dict[str, Any], dict[str, Any]]:
    paths = {
        name: run_dir / name
        for name in ("evaluation.csv", "comparison_metadata.json", "replay_run.json")
    }
    missing = [name for name, path in paths.items() if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"Upload actual MATLAB files; missing: {', '.join(missing)}")
    metadata = read_json(paths["comparison_metadata.json"].read_bytes())
    report = read_json(paths["replay_run.json"].read_bytes())
    if (
        metadata.get("schema_version") != 1
        or metadata.get("classification") != "exploratory_comparison"
    ):
        raise ValueError("Unsupported comparison metadata schema/classification")
    if report.get("status") != "executed_partial_not_validated" or any(
        report.get(k) is not True for k in ("matlab_execution_completed", "simulation_returned")
    ):
        raise ValueError("Replay did not complete; inspect original nested diagnostics instead")
    if report.get("model_name") != "THERMA_BOPTEST_ThermalZone_C2":
        raise ValueError("Unexpected replay model")
    packet = report["replay_metadata"]
    scenario = packet["source_scenario"]
    if metadata["scenario_id"] != packet["scenario_id"] or (
        metadata["model_version"] != report["model_version"]
        or metadata["reference_version"] != packet["reference_version"]
        or packet["reference_scenario_id"] != scenario["name"]
    ):
        raise ValueError("Inconsistent experiment/model/reference identity")
    if report.get("registry_sha256") != REGISTRY_HASH:
        raise ValueError("Unexpected frozen parameter registry")
    csv_hash = file_hash(paths["evaluation.csv"])
    if csv_hash != digest(metadata["csv_sha256"]):
        raise ValueError("Evaluation CSV hash differs from comparison metadata")
    if (
        packet["evaluation_start_s"] != scenario["evaluation_start_s"]
        or packet["evaluation_end_s"] != scenario["evaluation_end_s"]
        or packet["time_origin_s"] != scenario["initialization_time_s"]
        or packet["duration_s"] != packet["evaluation_end_s"] - packet["time_origin_s"]
    ):
        raise ValueError("Inconsistent warm-up/evaluation boundaries")
    if "start_time_s" in report and float(report["start_time_s"]) != 0:
        raise ValueError("Replay solver time must start at relative zero")
    if "stop_time_s" in report and float(report["stop_time_s"]) != packet["duration_s"]:
        raise ValueError("Replay solver stop differs from declared full duration")
    if "drivers" in report:
        drivers = report["drivers"]
        if not isinstance(drivers, list) or len(drivers) != 11:
            raise ValueError("Expected eleven source-driver diagnostics")
        for j, driver in enumerate(drivers, start=1):
            if (
                driver["block"] != f"Replay_Source_{j:02d}"
                or driver["samples"] < 2
                or driver["first_time_s"] > 0
                or driver["last_time_s"] < packet["duration_s"]
            ):
                raise ValueError("Driver ordering/coverage inconsistent with full replay")
            expected_policy = "linear" if j == 1 else "previous"
            expected_interpolate = "on" if j == 1 else "off"
            if (
                driver.get("interpolation") != expected_policy
                or driver.get("block_interpolate") != expected_interpolate
            ):
                raise ValueError("Driver interpolation differs from intended linear/ZOH policies")
    signals = metadata["signals"]
    by_quantity = {s["quantity"]: s for s in signals}
    if len(by_quantity) != len(signals) or not REQUIRED.keys() <= by_quantity.keys():
        raise ValueError("Missing/duplicate required physical quantities")
    quantities = [q for q in [*REQUIRED, *OPTIONAL] if q in by_quantity]
    columns = [by_quantity[q].get("column", q) for q in quantities]
    if len(set(columns)) != len(columns):
        raise ValueError("A CSV column cannot represent multiple quantities")
    time, data = numeric_columns(paths["evaluation.csv"], columns)
    if time[0] != packet["evaluation_start_s"] or time[-1] != packet["evaluation_end_s"]:
        raise ValueError(
            "Evaluation coverage differs or warm-up was not excluded; no "
            "automatic trimming/time shift"
        )
    result = {}
    for q, column in zip(quantities, columns, strict=True):
        spec = by_quantity[q]
        unit = (REQUIRED | OPTIONAL)[q]
        values = convert(data[column], spec["unit"], unit)
        result[q] = Series(
            time,
            values,
            unit,
            q,
            spec["interpolation"],
            metadata["scenario_id"],
            metadata["model_version"],
            metadata["reference_version"],
            csv_hash,
        )
    return result, metadata, report


def sampling(time: Array) -> dict[str, Any]:
    delta = np.diff(time)
    return {
        "samples": len(time),
        "start_s": float(time[0]),
        "end_s": float(time[-1]),
        "duration_s": float(time[-1] - time[0]),
        "minimum_step_s": float(delta.min()),
        "maximum_step_s": float(delta.max()),
        "median_step_s": float(np.median(delta)),
        "uniform_grid": bool(
            np.allclose(
                delta, delta[0], rtol=0, atol=64 * np.spacing(max(1.0, float(abs(time).max())))
            )
        ),
    }


def _read_reference(
    run: Path, packet: dict[str, Any] | None = None, *, need_heating: bool = True
) -> tuple[Array, dict[str, Array], dict[str, Any]]:
    manifest_path = run / "manifest.json"
    manifest = read_json(manifest_path.read_bytes())
    matrix = validate_matrix()
    if manifest.get("status") != "success" or manifest.get("source_fmu_unchanged") is not True:
        raise ValueError("Reference run failed or FMU changed")
    if (
        manifest["fmu"]["sha256"] != matrix["fmu_sha256"]
        or manifest["boptest_commit"] != matrix["boptest_commit"]
    ):
        raise ValueError("Reference FMU/version mismatch")
    if packet is not None:
        if file_hash(manifest_path) != packet["reference_manifest_sha256"] or (
            manifest["scenario"]["name"] != packet["reference_scenario_id"]
            or manifest["boptest_commit"] != packet["reference_version"]
            or manifest["scenario"]["initialization_time_s"] != packet["time_origin_s"]
            or manifest["artifacts"]["trajectory.csv"] != packet["source_trajectory_sha256"]
            or manifest["artifacts"]["signals.json"] != packet["source_signals_sha256"]
        ):
            raise ValueError("Replay and reference provenance/scenario mismatch")
    for name in ("evaluation.csv", "signals.json"):
        if file_hash(run / name) != manifest["artifacts"][name]:
            raise ValueError("Reference artifact hash mismatch: " + name)
    definitions = json.loads((run / "signals.json").read_bytes())
    units = {item["name"]: item["unit"] for item in definitions}
    required = {SOURCE_AIR: "K"}
    if need_heating:
        required.update({SOURCE_CONV: "W", SOURCE_RAD: "W"})
    if any(units.get(name) != unit for name, unit in required.items()):
        raise ValueError(
            "Reference air/split heat signal missing or incorrect units; "
            "never substitute operative temperature"
        )
    time, columns = numeric_columns(run / "evaluation.csv", list(required))
    if (
        time[0] != manifest["scenario"]["evaluation_start_s"]
        or time[-1] != manifest["scenario"]["evaluation_end_s"]
    ):
        raise ValueError("Reference evaluation coverage invalid")
    return time, columns, manifest


def reference_sign_audit(run: Path) -> dict[str, Any]:
    time, data, manifest = _read_reference(run)
    conv, rad = -data[SOURCE_CONV], -data[SOURCE_RAD]
    return {
        "scope": "original_BOPTEST_only_not_THERMA_results",
        "scenario": manifest["scenario"],
        "source_manifest_sha256": file_hash(run / "manifest.json"),
        "source_csv_sha256": file_hash(run / "evaluation.csv"),
        "sampling": sampling(time),
        "mapping": {"convective": f"-{SOURCE_CONV}", "radiative": f"-{SOURCE_RAD}"},
        "convective": signed_power(time, conv, "previous"),
        "radiative": signed_power(time, rad, "previous"),
        "total": signed_power(time, conv + rad, "previous"),
        "interpretation": (
            "Source heat-port powers are negated for heat delivered to the "
            "room. Negative delivered power is reverse exchange, not "
            "negative fuel consumption; no clamping."
        ),
        "limitations": [
            "Audit describes source samples only, not unavailable THERMA data.",
            "Hold integrals reconstruct sampled data, not exact continuous FMU energy.",
            "Temperature-cause attribution needs radiator and radiative/air state inspection.",
        ],
    }


def _find_reference(packet: dict[str, Any]) -> Path | None:
    for path in sorted((ROOT / "outputs/boptest/runs").glob("*/manifest.json")):
        if file_hash(path) == packet["reference_manifest_sha256"]:
            return path.parent
    return None


def reference_comparison(
    series: dict[str, Series], packet: dict[str, Any], reference: Path | None
) -> tuple[dict[str, Any], Series | None]:
    if reference is None:
        return {
            "status": "blocked",
            "reason": "Matching original reference trajectory unavailable",
            "metrics": None,
        }, None
    try:
        time, data, manifest = _read_reference(reference, packet, need_heating=False)
        candidate = series["air_temperature"]
        ref = Series(
            time,
            data[SOURCE_AIR],
            "K",
            "air_temperature",
            "linear",
            candidate.scenario,
            manifest["fmu"]["sha256"],
            manifest["boptest_commit"],
            file_hash(reference / "evaluation.csv"),
            max_gap_s=30,
        )
        # A fixed reference grid avoids weighting errors by THERMA's adaptive
        # solver sample density. Temperature is continuous; no extrapolation.
        aligned_candidate = replace(candidate, time_s=time, values=resample(candidate, time))
        metrics = compare(ref, aligned_candidate)
        metrics["analysis_grid"] = {
            "method": "native reference grid; candidate temperature piecewise linear",
            "original_candidate_samples": len(candidate.time_s),
            "samples": len(time),
            "maximum_error_scope": "sampled reference timestamps only",
        }
        try:
            signs = reference_sign_audit(reference)
            heat_time, heat_data, _ = _read_reference(reference)
            alignment = {}
            for source, quantity in (
                (SOURCE_CONV, "delivered_heating_convective_power"),
                (SOURCE_RAD, "delivered_heating_radiative_power"),
            ):
                h = series[quantity]
                source_series = Series(
                    heat_time,
                    -heat_data[source],
                    "W",
                    quantity,
                    "previous",
                    h.scenario,
                    ref.model_version,
                    ref.reference_version,
                    ref.source_sha256,
                )
                alignment[quantity] = compare(source_series, h)
            signs["actual_input_alignment"] = alignment
            signs["alignment_limit"] = (
                "Raw input errors may include different one-sided logs at exact switching "
                "instants; do not silently smooth or clamp."
            )
        except (OSError, ValueError, KeyError) as problem:
            signs = {"status": "blocked", "reason": str(problem)}
        return {
            "status": "available_exploratory_only",
            "classification": "exploratory_comparison",
            "physical_quantity": "air_temperature_not_operative",
            "source_variable": SOURCE_AIR,
            "reference_scenario_id": manifest["scenario"]["name"],
            "candidate_scenario_id": candidate.scenario,
            "pairing": (
                "Explicit partial experiment corresponding to original period; "
                "scenarios are not physically identical"
            ),
            "warmup_excluded": True,
            "reference_sampling": sampling(time),
            "metrics": metrics,
            "source_heating_sign_audit": signs,
        }, ref
    except (OSError, ValueError, KeyError) as problem:
        return {"status": "blocked", "reason": str(problem), "metrics": None}, None


def engineering_checks(series: dict[str, Series], report: dict[str, Any]) -> dict[str, Any]:
    def get(name: str) -> Array:
        return series[name].values

    time = series["air_temperature"].time_s
    total = get("delivered_heating_power")
    conv = get("delivered_heating_convective_power")
    rad = get("delivered_heating_radiative_power")
    accounting = total - conv - rad
    scale = max(1.0, float(np.max(abs(total))), float(np.max(abs(conv))), float(np.max(abs(rad))))
    residual = get("power_balance_residual")
    energy = get("stored_thermal_energy")
    checks: dict[str, Any] = {
        "temperatures": {
            "air_K": statistics(get("air_temperature")),
            "outdoor_K": statistics(get("outdoor_temperature")),
            "all_positive_K": bool(
                np.all(get("air_temperature") > 0) and np.all(get("outdoor_temperature") > 0)
            ),
        },
        "heating_component_accounting": {
            "maximum_discrepancy_W": float(np.max(abs(accounting))),
            "arithmetic_budget_W": 64 * np.spacing(scale),
            "consistent_at_roundoff": bool(np.max(abs(accounting)) <= 64 * np.spacing(scale)),
        },
        "signed_heating": {
            name: signed_power(time, get(name), series[name].interpolation)
            for name in (
                "delivered_heating_power",
                "delivered_heating_convective_power",
                "delivered_heating_radiative_power",
            )
        },
        "stored_energy": {
            "unit": "J",
            "statistics": statistics(energy),
            "change_J": float(energy[-1] - energy[0]),
            "interpretation": "Relative storage reference permits negative stored-energy values.",
        },
        "power_balance_residual": {
            "unit": "W",
            **statistics(residual),
            "maximum_absolute_W": float(np.max(abs(residual))),
            "signed_time_integral_J_reconstructed": integrate(
                time, residual, series["power_balance_residual"].interpolation
            ),
            "interpretation": (
                "Instantaneous derivative balance log; its integral alone is "
                "not a total-storage closure test."
            ),
        },
        "integrated_energy_balance": {
            "status": "blocked",
            "missing": "net_external_power not exported in standard evaluation.csv",
            "reason": (
                "Heating, internal gains and ventilation omit exterior/window "
                "boundary fluxes; do not sum an incomplete system boundary."
            ),
        },
    }
    if "net_external_power" in series:
        power = series["net_external_power"]
        samples = (
            power.values[:-1]
            if power.interpolation == "previous"
            else (power.values[:-1] + power.values[1:]) / 2
        )
        integrated = np.r_[0.0, np.cumsum(np.diff(time) * samples)]
        error = energy - energy[0] - integrated
        checks["integrated_energy_balance"] = {
            "status": "sampled_diagnostic_not_accuracy_pass",
            "maximum_absolute_residual_J": float(np.max(abs(error))),
            "final_residual_J": float(error[-1]),
            "interpolation": power.interpolation,
            "limitation": (
                "Includes sampling/event quadrature error; not exact conservation verification."
            ),
        }
    try:
        parameters = report["assumptions"]["parameters"]
        rho = parameters["rho_air_kg_m3"]
        cp = parameters["cp_air_J_kgK"]
        if rho["unit"] != "kg/m3" or cp["unit"] != "J/(kg.K)":
            raise ValueError("Unexpected air-property units")
        registry_path = ROOT / "configs/references/boptest_bestest_hydronic.json"
        if file_hash(registry_path) != REGISTRY_HASH:
            raise ValueError("Local frozen registry hash mismatch")
        registry = read_json(registry_path.read_bytes())
        flow = next(
            p["value"] for p in registry["parameters"] if p["id"] == "infiltration.volume_flow"
        )
        h = float(rho["value"]) * float(cp["value"]) * float(flow)
        if not np.isfinite(h) or h <= 0:
            raise ValueError("Invalid air properties")
        expected = h * (get("outdoor_temperature") - get("air_temperature"))
        checks["ventilation"] = {
            "status": "checked_against_recorded_reduced_assumptions",
            "conductance_W_K": h,
            "maximum_formula_discrepancy_W": float(
                np.max(abs(get("ventilation_sensible_power") - expected))
            ),
            "note": (
                "Positive into zone; this is sensible infiltration, not "
                "reference moist-air enthalpy validation."
            ),
        }
    except (KeyError, ValueError, StopIteration) as problem:
        checks["ventilation"] = {"status": "blocked", "reason": str(problem)}
    return checks


def _pyplot(folder: Path) -> Any:
    os.environ.setdefault("MPLCONFIGDIR", str(folder.resolve() / ".mpl-cache"))
    os.environ.setdefault("XDG_CACHE_HOME", str(folder.resolve() / ".cache"))
    matplotlib = importlib.import_module("matplotlib")
    matplotlib.use("Agg")
    return importlib.import_module("matplotlib.pyplot")


def replay_plots(
    series: dict[str, Series], folder: Path, reference: Series | None = None
) -> list[str]:
    folder.mkdir(parents=True, exist_ok=True)
    plt = _pyplot(folder)
    time = series["air_temperature"].time_s
    days = (time - time[0]) / 86400
    title = (
        f"THERMA {series['air_temperature'].model_version} | {series['air_temperature'].scenario}"
    )
    saved: list[str] = []
    style = {
        "font.size": 10,
        "axes.labelsize": 10,
        "axes.titlesize": 10,
        "legend.fontsize": 8,
        "pdf.fonttype": 42,
        "savefig.dpi": 300,
        "axes.spines.top": False,
    }

    def finish(fig: Any, name: str) -> None:
        fig.tight_layout()
        for extension in ("png", "pdf"):
            path = folder / f"{name}.{extension}"
            fig.savefig(path, bbox_inches="tight")
            saved.append(path.name)
        plt.close(fig)

    with plt.rc_context(style):
        fig, ax = plt.subplots(figsize=(7, 4))
        ax.plot(
            days, series["air_temperature"].values - 273.15, label="Indoor air", color="#0072B2"
        )
        ax.plot(
            days,
            series["outdoor_temperature"].values - 273.15,
            label="Outdoor air",
            color="#D55E00",
            alpha=0.8,
        )
        ax.set(xlabel="Elapsed evaluation days", ylabel="Temperature (°C)", title=title)
        ax.legend()
        ax.grid(alpha=0.25)
        finish(fig, "01_air_and_outdoor")
        fig, ax = plt.subplots(figsize=(7, 4))
        other = ax.twinx()
        heating = series["delivered_heating_power"]
        if heating.interpolation == "previous":
            ax.step(
                days, heating.values / 1000, where="post", color="#D55E00", label="Delivered heat"
            )
        else:
            ax.plot(days, heating.values / 1000, color="#D55E00", label="Delivered heat")
        other.plot(
            days, series["air_temperature"].values - 273.15, color="#0072B2", label="Indoor air"
        )
        ax.axhline(0, color="0.4", lw=0.7)
        ax.set(xlabel="Elapsed evaluation days", ylabel="Delivered heating power (kW)", title=title)
        other.set_ylabel("Indoor air (°C)")
        ax.legend(loc="upper left")
        other.legend(loc="upper right")
        ax.grid(alpha=0.25)
        finish(fig, "02_heating_and_air")
        fig, ax = plt.subplots(figsize=(7, 4))
        for name, label, color in (
            ("delivered_heating_convective_power", "Convective", "#009E73"),
            ("delivered_heating_radiative_power", "Radiative", "#CC79A7"),
        ):
            item = series[name]
            if item.interpolation == "previous":
                ax.step(days, item.values, where="post", label=label, color=color)
            else:
                ax.plot(days, item.values, label=label, color=color)
        ax.axhline(0, color="0.4", lw=0.7)
        ax.set(xlabel="Elapsed evaluation days", ylabel="Signed delivered power (W)", title=title)
        ax.legend()
        ax.grid(alpha=0.25)
        finish(fig, "03_heating_components")
        fig, ax = plt.subplots(figsize=(7, 4))
        ventilation = series["ventilation_sensible_power"]
        if ventilation.interpolation == "previous":
            ax.step(days, ventilation.values, where="post", color="#009E73")
        else:
            ax.plot(days, ventilation.values, color="#009E73")
        ax.axhline(0, color="0.4", lw=0.7)
        ax.set(
            xlabel="Elapsed evaluation days",
            ylabel="Sensible infiltration into zone (W)",
            title=title,
        )
        ax.grid(alpha=0.25)
        finish(fig, "04_ventilation")
        fig, axes = plt.subplots(2, 1, figsize=(7, 6), sharex=True)
        axes[0].plot(days, series["stored_thermal_energy"].values / 1e6, color="#0072B2")
        axes[0].set(ylabel="Relative stored energy (MJ)", title=title)
        axes[1].plot(days, series["power_balance_residual"].values, color="#D55E00")
        axes[1].set(xlabel="Elapsed evaluation days", ylabel="Power-balance residual (W)")
        axes[1].ticklabel_format(axis="y", style="sci", scilimits=(-3, 3))
        for ax in axes:
            ax.grid(alpha=0.25)
        finish(fig, "05_energy_and_residual")
        if reference is not None:
            # Align continuous temperature only; never smooth power steps here.
            times = np.union1d(time, reference.time_s)
            elapsed = (times - times[0]) / 86400
            candidate = resample(series["air_temperature"], times)
            original = resample(reference, times)
            fig, axes = plt.subplots(2, 1, figsize=(7, 6), sharex=True)
            axes[0].plot(elapsed, original - 273.15, label="BOPTEST indoor air", color="#D55E00")
            axes[0].plot(elapsed, candidate - 273.15, label="THERMA indoor air", color="#0072B2")
            axes[0].set(
                ylabel="Indoor air (°C)",
                title=title + "\nExploratory partial-forcing comparison, not validation",
            )
            axes[0].legend()
            axes[1].plot(elapsed, candidate - original, color="#009E73")
            axes[1].set(xlabel="Elapsed evaluation days", ylabel="THERMA − BOPTEST (K)")
            for ax in axes:
                ax.grid(alpha=0.25)
            finish(fig, "06_reference_air_comparison")
    return saved


def engineering_summary(report: dict[str, Any]) -> str:
    lines = [
        "# C2.5C engineering analysis",
        "",
        f"Scope: {report['scope']}.",
        "Exploratory analysis only; no BOPTEST validation or calibrated accuracy claim.",
        "",
    ]
    if "execution" in report:
        execution = report["execution"]
        sample = report["sampling"]
        checks = report["physical_checks"]
        lines += [
            f"Supplied MATLAB report: {execution['status']} ({execution['matlab_version']}).",
            "Codex did not independently execute MATLAB.",
            "",
            f"Evaluation: {sample['samples']} samples over "
            f"{sample['duration_s'] / 86400:.6g} days; "
            f"sample spacing {sample['minimum_step_s']:.6g}–{sample['maximum_step_s']:.6g} s.",
            "Warm-up is excluded. Original absolute model seconds are preserved.",
            "",
            (
                "| Signed delivered heat | Minimum W | Negative samples | "
                "Reconstructed negative energy J |"
            ),
            "|---|---:|---:|---:|",
        ]
        for name, item in checks["signed_heating"].items():
            lines.append(
                f"| {name} | {item['minimum']:.6g} | {item['negative_sample_count']} | "
                f"{item['negative_signed_energy_J_reconstructed']:.6g} |"
            )
        lines += [
            "",
            "No negative values were clamped. The original source sign audit is in metrics.json.",
            f"Stored-energy change: {checks['stored_energy']['change_J']:.6g} J.",
            "Maximum instantaneous power residual: "
            f"{checks['power_balance_residual']['maximum_absolute_W']:.6g} W.",
            f"Integral energy closure: {checks['integrated_energy_balance']}.",
            f"Heating component accounting: {checks['heating_component_accounting']}.",
            f"Sensible infiltration formula check: {checks['ventilation']}.",
            "",
        ]
        comparison = report["reference_comparison"]
        lines += [f"Reference comparison: {comparison['status']}."]
        if comparison.get("metrics"):
            m = comparison["metrics"]
            lines += [
                f"Indoor air temperature: MAE {m['mae']:.6g} K, RMSE {m['rmse']:.6g} K, "
                f"sampled max error {m['maximum_absolute_error']:.6g} K, "
                f"bias {m['mean_bias_error']:.6g} K.",
                "Bias is THERMA minus BOPTEST. Continuous candidate temperature is "
                "aligned to the native reference timestamps, without extrapolation.",
                (
                    "Errors include omitted forcing, initialization and reduced physics; "
                    "they are not solver errors alone."
                ),
            ]
        else:
            lines += [
                f"No temperature error metrics computed: {comparison.get('reason', 'unavailable')}."
            ]
    else:
        audit = report["source_heating_sign_audit"]
        lines += [
            f"Original reference scenario: {audit['scenario']['name']}.",
            "No THERMA execution outputs were used or reconstructed.",
            "",
            "| Component | Minimum W | Negative samples | Reconstructed negative energy J |",
            "|---|---:|---:|---:|",
        ]
        for name in ("convective", "radiative", "total"):
            item = audit[name]
            lines.append(
                f"| {name} | {item['minimum']:.6g} | {item['negative_sample_count']} | "
                f"{item['negative_signed_energy_J_reconstructed']:.6g} |"
            )
    for title, key in (
        ("Known limitations", "known_limitations"),
        ("Recommended next work", "recommended_next_work"),
    ):
        lines += ["", title + ":", ""]
        lines += ["- " + str(value) for value in report[key]]
    return "\n".join(lines) + "\n"


def analyze_run(
    run_dir: Path,
    output: Path,
    reference_run_dir: Path | None = None,
    *,
    plots: bool = True,
    auto_reference: bool = True,
) -> dict[str, Any]:
    series, metadata, execution = load_replay(run_dir)
    packet = execution["replay_metadata"]
    if reference_run_dir is None and auto_reference:
        reference_run_dir = _find_reference(packet)
    comparison, reference = reference_comparison(series, packet, reference_run_dir)
    checks = engineering_checks(series, execution)
    report = {
        "schema_version": 1,
        "status": "analyzed_exploratory_not_validated",
        "scope": "actual_supplied_MATLAB_replay_exports",
        "classification": "exploratory_comparison",
        "execution": {
            k: execution.get(k)
            for k in (
                "status",
                "matlab_execution_completed",
                "simulation_returned",
                "matlab_version",
                "simulink",
                "model_name",
                "model_version",
            )
        },
        "input_provenance": {
            "analysis_source_sha256": file_hash(Path(__file__)),
            "numpy_version": np.__version__,
            "original_signal_contract": metadata["signals"],
            "canonical_analysis_units": {k: v.unit for k, v in series.items()},
            "csv_sha256": file_hash(run_dir / "evaluation.csv"),
            "comparison_metadata_sha256": file_hash(run_dir / "comparison_metadata.json"),
            "replay_run_sha256": file_hash(run_dir / "replay_run.json"),
            "reference_manifest_sha256": packet["reference_manifest_sha256"],
            "reference_trajectory_sha256": packet["source_trajectory_sha256"],
            "reported_packet_sha256": execution.get("replay_packet_sha256"),
            "packet_file_verification": "Not independently checked by this three-export analysis",
            "source_scenario": packet["source_scenario"],
            "experiment_scenario_id": metadata["scenario_id"],
            "channels": packet.get("channels", []),
            "driver_diagnostics": execution.get("drivers", []),
            "initial_conditions": packet.get("initial_conditions"),
            "registry_sha256": execution["registry_sha256"],
            "assumptions_sha256": execution.get("assumptions_sha256"),
            "warmup_duration_s": packet["evaluation_start_s"] - packet["time_origin_s"],
            "warmup_excluded_from_metrics": True,
        },
        "sampling": sampling(series["air_temperature"].time_s),
        "physical_checks": checks,
        "reference_comparison": comparison,
        "known_limitations": [
            *metadata.get("missing_inputs", []),
            *metadata.get("limitations", []),
            (
                "Solar forcing is omitted and initial states are provisional; "
                "do not attribute all temperature errors to solver accuracy."
            ),
            (
                "Temperature metrics use native reference timestamps; sample "
                "spacing limits peak resolution. No acceptance threshold is inferred."
            ),
            "Power integrals use declared reconstruction, not unknown continuous waveforms.",
            (
                "Small instantaneous residual alone does not prove total energy"
                " closure or reference validity."
            ),
            "No values clamped, calibrated, smoothed or overwritten.",
        ],
        "recommended_next_work": [
            "Inspect matched input/sign diagnostics and first exploratory comparison before C2.6.",
            "Obtain absorbed solar and consistent full initial-state/warm-up policy.",
            (
                "Then prioritize glazing/solar, exterior exchange and radiative"
                " environment; preserve independent verification."
            ),
            "Export total external net power to permit a full sampled integral energy check.",
        ],
        "plots": {"status": "not_requested", "files": []},
    }
    output.mkdir(parents=True, exist_ok=False)
    if plots:
        try:
            files = replay_plots(series, output / "plots", reference)
            report["plots"] = {
                "status": "generated",
                "files": files,
                "formats": ["300-dpi PNG", "vector PDF"],
            }
        except ModuleNotFoundError as error:
            report["plots"] = {
                "status": "blocked",
                "reason": str(error),
                "files": [],
                "remedy": "Run with uv run --frozen --with matplotlib==3.10.8",
            }
    (output / "metrics.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    (output / "engineering_summary.md").write_text(engineering_summary(report))
    return report


def audit_reference(run: Path, output: Path, *, plots: bool = True) -> dict[str, Any]:
    audit = reference_sign_audit(run)
    report = {
        "schema_version": 1,
        "scope": "original_BOPTEST_only_not_THERMA_results",
        "source_heating_sign_audit": audit,
        "known_limitations": [
            (
                "Actual MATLAB "
                "evaluation.csv/comparison_metadata.json/replay_run.json not "
                "supplied to this source-only audit."
            ),
            "No THERMA temperature metrics or replay plots are inferred.",
        ],
        "recommended_next_work": ["Import actual MATLAB exports, then run analyze."],
    }
    output.mkdir(parents=True, exist_ok=False)
    if plots:
        time, data, _ = _read_reference(run)
        plt = _pyplot(output)
        fig, ax = plt.subplots(figsize=(7, 4))
        days = (time - time[0]) / 86400
        for name, label in (
            (SOURCE_CONV, "Convective delivered power"),
            (SOURCE_RAD, "Radiative delivered power"),
        ):
            ax.step(days, -data[name], where="post", label=label)
        ax.axhline(0, color="0.4", lw=0.7)
        ax.set(
            xlabel="Elapsed evaluation days",
            ylabel="Signed room-delivered heat (W)",
            title=f"Original BOPTEST only | {audit['scenario']['name']}",
        )
        ax.legend()
        ax.grid(alpha=0.25)
        fig.tight_layout()
        for extension in ("png", "pdf"):
            fig.savefig(
                output / f"reference_signed_heating.{extension}", dpi=300, bbox_inches="tight"
            )
        plt.close(fig)
    (output / "metrics.json").write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    (output / "engineering_summary.md").write_text(engineering_summary(report))
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    analysis = commands.add_parser("analyze")
    analysis.add_argument("--run-dir", type=Path, required=True)
    analysis.add_argument("--reference-run", type=Path)
    analysis.add_argument("--no-auto-reference", action="store_true")
    audit = commands.add_parser("reference-signs")
    audit.add_argument("--reference-run", type=Path, required=True)
    for sub in (analysis, audit):
        sub.add_argument("--output", type=Path, required=True)
        sub.add_argument("--no-plots", action="store_true")
    args = parser.parse_args()
    if args.command == "analyze":
        report = analyze_run(
            args.run_dir,
            args.output,
            args.reference_run,
            plots=not args.no_plots,
            auto_reference=not args.no_auto_reference,
        )
        print(report["reference_comparison"]["status"])
    else:
        audit_reference(args.reference_run, args.output, plots=not args.no_plots)
        print("Original BOPTEST sign audit complete; no THERMA outputs inferred.")


if __name__ == "__main__":
    main()
