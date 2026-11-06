"""Check declared room arithmetic and retain the one-run/no-invented-rating gate."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_residential_configuration_is_separate_and_explicit():
    c = json.loads((ROOT / "configs/c37/residential_room.json").read_text())
    g = c["geometry"]
    assert g["length_m"] * g["width_m"] == 20
    assert g["length_m"] * g["width_m"] * g["height_m"] == 50
    assert c["conditions"]["air_initial_C"] == 15
    assert c["conditions"]["fabric_initial_C"] == 20
    assert c["conditions"]["duration_s"] == 86400
    assert c["boundaries"] == [
        "outdoors",
        "adjacent_conditioned",
        "outdoors",
        "adjacent_conditioned",
        "adiabatic",
        "adiabatic",
    ]
    for kind in ["external_wall", "partition", "ceiling", "floor"]:
        assert len(c[kind]) == len(c[kind + "_materials"])
        assert all(len(layer) == 4 and all(v > 0 for v in layer) for layer in c[kind])


def test_one_run_and_verified_manufacturer_source_required():
    entry = (ROOT / "run_c37_residential_heating.m").read_text()
    assert entry.count("output=sim(") == 1
    assert entry.count("fig=figure(") == 2
    assert entry.index("c37_radiator_parameters()") < entry.index("c35_build_case(")
    assert "assess_c34(" in entry and "c35_metrics(" in entry
    rating = (ROOT / "scripts/matlab/c37/c37_radiator_parameters.m").read_text()
    assert "verified_manufacturer_source" in rating
    assert "boptest_file_sha256" in rating
    assert "rated_output_W/(rating.return_C-rating.room_C)" in rating
