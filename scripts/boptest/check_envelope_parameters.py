"""Static C1 parameter/discretisation audit only; never integrates a thermal model.

Independent algebraic assembly checks MATLAB-generated parameters.json when supplied.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "configs/references/boptest_bestest_hydronic.json"
REGISTRY_SHA256 = "f91141d78668908525d484a4900dc69af1a163c4c5e07f5a5fbd0c43eae4451c"
BOPTEST = "a29024f8c453517ccbd1186006a3fa6af8de1ae2"
IDEAS = "f1fdd8b22d39dc50297c47b6433e44381e40d0ff"


def near(actual: float, expected: float, label: str) -> None:
    # Same documented arithmetic budget as MATLAB: 64 binary64 ULPs, not physics error.
    if abs(actual - expected) > 64 * np.spacing(max(1.0, abs(expected))):
        raise ValueError(f"Inconsistent {label}: {actual} versus {expected}")


def extract_envelope(registry: dict) -> dict:
    if registry.get("schema_version") != 1:
        raise ValueError("Unsupported registry schema")
    if registry["repositories"]["boptest"]["commit"] != BOPTEST:
        raise ValueError("Wrong BOPTEST revision")
    if registry["repositories"]["ideas"]["commit"] != IDEAS:
        raise ValueError("Wrong IDEAS revision")
    entries = {p["id"]: p for p in registry["parameters"]}
    if len(entries) != len(registry["parameters"]):
        raise ValueError("Duplicate parameter ID")

    def entry(name: str) -> dict:
        if name not in entries:
            raise ValueError(f"Missing {name}")
        e = entries[name]
        if e["status"] not in ["explicit", "derived"] or not e.get("sources"):
            raise ValueError(f"Unverified {name}")
        return e

    def number(name: str, unit: str) -> float:
        e = entry(name)
        if e["unit"] != unit:
            raise ValueError(f"Wrong units for {name}")
        value = e["value"]
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f"Not numeric: {name}")
        if not math.isfinite(value) or value <= 0:
            raise ValueError(f"Nonpositive/nonfinite {name}")
        return float(value)

    length, width, height = [
        number("building." + key, "m") for key in ["length", "width", "height"]
    ]
    glazing = number("building.window_area", "m2")
    floor = number("building.floor_area", "m2")
    near(floor, length * width, "floor area")
    near(number("building.volume", "m3"), length * width * height, "volume")
    for flag in ["use_T_fixed", "use_T_in", "use_Q_in"]:
        if entry("floor." + flag)["value"] is not False:
            raise ValueError("Floor outer boundary is not adiabatic")
    definitions = [
        ("South_Wall", "wall", "wall_south_opaque_area", length * height - glazing),
        ("North_Wall", "wall", "wall_north_opaque_area", length * height),
        ("East_Wall", "wall", "wall_east_opaque_area", width * height),
        ("West_Wall", "wall", "wall_west_opaque_area", width * height),
        ("Roof", "roof", "roof_area", floor),
        ("Floor", "floor", "floor_area", floor),
    ]
    components = []
    for name, kind, area_id, expected_area in definitions:
        area = number("building." + area_id, "m2")
        near(area, expected_area, name + " area")
        layer_ids = [
            k for k in entries if k.startswith(kind + ".layer") and k.endswith(".material")
        ]
        if not layer_ids:
            raise ValueError(f"Missing {kind} layers")
        layers = []
        for i in range(1, len(layer_ids) + 1):
            prefix = f"{kind}.layer{i}"
            material = entry(prefix + ".material")["value"]
            if not isinstance(material, str) or not material:
                raise ValueError(f"Invalid {prefix} material")
            d = number(prefix + ".thickness", "m")
            k = number(prefix + ".k", "W/(m.K)")
            rho = number(prefix + ".rho", "kg/m3")
            cp = number(prefix + ".c", "J/(kg.K)")
            count = number(prefix + ".material_node_count", "1")
            n = max(2, math.ceil(3 * d / math.sqrt(k / (rho * cp)) / 224))
            if count != n:
                raise ValueError(f"Wrong node count: {prefix}")
            resistance, capacity = d / (k * area), rho * cp * d * area
            near(resistance * area, number(prefix + ".R_areal", "m2.K/W"), prefix + " R")
            near(capacity / area, number(prefix + ".C_areal", "J/(m2.K)"), prefix + " C")
            weights = np.ones(n) / n if n <= 2 else np.r_[0.5, np.ones(n - 2), 0.5] / (n - 1)
            layers.append(
                {
                    "material": material,
                    "n_source": n,
                    "R_K_W": resistance,
                    "C_J_K": capacity,
                    "local_C_J_K": capacity * weights,
                }
            )
        # Independent indexed accumulation, rather than MATLAB's append-and-merge loop.
        starts = np.r_[0, np.cumsum([x["n_source"] - 1 for x in layers])[:-1]]
        total_nodes = 1 + sum(x["n_source"] - 1 for x in layers)
        capacities = np.zeros(total_nodes)
        conductances = []
        for first, layer in zip(starts, layers, strict=True):
            indices = np.arange(first, first + layer["n_source"])
            np.add.at(capacities, indices, layer["local_C_J_K"])
            conductances.extend(
                [float((layer["n_source"] - 1) / layer["R_K_W"])] * (layer["n_source"] - 1)
            )
            layer["local_C_J_K"] = layer["local_C_J_K"].tolist()
        r_total = sum(x["R_K_W"] for x in layers)
        c_total = sum(x["C_J_K"] for x in layers)
        near(sum(1 / g for g in conductances), r_total, name + " network R")
        near(float(capacities.sum()), c_total, name + " network C")
        near(r_total * area, number(kind + ".R_material_areal", "m2.K/W"), kind + " registry R")
        components.append(
            {
                "name": name,
                "kind": kind,
                "area_m2": area,
                "adiabatic_exterior": kind == "floor",
                "layers": layers,
                "n_states": total_nodes,
                "C_J_K": capacities.tolist(),
                "G_W_K": conductances,
                "R_total_K_W": r_total,
                "C_total_J_K": c_total,
                "reference_K": number("building.initial_temperature", "K"),
            }
        )
    near(
        sum(x["area_m2"] for x in components[:4]),
        number("building.wall_total_opaque_area", "m2"),
        "wall area sum",
    )
    for kind in ["wall", "roof", "floor"]:
        near(
            sum(x["C_total_J_K"] for x in components if x["kind"] == kind),
            number(kind + ".C_material_total", "J/K"),
            kind + " total C",
        )
    return {
        "status": "static_parameter_audit_only",
        "matlab_executed": False,
        "components": components,
        "total_states": sum(c["n_states"] for c in components),
    }


def compare_matlab(audit: dict, matlab: dict) -> None:
    if matlab["registry_sha256"] != REGISTRY_SHA256:
        raise ValueError("MATLAB audit used a different registry")
    if matlab["total_states"] != audit["total_states"]:
        raise ValueError("MATLAB state count differs")
    for expected, actual in zip(audit["components"], matlab["components"], strict=True):
        for key in ["name", "kind", "n_states", "adiabatic_exterior"]:
            if expected[key] != actual[key]:
                raise ValueError(f"MATLAB {key} differs")
        for key in ["C_J_K", "G_W_K"]:
            x, y = np.asarray(expected[key]), np.asarray(actual[key]).reshape(-1)
            if x.shape != y.shape or not np.all(
                np.abs(x - y) <= 64 * np.spacing(np.maximum(1, np.abs(x)))
            ):
                raise ValueError(f"MATLAB {expected['name']} {key} differs")
        for key in ["area_m2", "R_total_K_W", "C_total_J_K"]:
            near(actual[key], expected[key], "MATLAB " + key)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=REGISTRY)
    parser.add_argument("--matlab-parameters", type=Path)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "outputs/boptest/simulink_c1/static_parameter_audit.json",
    )
    args = parser.parse_args()
    digest = hashlib.sha256(args.registry.read_bytes()).hexdigest()
    if digest != REGISTRY_SHA256:
        raise ValueError("Frozen reference registry SHA-256 differs")
    audit = extract_envelope(json.loads(args.registry.read_text()))
    audit["registry_sha256"] = digest
    if args.matlab_parameters:
        compare_matlab(audit, json.loads(args.matlab_parameters.read_text()))
        audit["matlab_parameter_comparison"] = "passed; not a simulation verification"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(audit, indent=2, allow_nan=False) + "\n")
    print(f"Static audit passed: {audit['total_states']} unique nodes. {args.output}")


if __name__ == "__main__":
    main()
