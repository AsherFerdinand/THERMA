"""Comparison reports must preserve experimental differences and physical meaning."""

import numpy as np
import pytest

from therma.comparison import Series
from therma.validation.reporting import markdown_report, study_report


def series(scenario="reference", quantity="air_temperature"):
    return Series(
        np.array([0.0, 1.0, 2.0]),
        np.array([293.0, 294.0, 295.0]),
        "K",
        quantity,
        "linear",
        scenario,
        "test",
        "pinned",
        "a" * 64,
    )


def metadata(scenario):
    return {
        "scenario_id": scenario,
        "signals": [{"quantity": "air_temperature", "unit": "K"}],
        "missing_inputs": ["absorbed solar"],
        "assumptions": ["explicit partial experiment"],
    }


def test_scenario_mismatch_requires_explicit_exploratory_pairing():
    r = {"air_temperature": series()}
    c = {"air_temperature": series("partial")}
    with pytest.raises(ValueError):
        study_report(r, c, metadata("reference"), metadata("partial"))
    report = study_report(
        r, c, metadata("reference"), metadata("partial"), allow_scenario_difference=True
    )
    assert report["classification"] == "exploratory_comparison"
    assert report["scenario_pair"] == {"reference": "reference", "candidate": "partial"}
    assert report["missing_inputs"] == ["absorbed solar"]
    assert report["signals"]["air_temperature"]["mae"] == 0
    text = markdown_report(report)
    assert "exploratory_comparison" in text and "absorbed solar" in text
    assert "No numerical acceptance" in text
    with pytest.raises(ValueError):
        study_report(
            r,
            c,
            metadata("reference"),
            metadata("partial"),
            classification="partial_reference_comparison",
            allow_scenario_difference=True,
        )


def test_proxy_quantities_not_promoted_to_equivalent_signals():
    r = {"radiative_temperature": series(quantity="radiative_temperature")}
    c = {"opaque_mean_surface_temperature": series(quantity="opaque_mean_surface_temperature")}
    report = study_report(r, c, metadata("reference"), metadata("reference"))
    assert report["classification"] == "not_comparable" and not report["signals"]


def test_validation_candidate_blocked_by_missing_readiness():
    with pytest.raises(ValueError, match="blocked"):
        study_report(
            {"air_temperature": series()},
            {"air_temperature": series()},
            metadata("reference"),
            metadata("reference"),
            classification="reference_validation_candidate",
        )
