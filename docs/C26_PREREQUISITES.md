# C2.6 prerequisites — investigation only

No THERMA equations, parameters, replay packet or existing baseline dataset were
changed. This document proposes future work; it does not implement C2.6 or promise
an error reduction. The first actual comparison remains exploratory (MAE 2.34053 K,
bias -2.33520 K), with missing solar and reduced exchange/glazing physics confounded.

## Results-only download

The unchanged prepared ZIP is published only on the independent `replay-transfer`
branch, never merged into development:

[Download THERMA_first_typical_actual_analysis.zip](https://github.com/AsherFerdinand/THERMA/raw/refs/heads/replay-transfer/THERMA_first_typical_actual_analysis.zip)

- Size: **1,804,074 bytes**.
- SHA-256: `108a5502e5604993a0782dad7759fa7f099732ddcb34c152063bcd1848e10314`.
- Transfer commit: `4f35abfa919a707034ff0ec64114fd0430bd9cbf`.
- Contents: six PNG/PDF figure pairs, metrics.json, engineering_summary.md and
  supplementary integrity/input/temperature reports and reproduction script.
- Excludes raw MATLAB uploads, reference CSV datasets, Simulink models and caches.
- Verified ZIP integrity/members locally and downloaded the remote blob into a new
  isolated bare Git repository; uploaded bytes have exactly the same SHA-256.

## Pinned evidence and investigation performed

- BOPTEST: `a29024f8c453517ccbd1186006a3fa6af8de1ae2`.
- IDEAS: `f1fdd8b22d39dc50297c47b6433e44381e40d0ff`.
- Original FMU: `365b3085d97cc4620c06b6036156126a056d7f160fcc4f181d6b2fac4b05743b`.
- modelDescription.xml: `f181acdca7167a092a993e68bf4fbbd4f3edfa90b629074d06abf39a90a96fd8`.
- Frozen extraction JSON remains unchanged. Its 11,738-variable FMU catalog was
  inspected directly, including one-based ModelStructure/Derivatives indices and
  Real@derivative pointers, aliases, units, causality and capabilities.
- Downloaded selected pinned IDEAS source files read-only; verified their hashes
  against the existing extraction registry before reading equations/connections.
- Actually initialized the unchanged original FMU at the typical warm-up start
  **28,252,800 s** and read all 39 declared continuous states, 38 opaque temperature
  aliases, solar quantities and weights. FMPy 0.3.20 / NumPy 1.26.4 used the existing
  isolated native runtime. No physical/control/tolerance parameter overrides.
- For daytime readability only, advanced that instance 24 times by 1800 s (12 hours).
  This short access probe uses a different communication grid from the 30 s baseline.
  Its daytime values are **not** replacement baseline data or validation results.
- Probe script/report remain under ignored outputs/boptest/prerequisites/c26/.
  Report SHA-256: `86f9c4cb8e6e9d3a8ac92c54fde5ea36f624a94c3e417eb28732870fffe30435`.
  FMU bytes were rehashed unchanged after execution. MATLAB was not executed.

## 1. Absorbed interior solar: accessible inputs, not six clean public outputs

The source exports sufficient **internal FMI Real variables** to derive the solar-only
power delivered to each surface. It does not expose six separate public BOPTEST REST
solar measurements. These variables were omitted from the existing Phase B export
allowlist; they are not inherently inaccessible.

Prefix: `mod.case900Template.radDistr.`

| Quantity | Variable suffix | Value reference | Unit / variability |
|---|---|---|---|
| Direct transmitted solar entering distributor | `iSolDir.Q_flow` | 2509 | W, local continuous |
| Diffuse transmitted solar entering distributor | `iSolDif.Q_flow` | 2510 | W, local continuous |
| Existing longwave internal/radiator gains entering distributor | `radGain.Q_flow` | 2511 | W, local continuous |
| Combined distributed surface powers | `radSurfTot[1:7].Q_flow` | 2512–2518 | W, local continuous |
| Direct allocation weights | `weightFactorDir[1:7]` | 1601,1602,1603,1604,1348,1605,1606 | Dimensionless, fixed |
| Diffuse allocation weights | `weightFactorDif[1:7]` | 1511–1517 | Dimensionless, fixed |
| Other radiative gain allocation | `weightFactorGain[1:7]` | 1518–1524 | Dimensionless, fixed |

These are total powers in W; do not multiply by window/surface area again or
substitute irradiance W/m². Probe reads succeeded before and after original-FMU stepping.

The pinned [ZoneLwGainDistribution.mo](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/BaseClasses/RadiativeHeatTransfer/ZoneLwGainDistribution.mo#L82)
initial equations (82–98) define the weights, and lines 104–110 define:

```text
radSurfTot[i].Q_flow = -wDif[i]*Qdif - wDir[i]*Qdir - wGain[i]*Qgain
solar_only_into_surface[i] = wDif[i]*Qdif + wDir[i]*Qdir
```

This is a source-equation derivation, **not a new optical model**. Positive solar
power enters the receiving surface. Do not inject `-radSurfTot` as solar: that also
contains gains already supplied through the current radiative heating/internal ports.
Surface-to-surface longwave exchange is a separate connected model and must not be
confused with the pure solar contribution either. Wall-local iSol connector names
can be aliases of zero; the distributor's transmitted-solar inputs are the correct
read points.

Source [PartialZone.mo lines 379–443](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/Interfaces/PartialZone.mo#L379)
traces the solar buses, gain connections and surface distributor. Source
[RectangularZoneTemplateInterface.mo](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/Interfaces/RectangularZoneTemplateInterface.mo#L990)
indices 990–1012 and connections 1115–1158 establish the receiver order.

| Source surface index | Receiver | C2 receiver position | Direct weight | Diffuse weight |
|---|---|---:|---:|---:|
| 1 | South / outA | 1 | 0.03072 | 0.05549132948 |
| 2 | West / outB | 4 | 0.05184 | 0.09364161850 |
| 3 | North / outC | 2 | 0.06912 | 0.12485549133 |
| 4 | East / outD | 3 | 0.05184 | 0.09364161850 |
| 5 | Floor / bouFlo | 6 | 0.6 | 0.27745664740 |
| 6 | Roof / outCei | 5 | 0.1536 | 0.27745664740 |
| 7 | South glazing / winA | absent | 0.04288 | 0.07745664740 |

Therefore C2 order south/north/east/west/roof/floor selects source indices
**[1,3,4,2,6,5]**. Both complete seven-element weight vectors sum to one.
Do **not** renormalize the six opaque weights to hide the glazing share.
The glazing also absorbs radiation within its own glass layers; that is distinct
from the distributor's seventh interior receiver and is not implemented by static UA.

The 12-hour probe read Qdir=947.475696 W, Qdif=798.973317 W. Source solar-only powers
in seven-surface order were approximately [73.443,123.934,165.246,123.934,790.166,
367.213,102.514] W. The combined source distribution equation closed within
2.85e-14 W. These are accessibility examples at one probe instant, not a 14-day
solar energy estimate or an explanation of the measured temperature error.

## 2. Initialized states and limits of access

The FMU declares **39 continuous states**:

- 27 distinct opaque-envelope temperatures (38 layer-temperature alias names).
- 2 glazing temperatures.
- 4 moist-air balance states: U, mass, water-vapor mass fraction inventory and trace mass.
- 5 radiator-fluid energy states.
- 1 PI integrator state.

All 39 state variables were readable with FMI `getReal` after initialization. Air
TAir is also readable as an algebraic medium temperature (VR 2439). Some XML start
attributes are 289.15 K; they are guesses/declarations, **not** the initialized solution.

**Observed after initialization:** all 27 opaque temperatures, both glazing temperatures,
air and radiative temperature are **293.15 K**. The current C2 uniform temperature
start at the same original warm-up time therefore already matches those source
initial temperatures. A supposed inaccessible/nonuniform initial fabric-temperature
vector is not a supported explanation for this replay's bias. This does not prove
that seven-day warm-up eliminates differing physics or medium/storage effects.

C2 exterior-to-interior temperature mapping can use these value references:

| C2 construction | Source component | Ordered unique VRs |
|---|---|---|
| South | outA | 2022,2021,2023,2025,2024 |
| North | outC | 2032,2031,2033,2035,2034 |
| East | outD | 2037,2036,2038,2040,2039 |
| West | outB | 2027,2026,2028,2030,2029 |
| Roof | outCei | 2042,2041,2043,2044 |
| Floor | bouFlo | 2019,2018,2020 |

These follow layer-local node reversal and shared-interface aliases in pinned
[MultiLayer.mo lines 83–109](https://github.com/open-ideas/IDEAS/blob/f1fdd8b22d39dc50297c47b6433e44381e40d0ff/IDEAS/Buildings/Components/BaseClasses/ConductiveHeatTransfer/MultiLayer.mo#L83).
Deduplicate shared-interface VRs; do not copy aliases into extra C2 capacities/states.
Glazing state VRs 2016/2017 have no current C2 dynamic counterparts. Moist-air U/m/
mXi/mC VRs are 2045–2048; their state basis is not the C2 constant-capacity dry-air
node. In particular, source U initially equals -6086517.0336 J due to the medium's
energy reference; it must not be copied into C2's relative stored-energy diagnostic.

At evaluation-start restart, source temperatures are not generally uniform: request
all mapped states at that exact boundary in a future recorded run, rather than using
only room temperature. Such observable temperature snapshots are **not** a full
FMI/solver restart. Co-Simulation does not provide Model Exchange getContinuousStates;
this FMU does not advertise canGetAndSetFMUstate (default false) and explicitly sets
canSerializeFMUstate=false. Python binding method availability does not override
those capabilities. Do not call setReal on local continuous states or pretend a JSON
snapshot restores hidden solver/discrete/controller history.

## 3. Minimum future changes, in order

1. **Observability-only reference export.** Expand a separate/preserved version of
   run_reference.py's internal read allowlist: direct/diffuse solar totals, all seven
   direct/diffuse weights and combined distribution for an independent closure check;
   record all 27 mapped temperatures plus TAir/glazing/moist-air state diagnostics at
   initialization and evaluation start. Preserve original baseline artifacts, FMU,
   parameters, weather and controls. Export all forcing on the same 30 s baseline
   grid, retaining source names/units/signs/hashes. No new optical equations needed.
2. **Solar-resolved partial replay packet.** Derive only the six opaque powers using
   the pinned formula/order; record the seventh glazing allocation separately.
   Update prepare's currently zero-filled channels and loader's explicit omitted-solar
   validation in an opt-in new packet schema/mode. Rename the scenario suffix honestly;
   retain the old no-solar packet for reproducibility. Existing C2 absorbed-solar
   ports already accept these powers; no opaque conduction changes are required.
3. **Initial-temperature checks, not tuning.** Record the actual initialized vector
   and assert it matches mapped start temperatures. For this scenario, retain 293.15 K
   and the existing seven-day warm-up; no temperature adjustment is justified by this
   probe. Nonuniform restart support would need a separate explicit state/energy-reference
   design, not reuse of room temperature or source moist-air energy.
4. **Export full energy diagnostics.** The existing C2 model already logs q_net_W and
   dE_dt_W. Export them alongside storage/residual without changing equations, or derive
   a separate diagnostics CSV from saved simulation.mat. This closes the current data
   gap for piecewise sampled integral diagnostics; small instantaneous residual alone
   is insufficient.
5. **Controlled comparison before more physics.** Run no-solar versus solar-resolved
   partial replay with identical settings. Verify seven-surface solar sums and no
   radiative-gain double counting, event policies, input pointwise agreement, reference
   time grid, initialization and solver sensitivity. Report measured changes only;
   do not fit h/capacity coefficients to offset omissions.
6. **Then assess glazing/exterior exchange.** The solar-only opaque replay remains
   partial: absent dynamic window/glass gains, different radiative allocation including
   glazing, exterior absorbed solar/sky radiation and nonlinear exchange still prevent
   exact equivalence. Review the minimum two-glazing-state and exterior-boundary
   requirements before calling anything fully matched. No substitution of window
   absorbed power directly into room air merely to conserve a desired sum.

## 4. Proposed C2.6 gates and present status

- A: source observability export reviewed and reproduced, with full initialization
  and evaluation-start temperature snapshots plus solar closure diagnostics.
- B: explicit solar-resolved packet contract, indexing/units/sign and seven-surface
  energy tests; no arbitrary zero substitution or renormalization.
- C: local MATLAB replay, preserved no-solar baseline and numerical convergence/
  piecewise energy diagnostics, then actual comparison measurements.
- D: decide measured next physics scope (glazing, exterior exchange, radiative
  environment, moist air) before hydronic feedback/C3. No guaranteed error reduction.

**Implemented in this task:** results-only publication and prerequisite investigation/
documentation. **Not implemented:** C2.6 physics, calibration, exporter/packet changes,
solar replay or any new MATLAB simulation. The successful original C2 verification
remains valid for its existing reduced equations, not these proposed extensions.
