"""Static wiring regressions and analytical input examples; never execute MATLAB."""

import re
from pathlib import Path

import numpy as np
import pytest

from therma.comparison import Series, integrate, resample

ROOT = Path(__file__).resolve().parents[1]
MATLAB = ROOT / "scripts/matlab/boptest"


def test_root_inport_explicit_hold_and_actual_input_logging():
    source = (MATLAB / "build_boptest_zone_c2.m").read_text()
    root = re.search(
        r"add_block\('simulink/Sources/In1',\[model '/Inputs'\],(.*?)\);", source, re.S
    )
    assert root is not None and "'Interpolate','off'" in root.group(1)
    assert "add_line(model,'Inputs/1','Log_inputs_used/1')" in source
    assert "'VariableName','inputs_used'" in source
    expected = {
        "Outdoor_K": "1",
        "Heating_conv_W": "2",
        "Heating_rad_W": "3",
        "Internal_conv_W": "4",
        "Internal_rad_W": "5",
        "Solar_absorbed_W": "6:11",
    }
    found = dict(re.findall(r"select\('([^']+)','Inputs/1','([^']+)',11\)", source))
    assert found == expected


def test_accounting_checks_both_actual_and_prescribed_inputs():
    source = (MATLAB / "verify_boptest_zone_c2.m").read_text()
    assert "output.get('inputs_used')" in source
    assert "u = trace.inputs_used" in source
    assert "inputDiagnostics.passed &&" in source
    assert "boptest_piecewise_reference(" in source
    assert "boptest_hold_integral(" in source
    assert "interp1(c.time_s,c.values,t,'previous')" not in source
    reference = (MATLAB / "boptest_piecewise_reference.m").read_text()
    assert 'boptest_hold_values(time_s,values,edges(interval),"right")' in reference
    assert "time_s(time_s>previous & time_s<query_s(sample))" in reference


@pytest.mark.parametrize(
    "before,after", [(0, 1000), (1000, 0), (293.15, 283.15), (0, 300), (0, 210)]
)
def test_ramp_is_not_a_step(before, after):
    time = np.array([0.0, 3600.0, 7200.0])
    values = np.array([before, after, after])
    held = Series(
        time,
        values,
        "K" if before == 293.15 else "W",
        "test_input",
        "previous",
        "test",
        "v1",
        "pinned",
        "a" * 64,
    )
    query = np.array([0.0, 3599.0, 3600.0, 3601.0, 7200.0])
    np.testing.assert_array_equal(resample(held, query), [before, before, after, after, after])
    ramp = np.interp(query, time, values)
    assert abs(ramp[1] - resample(held, query)[1]) == pytest.approx(
        abs(after - before) * 3599 / 3600
    )
    assert integrate(time, values, "linear") - integrate(time, values, "previous") == pytest.approx(
        (after - before) * 1800
    )
