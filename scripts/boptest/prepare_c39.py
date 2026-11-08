"""Post-process preserved C2.8 artifacts; no FMU/MATLAB execution or new physics."""

from __future__ import annotations

import argparse
import json
from dataclasses import replace
from pathlib import Path

import numpy as np

from therma.comparison import Series, integrate, resample
from therma.validation.analysis import _pyplot, file_hash
from therma.validation.replay import reference_run
from therma.validation.temperature import aligned_errors, read_reference
from therma.validation.temperature_study import load_pair


def prepare(study: Path, reference: Path, run: Path, output: Path) -> dict:
    pair, provenance = load_pair(study)
    channels, _, execution = pair["solar_30"]
    ref = read_reference(reference)
    metadata = json.loads((reference / "reference_metadata.json").read_text())
    manifest, raw, units = reference_run(run)
    p = execution["replay_metadata"]
    if (
        manifest["scenario"] != metadata["scenario"]
        or p["source_scenario"] != metadata["scenario"]
        or p["reference_version"] != metadata["boptest_commit"]
        or file_hash(run / "manifest.json") != metadata["source_manifest_sha256"]
        or p["source_fmu_sha256"] != metadata["fmu_sha256"]
        or not any(
            p["source_trajectory_sha256"] == s["trajectory_sha256"]
            and p["reference_manifest_sha256"] == s["manifest_sha256"]
            and p["source_signals_sha256"] == s["signals_sha256"]
            for s in metadata["compatible_reference_sources"]
        )
    ):
        raise ValueError("Scenario/reference lineage differs")
    mask = (raw["time_s"] >= ref.time_s[0]) & (raw["time_s"] <= ref.time_s[-1])
    if (
        units["mod.case900Template.TAir"] != "K"
        or not np.array_equal(raw["time_s"][mask], ref.time_s)
        or not np.array_equal(raw["mod.case900Template.TAir"][mask], ref.values)
    ):
        raise ValueError("Reference extraction is not the original native air trajectory")
    air = replace(channels["air_temperature"], scenario=ref.scenario)
    metrics = aligned_errors(air, ref)
    prior = json.loads(Path("docs/results/c28/metrics.json").read_text())
    if any(abs(metrics[k] - prior["metrics"]["solar_30"][k]) > 1e-12 for k in metrics):
        raise ValueError("Preserved C2.8 metrics not reproduced")
    source = []
    observed = []
    discrepancies = {}
    for name, signal in [
        ("delivered_heating_convective_power", "mod.rad.QCon_flow"),
        ("delivered_heating_radiative_power", "mod.rad.QRad_flow"),
    ]:
        if units[signal] != "W":
            raise ValueError("Reference radiator signal has wrong units")
        q = -np.asarray(raw[signal], dtype=float)  # heat leaving radiator enters zone
        s = Series(
            raw["time_s"],
            q,
            "W",
            name,
            "previous",
            ref.scenario,
            "pinned FMU",
            ref.reference_version,
            metadata["source_trajectory_sha256"],
        )
        actual = channels[name]
        if actual.unit != "W" or actual.interpolation != "previous":
            raise ValueError("Expected held delivered radiator power in W")
        expected = resample(s, actual.time_s)
        discrepancies[name] = float(np.max(abs(expected - actual.values)))
        source.append(resample(s, ref.time_s))
        observed.append((actual.time_s, actual.values, expected))
    if not np.array_equal(observed[0][0], observed[1][0]):
        raise ValueError("Candidate radiator channel times differ")
    if max(discrepancies.values()) > 1e-7:
        raise ValueError("Logged forcing does not match reference held inputs")
    t = ref.time_s
    qt = observed[0][1] + observed[1][1]
    total = channels["delivered_heating_power"]
    if total.unit != "W" or not np.array_equal(total.time_s, observed[0][0]):
        raise ValueError("Zone delivered-heat total uses a different unit/time grid")
    total_error = float(np.max(abs(total.values - qt)))
    if total_error > 1e-7:
        raise ValueError("Delivered zone-heat total differs from convective+radiative inputs")
    qt = total.values
    qr = observed[0][2] + observed[1][2]
    native_q = source[0] + source[1]
    energy = {
        "reference_30s_hold_kWh": integrate(t, native_q, "previous") / 3.6e6,
        "THERMA_logged_hold_kWh": integrate(observed[0][0], qt, "previous") / 3.6e6,
        "reference_on_log_grid_hold_kWh": integrate(observed[0][0], qr, "previous") / 3.6e6,
        "component_max_discrepancy_W": discrepancies,
        "zone_total_vs_components_max_W": total_error,
        "source_negative_power_samples": int(np.sum(native_q < 0)),
        "method": "Signed previous-hold reconstructions; no gas/equipment input or clamping",
        "limitation": (
            "Not continuous FMU energy or native integrator proof; "
            "adaptive export grid aliases held jumps"
        ),
    }
    if output.exists():
        raise ValueError("Refusing to overwrite existing output")
    output.mkdir(parents=True)
    values = resample(air, t)
    np.savetxt(
        output / "temperature.csv",
        np.column_stack([t, values, ref.values, native_q]),
        delimiter=",",
        header="time_s,THERMA_air_K,BOPTEST_air_K,reference_heat_W",
        comments="",
        fmt="%.17g",
    )
    np.savetxt(
        output / "heating.csv",
        np.column_stack([observed[0][0], qt, qr]),
        delimiter=",",
        header="time_s,THERMA_heat_W,reference_held_at_log_W",
        comments="",
        fmt="%.17g",
    )
    summary = {
        "status": "postprocessed_preserved_actual_results_no_simulation",
        "temperature_quantity": "air_temperature",
        "reference_temperature_source": "mod.case900Template.TAir",
        "excluded_operative_source": "reaTRoo_y",
        "temperature_unit": "K",
        "power_unit": "W",
        "heating_quantity": "delivered_zone_heat",
        "heating_source": "-(mod.rad.QCon_flow + mod.rad.QRad_flow)",
        "scenario": metadata["scenario"],
        "boptest_commit": metadata["boptest_commit"],
        "ideas_commit": metadata["ideas_commit"],
        "fmu_sha256": metadata["fmu_sha256"],
        "weather": manifest["active_weather_resource"],
        "sample_count": len(t),
        "metrics": metrics,
        "heating_energy": energy,
        "source_provenance": provenance,
        "reference_metadata_sha256": file_hash(reference / "reference_metadata.json"),
        "reference_manifest_sha256": file_hash(run / "manifest.json"),
        "reference_trajectory_sha256": file_hash(run / "trajectory.csv"),
        "reference_initialized_air_K": manifest["initialized_internal_values"][
            "mod.case900Template.TAir"
        ],
        "THERMA_initial_conditions": p["initial_conditions"]["status"],
        "limitations": prior["limitations"],
        "MATLAB_executed_in_cloud": False,
        "derived_files": {
            n.replace(".", "_"): file_hash(output / n) for n in ["temperature.csv", "heating.csv"]
        },
    }
    (output / "metrics.json").write_text(json.dumps(summary, indent=2) + "\n")
    plt = _pyplot(output)
    days = (t - t[0]) / 86400
    fig, ax = plt.subplots(figsize=(10, 4), layout="constrained")
    ax.plot(days, ref.values - 273.15, label="BOPTEST air: mod.case900Template.TAir", lw=1)
    ax.plot(days, values - 273.15, label="THERMA C2 air, solar-resolved", lw=1)
    ax.set(xlabel="Evaluation time (days)", ylabel="Indoor air temperature (°C)")
    ax.legend()
    ax.grid(alpha=0.25)
    fig.savefig(output / "temperature_comparison.png", dpi=250)
    plt.close(fig)
    fig, ax = plt.subplots(figsize=(10, 4), layout="constrained")
    ax.plot(days, values - ref.values, lw=1, label="THERMA air − BOPTEST air")
    ax.axhline(0, color="black", lw=0.7)
    ax.set(xlabel="Evaluation time (days)", ylabel="Air-temperature error (K)")
    ax.legend()
    ax.grid(alpha=0.25)
    fig.savefig(output / "temperature_error.png", dpi=250)
    plt.close(fig)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--study", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = prepare(args.study, args.reference, args.run, args.output)
    print(
        json.dumps(
            {"metrics": result["metrics"], "heating_energy": result["heating_energy"]}, indent=2
        )
    )
