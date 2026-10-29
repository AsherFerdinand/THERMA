"""Time-series contracts and comparison metrics, without a thermal solver.

No accuracy threshold is inferred. Quantities must match semantically, not just
share a unit: gas input and delivered room heat are different quantities.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

import numpy as np
from numpy.typing import NDArray

Array = NDArray[np.float64]
Interpolation = Literal["linear", "previous"]
UNITS: dict[str, tuple[str, float, float]] = {
    "K": ("temperature", 1.0, 0.0),
    "degC": ("temperature", 1.0, 273.15),
    "W": ("power", 1.0, 0.0),
    "kW": ("power", 1000.0, 0.0),
    "J": ("energy", 1.0, 0.0),
    "kWh": ("energy", 3_600_000.0, 0.0),
    "1": ("dimensionless", 1.0, 0.0),
}


@dataclass(frozen=True)
class Series:
    time_s: Array
    values: Array
    unit: str
    quantity: str
    interpolation: Interpolation
    scenario: str
    model_version: str
    reference_version: str
    source_sha256: str
    max_gap_s: float | None = None

    def __post_init__(self) -> None:
        t = np.array(self.time_s, dtype=float, copy=True)
        y = np.array(self.values, dtype=float, copy=True)
        if t.ndim != 1 or y.shape != t.shape or len(t) < 2:
            raise ValueError("Expected at least two scalar samples with matching 1D time")
        if not np.isfinite(t).all() or not np.isfinite(y).all():
            raise ValueError("Nonfinite time or missing/nonfinite data")
        if np.any(np.diff(t) <= 0):
            raise ValueError("Time must strictly increase; duplicate timestamps are forbidden")
        if self.unit not in UNITS or self.interpolation not in ("linear", "previous"):
            raise ValueError("Unsupported unit or interpolation policy")
        for name in ("quantity", "scenario", "model_version", "reference_version"):
            if not getattr(self, name).strip():
                raise ValueError(f"Missing {name}")
        if len(self.source_sha256) != 64 or any(
            c not in "0123456789abcdef" for c in self.source_sha256
        ):
            raise ValueError("Expected lowercase SHA-256 provenance")
        if self.max_gap_s is not None:
            if not np.isfinite(self.max_gap_s) or self.max_gap_s <= 0:
                raise ValueError("max_gap_s must be finite and positive")
            if np.any(np.diff(t) > self.max_gap_s):
                raise ValueError("Missing samples: maximum allowed time gap exceeded")
        t.flags.writeable = False
        y.flags.writeable = False
        object.__setattr__(self, "time_s", t)
        object.__setattr__(self, "values", y)


def convert(values: Array, source: str, target: str) -> Array:
    if source not in UNITS or target not in UNITS:
        raise ValueError("Unsupported unit")
    dimension, factor, offset = UNITS[source]
    other, target_factor, target_offset = UNITS[target]
    if dimension != other:
        raise ValueError("Incompatible units")
    return np.asarray((values * factor + offset - target_offset) / target_factor, dtype=float)


def resample(series: Series, times: Array) -> Array:
    times = np.asarray(times, dtype=float)
    if times.ndim != 1 or not np.isfinite(times).all() or np.any(np.diff(times) <= 0):
        raise ValueError("Target times must be finite and strictly increasing")
    if len(times) == 0 or times[0] < series.time_s[0] or times[-1] > series.time_s[-1]:
        raise ValueError("No extrapolation or empty target grid")
    if series.interpolation == "previous":
        indices = np.searchsorted(series.time_s, times, side="right") - 1
        return np.asarray(series.values[indices], dtype=float)
    return np.asarray(np.interp(times, series.time_s, series.values), dtype=float)


def integrate(time_s: Array, values: Array, policy: Interpolation) -> float:
    """Integral of the declared reconstruction, not unknown continuous source power."""
    dt = np.diff(time_s)
    if policy == "previous":
        return float(np.sum(dt * values[:-1]))
    if policy == "linear":
        return float(np.sum(dt * (values[:-1] + values[1:]) / 2))
    raise ValueError("Unsupported integration policy")


def compare(reference: Series, candidate: Series) -> dict[str, object]:
    if reference.quantity != candidate.quantity:
        raise ValueError("Incompatible physical quantities (even if units match)")
    if reference.scenario != candidate.scenario:
        raise ValueError("Scenario mismatch")
    if reference.reference_version != candidate.reference_version:
        raise ValueError("Reference revision mismatch")
    if not np.array_equal(reference.time_s[[0, -1]], candidate.time_s[[0, -1]]):
        raise ValueError("Time coverage differs; explicitly trim both datasets first")
    # Union grid retains every known switching time; previous-hold signals are
    # never linearly interpolated across a discontinuity.
    times = np.union1d(reference.time_s, candidate.time_s)
    x = resample(reference, times)
    y = convert(resample(candidate, times), candidate.unit, reference.unit)
    error = y - x
    dimension = UNITS[reference.unit][0]
    relative_energy: float | None = None
    reference_energy: float | None = None
    candidate_energy: float | None = None
    if dimension == "power":
        factor = UNITS[reference.unit][1]
        reference_energy = integrate(times, x, reference.interpolation) * factor
        candidate_energy = integrate(times, y, candidate.interpolation) * factor
    elif dimension == "energy":
        factor = UNITS[reference.unit][1]
        reference_energy = float(x[-1] - x[0]) * factor
        candidate_energy = float(y[-1] - y[0]) * factor
    if reference_energy is not None and candidate_energy is not None and reference_energy != 0:
        relative_energy = (candidate_energy - reference_energy) / abs(reference_energy)
    return {
        "schema_version": 1,
        "status": "compared_no_accuracy_threshold_applied",
        "scenario": reference.scenario,
        "reference_version": reference.reference_version,
        "reference_model_version": reference.model_version,
        "candidate_model_version": candidate.model_version,
        "source_hashes": [reference.source_sha256, candidate.source_sha256],
        "quantity": reference.quantity,
        "unit": reference.unit,
        "mae": float(np.mean(abs(error))),
        "rmse": float(np.sqrt(np.mean(error**2))),
        "maximum_absolute_error": float(np.max(abs(error))),
        "mean_bias_error": float(np.mean(error)),
        "peak_value_difference": float(np.max(y) - np.max(x)),
        "reference_energy_J": reference_energy,
        "candidate_energy_J": candidate_energy,
        "relative_energy_difference": relative_energy,
        "alignment": {
            "method": "union of sample times, no extrapolation",
            "reference_interpolation": reference.interpolation,
            "candidate_interpolation": candidate.interpolation,
            "reference_samples": len(reference.time_s),
            "candidate_samples": len(candidate.time_s),
            "aligned_samples": len(times),
            "identical_grids": bool(np.array_equal(reference.time_s, candidate.time_s)),
            "duration_s": float(times[-1] - times[0]),
        },
        "limitations": [
            "Temperature/power MAE and RMSE are unweighted sample metrics on the union grid.",
            "No unknown event time or continuous source waveform is reconstructed.",
            "Zero reference energy yields null relative difference; no threshold implies a pass.",
        ],
    }


def compare_collection(
    reference: dict[str, Series], candidate: dict[str, Series]
) -> dict[str, object]:
    """Report missing quantities explicitly; do not infer a validation pass."""
    shared = sorted(reference.keys() & candidate.keys())
    reports = {name: compare(reference[name], candidate[name]) for name in shared}
    return {
        "schema_version": 1,
        "status": "compared_no_accuracy_threshold_applied" if shared else "comparison_not_ready",
        "signals": reports,
        "missing_candidate_signals": sorted(reference.keys() - candidate.keys()),
        "missing_reference_signals": sorted(candidate.keys() - reference.keys()),
        "limitations": [
            "No validation acceptance criteria have been applied.",
            "Air, opaque mean surface and operative temperatures are distinct quantities.",
        ],
    }
