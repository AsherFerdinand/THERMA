"""Declared room arithmetic, supplied rating provenance and one-run scope."""

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
    assert "user_supplied_manufacturer_specifications" in rating
    assert "boptest_file_sha256" in rating
    assert "rated_output_W/(rating.return_C-rating.room_C)" in rating


def test_purmo_rating_and_mass_assumptions_match_supplied_evidence():
    import hashlib

    c = json.loads((ROOT / "configs/c37/radiator_rating.json").read_text())
    raw = (ROOT / c["source_file"]).read_bytes()
    evidence = json.loads(raw)
    assert hashlib.sha256(raw).hexdigest() == c["source_sha256"]
    assert evidence["evidence_kind"] == "user_supplied_transcription_of_manufacturer_product_page"
    assert not evidence["independently_retrieved_in_cloud"]
    for key in [
        "product_code",
        "rated_output_W",
        "supply_C",
        "return_C",
        "room_C",
        "water_content_L",
        "manufacturer_listed_mass_kg",
    ]:
        assert c[key] == evidence[key]
    assert c["product_code"] == "F062206010010P00"
    assert c["listed_mass_includes_water"] is None
    flow = c["rated_output_W"] / (4180 * (c["supply_C"] - c["return_C"]))
    ua = c["rated_output_W"] / (c["return_C"] - c["room_C"])
    water_h = flow * 4180
    assert abs(flow * 3600 - 74.4114832536) < 1e-9
    assert abs(ua - 34.56) < 1e-12
    assert abs(water_h * ua / (water_h + ua) * 35 - 864) < 1e-9
    water_mass = c["water_content_L"] * c["water_density_kg_L"]
    effective_metal = c["manufacturer_listed_mass_kg"] - water_mass
    assert abs(water_mass * 4180 + effective_metal * 500 - 39966) < 1e-9
    assert abs(water_mass * 4180 + c["manufacturer_listed_mass_kg"] * 500 - 43266) < 1e-9
