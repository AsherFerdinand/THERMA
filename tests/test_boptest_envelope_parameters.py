"""Static source-parameter audits; these do not execute MATLAB or a thermal solver."""

import copy
import hashlib
import importlib.util
import json
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "envelope_audit", ROOT / "scripts/boptest/check_envelope_parameters.py"
)
assert spec is not None and spec.loader is not None
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


@pytest.fixture
def registry():
    return json.loads(audit.REGISTRY.read_text())


def test_frozen_registry_and_geometry(registry):
    assert hashlib.sha256(audit.REGISTRY.read_bytes()).hexdigest() == audit.REGISTRY_SHA256
    result = audit.extract_envelope(registry)
    assert result["matlab_executed"] is False
    assert [c["area_m2"] for c in result["components"]] == pytest.approx(
        [9.6, 21.6, 16.2, 16.2, 48, 48]
    )
    assert result["total_states"] == 27
    assert [c["n_states"] for c in result["components"]] == [5, 5, 5, 5, 4, 3]


def test_source_discretisation_and_interface_mass(registry):
    for c in audit.extract_envelope(registry)["components"]:
        assert all(x > 0 for x in c["C_J_K"] + c["G_W_K"])
        assert sum(1 / g for g in c["G_W_K"]) == pytest.approx(c["R_total_K_W"])
        assert sum(c["C_J_K"]) == pytest.approx(sum(x["C_J_K"] for x in c["layers"]))
        offset = 0
        for left, right in zip(c["layers"][:-1], c["layers"][1:], strict=True):
            offset += left["n_source"] - 1
            assert c["C_J_K"][offset] == pytest.approx(
                left["local_C_J_K"][-1] + right["local_C_J_K"][0]
            )
        # Internal edge power cancels globally for arbitrary node temperatures.
        edge_power = np.asarray(c["G_W_K"]) * np.diff(np.arange(c["n_states"]) ** 2)
        net = np.zeros(c["n_states"])
        net[:-1] += edge_power
        net[1:] -= edge_power
        assert abs(net.sum()) <= 64 * np.spacing(max(1, abs(edge_power).max()))
    floor = audit.extract_envelope(registry)["components"][-1]
    assert floor["adiabatic_exterior"] is True
    assert floor["C_total_J_K"] == pytest.approx(5380833.6)


@pytest.mark.parametrize(
    ("parameter", "field", "value"),
    [
        ("building.volume", "value", 130),
        ("wall.layer1.k", "unit", "W/K"),
        ("wall.layer1.k", "value", 0),
        ("wall.layer1.k", "value", float("nan")),
        ("wall.layer1.k", "status", "unresolved"),
        ("wall.layer1.k", "sources", []),
        ("wall.layer3.material_node_count", "value", 2),
        ("floor.use_T_fixed", "value", True),
    ],
)
def test_reject_inconsistent_parameters(registry, parameter, field, value):
    next(p for p in registry["parameters"] if p["id"] == parameter)[field] = value
    with pytest.raises(ValueError):
        audit.extract_envelope(registry)


def test_reject_missing_and_duplicate_parameters(registry):
    broken = copy.deepcopy(registry)
    broken["parameters"] = [p for p in broken["parameters"] if p["id"] != "wall.layer1.k"]
    with pytest.raises(ValueError, match="Missing"):
        audit.extract_envelope(broken)
    registry["parameters"].append(copy.deepcopy(registry["parameters"][0]))
    with pytest.raises(ValueError, match="Duplicate"):
        audit.extract_envelope(registry)


def test_reject_reference_revision_change(registry):
    registry["repositories"]["ideas"]["commit"] = "unverified"
    with pytest.raises(ValueError, match="revision"):
        audit.extract_envelope(registry)
