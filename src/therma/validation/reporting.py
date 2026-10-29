"""Comparison presentation with explicit readiness, no numerical acceptance claims."""

from __future__ import annotations

import importlib
import os
from dataclasses import replace
from pathlib import Path
from typing import Any

import numpy as np

from therma.comparison import UNITS, Series, compare_collection, convert, resample

CLASSIFICATIONS = (
    "verification_only",
    "exploratory_comparison",
    "partial_reference_comparison",
    "reference_validation_candidate",
    "not_comparable",
)


def study_report(
    reference: dict[str, Series],
    candidate: dict[str, Series],
    reference_metadata: dict[str, Any],
    candidate_metadata: dict[str, Any],
    classification: str = "exploratory_comparison",
    allow_scenario_difference: bool = False,
) -> dict[str, Any]:
    if classification not in CLASSIFICATIONS:
        raise ValueError("Unsupported comparison classification")
    if allow_scenario_difference and classification != "exploratory_comparison":
        raise ValueError("Different scenarios permit exploratory comparison only")
    if classification == "reference_validation_candidate":
        for metadata in (reference_metadata, candidate_metadata):
            if metadata.get("missing_inputs") or not all(
                metadata.get(k) is True
                for k in (
                    "reference_physics_complete",
                    "matched_initial_conditions",
                    "all_required_inputs",
                )
            ):
                raise ValueError(
                    "Reference validation candidate blocked by unestablished readiness"
                )
    original_reference = reference_metadata["scenario_id"]
    original_candidate = candidate_metadata["scenario_id"]
    if original_reference != original_candidate:
        if not allow_scenario_difference:
            raise ValueError("Different scenarios require explicit exploratory pairing")
        study = f"exploratory_pair:{original_reference}:{original_candidate}"
        reference = {k: replace(v, scenario=study) for k, v in reference.items()}
        candidate = {k: replace(v, scenario=study) for k, v in candidate.items()}
    report = compare_collection(reference, candidate)
    if not report["signals"] or classification == "not_comparable":
        classification = "not_comparable"
    report.update(
        {
            "classification": classification,
            "scenario_pair": {"reference": original_reference, "candidate": original_candidate},
            "missing_inputs": candidate_metadata.get("missing_inputs", []),
            "assumptions": candidate_metadata.get("assumptions", []),
            "signal_mappings": {
                "reference": reference_metadata["signals"],
                "candidate": candidate_metadata["signals"],
            },
            "comparison_readiness": "exploratory_only"
            if classification == "exploratory_comparison"
            else classification,
            "known_limitations": [
                *reference_metadata.get("limitations", []),
                *candidate_metadata.get("limitations", []),
            ],
        }
    )
    return report


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# Reference comparison",
        "",
        f"Classification: `{report['classification']}`.",
        "No numerical acceptance threshold or BOPTEST validation pass is inferred.",
        "",
        f"Scenarios: {report['scenario_pair']}",
        "",
        "| Quantity | Unit | MAE | RMSE | Max error | Bias | Relative energy difference |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    for name, metrics in report["signals"].items():
        energy = metrics["relative_energy_difference"]
        lines.append(
            f"| {name} | {metrics['unit']} | {metrics['mae']:.6g} | "
            f"{metrics['rmse']:.6g} | {metrics['maximum_absolute_error']:.6g} | "
            f"{metrics['mean_bias_error']:.6g} | {energy if energy is not None else 'n/a'} |"
        )
    for key in (
        "missing_candidate_signals",
        "missing_reference_signals",
        "missing_inputs",
        "assumptions",
        "known_limitations",
    ):
        lines.extend(["", f"{key}: {report.get(key, [])}"])
    return "\n".join(lines) + "\n"


def diagnostic_plots(
    reference: dict[str, Series], candidate: dict[str, Series], folder: Path
) -> int:
    folder.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("MPLCONFIGDIR", str(folder.resolve() / ".mpl-cache"))
    os.environ.setdefault("XDG_CACHE_HOME", str(folder.resolve() / ".cache"))
    # Optional plotting dependency, deliberately outside core comparison imports.
    matplotlib = importlib.import_module("matplotlib")
    matplotlib.use("Agg")
    plt = importlib.import_module("matplotlib.pyplot")

    folder.mkdir(parents=True, exist_ok=True)
    count = 0
    for index, name in enumerate(sorted(reference.keys() & candidate.keys())):
        ref, can = reference[name], candidate[name]
        # Perform the same strict quantity/unit/coverage checks before drawing.
        compare_collection(
            {name: replace(ref, scenario="plot")}, {name: replace(can, scenario="plot")}
        )
        t = np.union1d(ref.time_s, can.time_s)
        x = resample(ref, t)
        y = convert(resample(can, t), can.unit, ref.unit)
        elapsed_h = (t - t[0]) / 3600
        fig, axes = plt.subplots(3, 1, figsize=(11, 9), sharex=True)
        for series, values, label in ((ref, x, "reference"), (can, y, "candidate")):
            if series.interpolation == "previous":
                axes[0].step(elapsed_h, values, where="post", label=label)
            else:
                axes[0].plot(elapsed_h, values, label=label)
        axes[0].set_ylabel(ref.unit)
        axes[0].legend()
        axes[1].plot(elapsed_h, y - x)
        axes[1].set_ylabel(f"Candidate-reference ({ref.unit})")
        dimension, factor, _ = UNITS[ref.unit]
        if dimension == "power":
            for values, series, label in (
                (x, ref, "reference energy"),
                (y, can, "candidate energy"),
            ):
                sample = (
                    values[:-1]
                    if series.interpolation == "previous"
                    else (values[:-1] + values[1:]) / 2
                )
                energy = np.r_[0, np.cumsum(np.diff(t) * sample * factor)]
                axes[2].plot(elapsed_h, energy, label=label)
            axes[2].set_ylabel("Cumulative J")
            axes[2].legend()
        else:
            axes[2].plot(
                (ref.time_s - ref.time_s[0]) / 3600,
                np.zeros(len(ref.time_s)),
                "|",
                label="reference samples",
            )
            axes[2].plot(
                (can.time_s - can.time_s[0]) / 3600,
                np.ones(len(can.time_s)),
                "|",
                label="candidate samples",
            )
            axes[2].set_ylabel("Input/time alignment")
            axes[2].legend()
        for axis in axes:
            axis.grid(True)
        axes[2].set_xlabel("Elapsed hours in common coverage")
        fig.suptitle(
            f"{name}\n{ref.model_version[:24]} / {can.model_version[:24]}\n"
            f"{ref.scenario} / {can.scenario}"
        )
        fig.tight_layout()
        fig.savefig(folder / f"signal_{index:02d}.png", dpi=140)
        plt.close(fig)
        count += 1
    return count
