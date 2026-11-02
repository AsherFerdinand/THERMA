"""Audit actual replay exports against a verified packet; never run a thermal model."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np

from therma.comparison import integrate
from therma.validation.analysis import _pyplot, file_hash, load_replay
from therma.validation.benchmark import matlab_json_metadata
from therma.validation.solar import verify_packet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["baseline", "solar", "packet", "output"]:
        parser.add_argument("--" + name, type=Path, required=True)
    args = parser.parse_args()
    checks = verify_packet(args.packet)
    packet = json.loads((args.packet / "replay.json").read_text())
    source = np.loadtxt(args.packet / "inputs.csv", delimiter=",", skiprows=1)
    t = source[:, 0] + packet["time_origin_s"]
    selected = t >= packet["evaluation_start_s"]
    st = t[selected]
    source_evaluation = source[selected]
    quantities = [c["quantity"] for c in packet["channels"][:5]]
    files = [
        directory / name
        for directory in [args.baseline, args.solar]
        for name in ["evaluation.csv", "comparison_metadata.json", "replay_run.json"]
    ]
    before = {p: file_hash(p) for p in files}
    output = {
        "scope": "actual uploaded CSV/JSON; no MATLAB run, no synthetic simulation",
        "source_packet_sha256": file_hash(args.packet / "replay.json"),
        "packet_checks": checks,
        "actual_input_checks": {},
        "source_hold_energy_kWh": {},
        "attachment_integrity": {},
        "simulation_mat": {
            "accessed": False,
            "reason": "Attachment exceeds tool 32 MiB download limit",
        },
    }
    collections = {}
    for label, directory in [("baseline", args.baseline), ("solar", args.solar)]:
        series, _, report = load_replay(directory)
        collections[label] = series
        times = series["air_temperature"].time_s
        indices = np.searchsorted(t, times, side="right") - 1
        if times[0] != packet["evaluation_start_s"] or times[-1] != packet["evaluation_end_s"]:
            raise ValueError("Evaluation coverage mismatch")
        audit = {}
        for j, quantity in enumerate(quantities, 1):
            actual = series[quantity]
            expected = np.interp(times, t, source[:, j]) if j == 1 else source[indices, j]
            error = actual.values - expected
            if np.max(abs(error)) > 1e-7:
                raise ValueError("Pointwise source mismatch: " + label + " " + quantity)
            audit[quantity] = {
                "max_absolute_discrepancy": float(np.max(abs(error))),
                "unit": actual.unit,
                "policy": actual.interpolation,
            }
        if label == "solar":
            if report["replay_packet_sha256"] != output["source_packet_sha256"]:
                raise ValueError("Actual replay packet provenance mismatch")
            if report["replay_metadata"] != matlab_json_metadata(packet):
                raise ValueError("Embedded metadata differs from original packet")
            audit["metadata_serialization"] = (
                "Original packet file SHA256 matches. Embedded MATLAB JSON fields use "
                "makeValidName underscores/truncation; JSON null becomes empty array."
            )
            expected = source[indices, 6:12].sum(axis=1)
            error = series["absorbed_solar_power"].values - expected
            if np.max(abs(error)) > 1e-7:
                raise ValueError("Actual absorbed solar mismatch")
            audit["opaque_solar_total"] = {"max_absolute_discrepancy_W": float(np.max(abs(error)))}
            internal = (
                series["internal_gain_power"].values
                - series["internal_convective_power"].values
                - series["internal_radiative_power"].values
            )
            derivative = (
                series["stored_energy_derivative"].values
                - series["net_external_power"].values
                - series["power_balance_residual"].values
            )
            audit["internal_component_max_discrepancy_W"] = float(np.max(abs(internal)))
            audit["derivative_minus_net_minus_residual_max_W"] = float(np.max(abs(derivative)))
            x = times
            energy = series["stored_thermal_energy"].values
            qnet = series["net_external_power"].values
            left = np.r_[0.0, np.cumsum(np.diff(x) * qnet[:-1])]
            trap = np.r_[0.0, np.cumsum(np.diff(x) * (qnet[:-1] + qnet[1:]) / 2)]
            balance = energy - energy[0] - left
            trap_balance = energy - energy[0] - trap
            output["energy_balance"] = {
                "stored_energy_change_J": float(energy[-1] - energy[0]),
                "previous_hold_net_energy_J": float(left[-1]),
                "previous_hold_final_residual_J": float(balance[-1]),
                "previous_hold_max_residual_J": float(np.max(abs(balance))),
                "trapezoid_final_residual_J": float(trap_balance[-1]),
                "trapezoid_max_residual_J": float(np.max(abs(trap_balance))),
                "interpretation": "Sampled quadrature diagnostics, not exact conservation proof; "
                "no second solver run and no original duplicate-event logs available.",
            }
        output["actual_input_checks"][label] = audit
        output["attachment_integrity"][label] = {
            p.name: {"sha256": before[p], "bytes": p.stat().st_size}
            for p in files
            if p.parent == directory
        }
    for j, c in enumerate(packet["channels"][1:], 2):
        output["source_hold_energy_kWh"][c["quantity"]] = (
            integrate(st, source_evaluation[:, j], "previous") / 3.6e6
        )
    output["source_hold_energy_kWh"]["opaque_solar_total"] = sum(
        v for k, v in output["source_hold_energy_kWh"].items() if k.startswith("absorbed_solar_")
    )
    output["source_hold_energy_kWh"]["glazing_separate"] = (
        checks["evaluation_solar_hold_energy_J"]["glazing"] / 3.6e6
    )
    output["interpretation"] = (
        "Baseline and solar radiator/internal forcings match the same source pointwise. "
        "Adaptive-log energy differences are not evidence of heating/control savings. "
        "Negative source radiator exchange is preserved, not clamped."
    )
    args.output.mkdir(parents=True, exist_ok=False)
    plt = _pyplot(args.output)
    solar = collections["solar"]
    fig, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
    for quantity, label in [
        ("delivered_heating_power", "Delivered radiator"),
        ("internal_gain_power", "Internal gains"),
        ("absorbed_solar_power", "Opaque solar"),
    ]:
        v = solar[quantity]
        axes[0].plot((v.time_s - v.time_s[0]) / 86400, v.values / 1000, lw=0.7, label=label)
    axes[0].set(ylabel="Input power (kW)")
    axes[0].legend(ncol=3)
    axes[0].grid(alpha=0.25)
    for quantity, label in [
        ("delivered_heating_convective_power", "Radiator convective"),
        ("delivered_heating_radiative_power", "Radiator radiative"),
    ]:
        v = solar[quantity]
        axes[1].plot((v.time_s - v.time_s[0]) / 86400, v.values / 1000, lw=0.7, label=label)
    axes[1].set(ylabel="Delivered power (kW)", xlabel="Evaluation day")
    axes[1].legend()
    axes[1].grid(alpha=0.25)
    fig.tight_layout()
    for suffix in ["png", "pdf"]:
        fig.savefig(args.output / f"energy_inputs.{suffix}", dpi=300)
    plt.close(fig)
    fig, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
    axes[0].plot((x - x[0]) / 86400, energy - energy[0], lw=0.8, label="Storage change")
    axes[0].plot((x - x[0]) / 86400, left, lw=0.8, label="Integrated net power (hold)")
    axes[0].set(ylabel="Energy (J)")
    axes[0].legend()
    axes[0].grid(alpha=0.25)
    axes[1].plot((x - x[0]) / 86400, balance / 1000, lw=0.8, label="Hold quadrature")
    axes[1].plot((x - x[0]) / 86400, trap_balance / 1000, lw=0.8, label="Trapezoid sensitivity")
    axes[1].set(ylabel="Sampled closure residual (kJ)", xlabel="Evaluation day")
    axes[1].legend()
    axes[1].grid(alpha=0.25)
    fig.tight_layout()
    for suffix in ["png", "pdf"]:
        fig.savefig(args.output / f"energy_closure.{suffix}", dpi=300)
    plt.close(fig)
    assert all(file_hash(p) == value for p, value in before.items())
    (args.output / "audit.json").write_text(json.dumps(output, indent=2, allow_nan=False) + "\n")
    print(json.dumps(output["energy_balance"], indent=2))


if __name__ == "__main__":
    main()
