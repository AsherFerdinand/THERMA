# Incoming C3.4 baseline evidence review

The user supplied the actual verification JSON and MATLAB console log. All source/
configuration hashes match the preserved implementation. The report records
**R2025a**, 17 tests passed, zero failed/incomplete, duration 57.9763809 s, and a
completed 86400 s simulation. Codex did not execute MATLAB.

| Supplied diagnostic | Value |
|---|---:|
| Logged air minimum | 14.76753274 °C |
| Logged air maximum | 17.70689053 °C |
| Maximum absolute delivered radiator power | 1586.915949 W |
| Native delivered energy | 36.86579156 kWh |
| Native water-side input energy | 37.04066826 kWh |
| Observed thermostat transitions | 0 |
| Radiator integrated error maximum | 2.21701339e-6 J |
| Combined integrated error maximum | 9.26294597e-5 J |
| Combined integrated error at end | −1.81422802e-5 J |
| Maximum instantaneous combined residual | 2.35331754e-11 W |
| Heating-port / partition mismatch | 0 / 0 W |

The water/delivered energy difference is approximately 0.17487670 kWh. Within the
reported balance residual, this is increased radiator stored energy, not fuel or
pump electricity. The room did not reach the 21 °C setpoint in the reported
samples. Zero observed transitions is consistent with a continuously active
thermostat below its threshold; it is not evidence of faulty thermostat logic.

The full trajectory, actual final air temperature and zone/environment energy
histories were not supplied. Maximum temperature must not be silently relabeled
as final temperature. The report alone cannot separate insufficient steady heat
capacity from long fabric warm-up or large envelope/ventilation/window losses.
C3.5 therefore records all three using native storage/loss energies and a conditional
steady-state diagnostic before drawing conclusions. No new UA/supply/solar result,
comfort integral or convergence result is reconstructed from these scalar values.

The originals remain unmodified locally. Public selected/path-redacted evidence
is under verification/c3/c34_gate/, with hashes of both original attachments.
Existing C2.8 results and their scientific qualifications remain unchanged.
