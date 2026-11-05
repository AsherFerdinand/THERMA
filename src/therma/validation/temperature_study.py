"""C2.8 actual controlled pair analysis; selective receipts, not full C2.7 certification."""

from __future__ import annotations

import argparse
import json
from dataclasses import replace
from pathlib import Path, PurePosixPath
from typing import Any

import numpy as np

from therma.comparison import resample
from therma.validation.analysis import _pyplot, file_hash, load_replay
from therma.validation.archive import ROOT
from therma.validation.benchmark import metric_changes, metrics
from therma.validation.temperature import aligned_errors, read_reference

IDS = ("no_solar_30", "solar_30")
FILES = ("evaluation.csv", "comparison_metadata.json", "replay_run.json")


def load_pair(index_file: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    index = json.loads(index_file.read_text())
    contract_file = index_file.parent / "contract.json"
    if index["status"] != "completed" or file_hash(contract_file) != index["contract_sha256"]:
        raise ValueError("Incomplete study or contract hash mismatch")
    contract = json.loads(contract_file.read_text())
    plan_file = ROOT / "configs/references/c27_study.json"
    if file_hash(plan_file) != contract["plan_sha256"]:
        raise ValueError("Study plan identity differs")
    plan = json.loads(plan_file.read_text())
    source_hashes = {s["name"]: s["sha256"] for s in contract["sources"]}
    pair = {}
    provenance: dict[str, Any] = {
        "study_index_sha256": file_hash(index_file),
        "contract_sha256": file_hash(contract_file),
        "matlab_version": contract["matlab_version"],
        "independent_MATLAB_execution": False,
        "verification_scope": "Supplied controlled-pair artifacts only; not all C2.7 outputs",
    }
    for name in IDS:
        item = index["experiments"][name]
        relative = PurePosixPath(item["folder"])
        if (
            relative.is_absolute()
            or ".." in relative.parts
            or "\\" in str(relative)
            or ":" in str(relative)
        ):
            raise ValueError("Unsafe experiment folder")
        folder = index_file.parent.parent / relative
        receipt_file = folder / "completion.json"
        if item["status"] != "completed" or file_hash(receipt_file) != item["completion_sha256"]:
            raise ValueError("Completion receipt hash mismatch")
        receipt = json.loads(receipt_file.read_text())
        expected = receipt["expected"]
        key = "no_solar" if name == "no_solar_30" else "solar"
        if (
            receipt["status"] != "completed"
            or expected["experiment_id"] != name
            or expected["max_step_s"] != 30
            or expected["packet_sha256"] != plan[key + "_packet_sha256"]
            or expected["contract_sha256"] != index["contract_sha256"]
            or expected["matlab_version"] != contract["matlab_version"]
        ):
            raise ValueError("Experiment identity/contract mismatch")
        artifacts = receipt["artifacts"]
        hashes = {a["name"]: a["sha256"] for a in artifacts}
        if len(hashes) != len(artifacts) or not set(FILES) <= hashes.keys():
            raise ValueError("Missing/duplicate receipt artifacts")
        for filename in FILES:
            if file_hash(folder / filename) != hashes[filename]:
                raise ValueError("Consumed artifact hash mismatch: " + filename)
        series, metadata, report = load_replay(folder)
        if (
            report["matlab_version"] != contract["matlab_version"]
            or report["simulink"] != contract["simulink"]
            or report["driver_source_sha256"] != source_hashes["run_boptest_zone_replay.m"]
            or report["registry_sha256"] != contract["frozen_registry_sha256"]
            or report["assumptions_sha256"] != contract["assumptions_sha256"]
            or report["replay_packet_sha256"] != expected["packet_sha256"]
            or float(report["solver"]["MaxStep_s"]) != 30
            or report.get("export_completed") is not True
        ):
            raise ValueError("Runtime contract/source mismatch")
        pair[name] = (series, metadata, report)
        provenance[name] = {
            "completion_sha256": file_hash(receipt_file),
            "supplied_artifacts": {f: hashes[f] for f in FILES},
            "unverified_unsupplied_artifacts": sorted(set(hashes) - set(FILES)),
            "samples": len(series["air_temperature"].time_s),
            "maximum_sample_gap_s": float(np.max(np.diff(series["air_temperature"].time_s))),
            "packet_sha256": report["replay_packet_sha256"],
        }
    a, b = (pair[name][2] for name in IDS)
    for key in [
        "driver_source_sha256",
        "model_version",
        "solver",
        "registry_sha256",
        "assumptions_sha256",
    ]:
        if a[key] != b[key]:
            raise ValueError("Controlled pair differs: " + key)
    return pair, provenance


def analyze(index_file: Path, reference_folder: Path, output: Path) -> dict[str, Any]:
    pair, provenance = load_pair(index_file)
    reference = read_reference(reference_folder)
    metadata = json.loads((reference_folder / "reference_metadata.json").read_text())
    sources = metadata["compatible_reference_sources"]
    t = reference.time_s
    days = (t - t[0]) / 86400
    errors, values, results = {}, {}, {}
    for name in IDS:
        candidate, _, report = pair[name]
        packet = report["replay_metadata"]
        if (
            packet["source_fmu_sha256"] != metadata["fmu_sha256"]
            or packet["source_scenario"] != metadata["scenario"]
            or not any(
                packet["source_trajectory_sha256"] == s["trajectory_sha256"]
                and packet["reference_manifest_sha256"] == s["manifest_sha256"]
                and packet["source_signals_sha256"] == s["signals_sha256"]
                for s in sources
            )
        ):
            raise ValueError("Replay source not the verified original/equivalent reference")
        # Scenario suffixes describe interventions; only normalize after source/scenario checks.
        air = replace(candidate["air_temperature"], scenario=reference.scenario)
        results[name] = aligned_errors(air, reference)
        values[name] = resample(air, t)
        errors[name] = values[name] - reference.values
    changes = metric_changes(results[IDS[0]], results[IDS[1]])
    summary: dict[str, Any] = {
        "status": "completed_controlled_reduced_zone_reference_comparison",
        "real_world_validation": False,
        "sample_count": len(t),
        "evaluation_start_s": float(t[0]),
        "evaluation_end_s": float(t[-1]),
        "reference_quantity": "air_temperature",
        "reference_source": "mod.case900Template.TAir",
        "bias_convention": "THERMA minus BOPTEST",
        "metrics": results,
        "solar_changes": changes,
        "worst_errors": {},
        "maximum_solar_minus_no_solar_temperature_difference_K": float(
            np.max(values[IDS[1]] - values[IDS[0]])
        ),
        "maximum_absolute_solar_no_solar_temperature_difference_K": float(
            np.max(abs(values[IDS[1]] - values[IDS[0]]))
        ),
        "limitations": [
            "Prescribed reference radiator heat, not independent hydronic prediction",
            "Reduced initial-state/envelope/window/airflow representation",
            "Full C2.7 convergence and event energy evidence not supplied",
            "MATLAB comparison script unexecuted in cloud; metrics/plots generated in Python",
            "Maximum errors are sampled, not bounds between timestamps",
        ],
    }
    output.mkdir(parents=True, exist_ok=False)
    daily = []
    for name in IDS:
        e = errors[name]
        worst = int(np.argmax(abs(e)))
        summary["worst_errors"][name] = {
            "time_s": float(t[worst]),
            "evaluation_day": float(days[worst]),
            "signed_error_K": float(e[worst]),
            "THERMA_degC": float(values[name][worst] - 273.15),
            "BOPTEST_degC": float(reference.values[worst] - 273.15),
        }
        for day in range(14):
            mask = (days >= day) & ((days <= 14) if day == 13 else (days < day + 1))
            daily.append(
                {
                    "experiment": name,
                    "day_zero_based": day,
                    "samples": int(mask.sum()),
                    **metrics(e[mask]),
                }
            )
    import csv

    for filename, rows in [
        ("metrics.csv", [{"experiment": name, "samples": len(t), **results[name]} for name in IDS]),
        ("daily_metrics.csv", daily),
    ]:
        with (output / filename).open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    prior = json.loads((ROOT / "docs/results/c26c/provenance.json").read_text())
    duplicate_solar = (
        provenance["solar_30"]["supplied_artifacts"]["evaluation.csv"]
        == prior["attachments"]["evaluation.csv"]["sha256"]
    )
    provenance["solar_csv_already_present_in_C26C_evidence"] = duplicate_solar
    if duplicate_solar:
        summary["limitations"].append(
            "Uploaded solar CSV matches C2.6C solar evidence previously reported R2021a; "
            "new report/contract state R2024a. Independent fresh-run lineage is not established."
        )
        summary["execution_lineage_status"] = "review_required_duplicate_prior_solar_payload"
    provenance["reference_metadata_sha256"] = file_hash(
        reference_folder / "reference_metadata.json"
    )
    provenance["reference_csv_sha256"] = file_hash(reference_folder / "reference_temperature.csv")
    for filename, obj in [("metrics.json", summary), ("provenance.json", provenance)]:
        (output / filename).write_text(json.dumps(obj, indent=2, allow_nan=False) + "\n")
    plt = _pyplot(output)
    fig, ax = plt.subplots(figsize=(11, 4.5), constrained_layout=True)
    ax.plot(days, reference.values - 273.15, color="black", lw=1.2, label="BOPTEST air")
    for name, color, label in [
        (IDS[0], "blue", "THERMA no solar"),
        (IDS[1], "red", "THERMA solar"),
    ]:
        ax.plot(days, values[name] - 273.15, color=color, lw=0.9, label=label)
    ax.set(
        xlabel="Evaluation time (days)",
        ylabel="Indoor air temperature (°C)",
        title="C2.8: prescribed-heating thermal-zone response versus BOPTEST",
    )
    ax.grid(alpha=0.25)
    ax.legend(ncol=3)
    figures = [(fig, "temperature_comparison")]
    fig, ax = plt.subplots(figsize=(11, 4), constrained_layout=True)
    for name, color in zip(IDS, ["blue", "red"], strict=True):
        ax.plot(days, errors[name], color=color, lw=0.9, label=name)
    ax.axhline(0, color="black", lw=0.5)
    ax.grid(alpha=0.25)
    ax.legend()
    ax.set(
        xlabel="Evaluation time (days)",
        ylabel="THERMA minus BOPTEST (K)",
        title="Native 30-second reference-grid error",
    )
    figures.append((fig, "temperature_errors"))
    fig, ax = plt.subplots(figsize=(10, 4), constrained_layout=True)
    for name, color in zip(IDS, ["blue", "red"], strict=True):
        ax.plot(
            np.arange(14) + 0.5,
            [row["MAE_K"] for row in daily if row["experiment"] == name],
            color=color,
            marker="o",
            label=name,
        )
    ax.set(
        xlabel="Evaluation time (days; bin midpoints)",
        ylabel="Daily MAE (K)",
        title="Daily indoor-air-temperature agreement",
    )
    ax.grid(alpha=0.25)
    ax.legend()
    figures.append((fig, "daily_errors"))
    for fig, stem in figures:
        for suffix in ["png", "pdf"]:
            fig.savefig(output / (stem + "." + suffix), dpi=300)
        plt.close(fig)
    baseline, solar = (results[name] for name in IDS)
    report = [
        "# C2.8 controlled BOPTEST air-temperature comparison",
        "",
        (
            "Actual supplied MATLAB R2024a outputs; Python post-processing. No MATLAB "
            "execution in cloud."
        ),
        "40,321 native 30 s reference timestamps; 14 evaluation days after 7-day warm-up.",
        "",
        "| Metric (K) | No solar | Solar | Solar minus no solar |",
        "|---|---:|---:|---:|",
    ]
    for key in baseline:
        report.append(
            f"| {key} | {baseline[key]:.9f} | {solar[key]:.9f} | "
            f"{solar[key] - baseline[key]:+.9f} |"
        )
    report += [
        "",
        "A negative MAE/RMSE change means improvement; assess bias by magnitude, not sign alone.",
        "",
        "## Largest sampled deviations",
    ]
    for name, worst in summary["worst_errors"].items():
        report.append(
            f"- {name}: {worst['signed_error_K']:+.6f} K at evaluation day "
            f"{worst['evaluation_day']:.6f}."
        )
    report += [
        "",
        "## Interpretation and next step",
        (
            "These measurements evaluate reduced-zone response under prescribed BOPTEST "
            "radiator heat. They do not establish independent hydronic or real-world "
            "validation."
        ),
        (
            "Supplied release metadata, solver, parameter and driver identities agree. "
            "Reference source equivalence was verified before comparing intervention "
            "scenarios."
        ),
        (
            "Possible causes of remaining differences include reduced initial states, "
            "omitted window/airflow physics and solar allocation. These are hypotheses, "
            "not identified causes."
        ),
        (
            "Review daily errors alongside all four C2.7 solver-step runs and original "
            "event-energy logs before selecting further physics changes. No "
            "recalibration or C2.9 implementation was performed."
        ),
        "",
        (
            "Unsupplied energy_events.csv, solver_metadata.json and generated SLX files "
            "were not rehashed; completion claims for refinements are not independently "
            "checked. Full convergence/energy certification is outside this supplied "
            "pair."
        ),
        (
            "MATLAB PNG/FIG reproduction remains pending university execution; Python "
            "generated the actual PNG/PDF figures and metrics here."
        ),
    ]
    if duplicate_solar:
        report += [
            "",
            "## Execution-lineage qualification",
            "The uploaded solar CSV is byte-identical to preserved C2.6C solar evidence, "
            "whose earlier report recorded R2021a. The new supplied contract/report state "
            "R2024a. Numerical metrics are reproducible, but this payload does not establish "
            "a fresh independent same-release execution. Retain original university logs, "
            "solver metadata and event files for lineage review before making that claim.",
        ]
    (output / "validation_report.md").write_text("\n".join(report) + "\n")
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--study", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(analyze(args.study, args.reference, args.output), indent=2))


if __name__ == "__main__":
    main()
