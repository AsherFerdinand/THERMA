"""Controlled comparisons of actual C2 no-solar/solar MATLAB exports; no simulation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from therma.comparison import integrate, resample
from therma.validation.analysis import _find_reference, analyze_run, file_hash, load_replay
from therma.validation.replay import reference_run


def metrics(error: NDArray[np.float64]) -> dict[str, float]:
    if error.ndim != 1 or not len(error) or not np.isfinite(error).all():
        raise ValueError("Expected finite aligned temperature errors")
    return {
        "MAE_K": float(np.mean(abs(error))),
        "RMSE_K": float(np.sqrt(np.mean(error**2))),
        "maximum_absolute_error_K": float(np.max(abs(error))),
        "bias_K": float(np.mean(error)),
    }


def day_metrics(time: NDArray[np.float64], error: NDArray[np.float64]) -> list[dict[str, Any]]:
    if len(time) != len(error) or len(time) < 2 or np.any(np.diff(time) <= 0):
        raise ValueError("Invalid daily grid")
    bins = ((time - time[0]) // 86400).astype(int)
    # Final boundary belongs to preceding day; no one-sample extra day.
    if time[-1] > time[0] and (time[-1] - time[0]) % 86400 == 0:
        bins[-1] -= 1
    return [
        {
            "evaluation_day": int(day + 1),
            "samples": int(np.sum(bins == day)),
            **metrics(error[bins == day]),
        }
        for day in np.unique(bins)
    ]


def paired(
    baseline: Path,
    solar: Path,
    reference: Path,
    output: Path,
    *,
    plots: bool = True,
    step_run: Path | None = None,
) -> dict[str, Any]:
    """Warm-up is excluded by load_replay; use native reference temperature grid."""
    b, _, br = load_replay(baseline)
    s, _, sr = load_replay(solar)
    bp, sp = br["replay_metadata"], sr["replay_metadata"]
    for key in ["source_fmu_sha256", "reference_version", "source_scenario", "initial_conditions"]:
        left, right = bp[key], sp[key]
        if key == "initial_conditions":
            left, right = left["temperature_K"], right["temperature_K"]
        if left != right:
            raise ValueError("Controlled comparison mismatch: " + key)
    for key in ["registry_sha256", "assumptions_sha256", "model_version"]:
        if br[key] != sr[key]:
            raise ValueError("Model/assumption mismatch: " + key)
    if bp["reference_manifest_sha256"] != sp["baseline_manifest_sha256"]:
        raise ValueError("Baseline provenance differs from solar preservation record")
    if bp["schema_version"] != 1 or sp["schema_version"] != 2:
        raise ValueError("Expected original v1 baseline and solar v2 experiment")
    m, data, units = reference_run(reference, "evaluation.csv")
    if (
        file_hash(reference / "manifest.json") != sp["reference_manifest_sha256"]
        or m["scenario"] != sp["source_scenario"]
        or units.get("mod.case900Template.TAir") != "K"
    ):
        raise ValueError("Reference identity or air-temperature units mismatch")
    t = np.asarray(data["time_s"], dtype=float)
    if (
        t[0] != sp["evaluation_start_s"]
        or t[-1] != sp["evaluation_end_s"]
        or not np.all(np.diff(t) == 30)
    ):
        raise ValueError("Invalid native evaluation grid")
    ref = np.asarray(data["mod.case900Template.TAir"], dtype=float)
    bt, st = resample(b["air_temperature"], t), resample(s["air_temperature"], t)
    result: dict[str, Any] = {
        "status": "exploratory_comparison_not_validation",
        "baseline": metrics(bt - ref),
        "solar": metrics(st - ref),
        "solar_minus_baseline": metrics(st - bt),
        "daily_baseline": day_metrics(t, bt - ref),
        "daily_solar": day_metrics(t, st - ref),
        "energy_J_reconstructed": {},
        "solver_step_sensitivity": {"status": "pending"},
        "sources": {
            "baseline_evaluation": b["air_temperature"].source_sha256,
            "solar_evaluation": s["air_temperature"].source_sha256,
            "reference_manifest": file_hash(reference / "manifest.json"),
        },
        "solver_settings": {"baseline": br.get("solver"), "solar": sr.get("solver")},
        "limitations": [
            "Sampled/held power quadrature is not exact continuous energy.",
            "Reduced glazing/exterior/air physics remain different; no calibration.",
        ],
    }
    for label, collection in [("baseline", b), ("solar", s)]:
        result["energy_J_reconstructed"][label] = {
            q: integrate(v.time_s, v.values, v.interpolation)
            for q, v in collection.items()
            if q
            in [
                "delivered_heating_power",
                "internal_convective_power",
                "internal_radiative_power",
                "absorbed_solar_power",
            ]
        }
    if step_run:
        x, _, xr = load_replay(step_run)
        if any(
            xr.get(k) != sr.get(k)
            for k in [
                "replay_packet_sha256",
                "assumptions_sha256",
                "registry_sha256",
                "model_version",
            ]
        ):
            raise ValueError("Step sensitivity requires identical packet/model/parameters")
        result["solver_step_sensitivity"] = {
            "status": (
                "compared_actual_runs_not_convergence_proof"
                if xr.get("solver") != sr.get("solver")
                else "same_solver_settings_repeatability_only"
            ),
            "temperature_difference": metrics(resample(x["air_temperature"], t) - st),
            "solar_solver": sr.get("solver"),
            "other_solver": xr.get("solver"),
        }
    output.mkdir(parents=True, exist_ok=False)
    # Reuse proven individual report/energy/plot logic with each packet's own reference.
    analyze_run(solar, output / "solar", reference, plots=plots)
    analyze_run(baseline, output / "baseline", _find_reference(bp), plots=plots)
    if plots:
        from therma.validation.analysis import _pyplot

        plt = _pyplot(output)
        fig, ax = plt.subplots(figsize=(10, 4))
        for values, label in [
            (ref, "BOPTEST air"),
            (bt, "THERMA no solar"),
            (st, "THERMA opaque solar"),
        ]:
            ax.plot((t - t[0]) / 86400, values - 273.15, lw=0.8, label=label)
        ax.set(xlabel="Evaluation day", ylabel="Indoor air temperature (°C)")
        ax.grid(alpha=0.25)
        ax.legend()
        fig.tight_layout()
        for suffix in ["png", "pdf"]:
            fig.savefig(output / f"controlled_comparison.{suffix}", dpi=300)
        plt.close(fig)
    (output / "comparison.json").write_text(json.dumps(result, indent=2, allow_nan=False) + "\n")
    (output / "engineering_summary.md").write_text(
        "# Actual paired exploratory replay\n\n"
        + json.dumps(result, indent=2)
        + "\n\nNo validation threshold or calibration applied.\n"
    )
    return result


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    for arg in ["baseline", "solar", "reference", "output"]:
        p.add_argument("--" + arg, type=Path, required=True)
    p.add_argument("--step-run", type=Path)
    args = p.parse_args()
    paired(args.baseline, args.solar, args.reference, args.output, step_run=args.step_run)


if __name__ == "__main__":
    main()
