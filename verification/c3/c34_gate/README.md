# Actual university C3.4 execution evidence

Original c34_verification.json SHA-256:
b92885c8e4b36c37f1679aa48cfdc58a6cb87cedbc3322b04106a6898418af86.
Original report and log are preserved unchanged under ignored
outputs/c3/evidence/b92885c8e4b36c37/. They contain private network paths and are not
published. summary.json is a selected summary omitting model_file, not the original
report. The separately named public test log is explicitly path-redacted; its
hash and the original log hash are recorded. Neither copy is presented as an
independently generated cloud test log.

Actual report: 17 passed, 0 failed, 0 incomplete, 57.9763809 s; MATLAB/Simulink
R2025a. The nominal 86400-second simulation completed in 2.0866746 s according to
its report. All 15 integration-source hashes, original baseline configuration and
previous component-summary hash match preserved repository files. Every reported
numerical check passed. No original SLX or trajectory CSV was supplied, so their
binary contents/final air temperature/full histories cannot be rechecked here.
This verifies the supplied source/configuration gate, not field/BOPTEST accuracy.
C3.5 case results remain pending actual MATLAB execution.
