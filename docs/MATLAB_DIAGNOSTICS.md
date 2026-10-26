# MATLAB reference diagnostics — Phase 1B.1

This workflow inspects the pinned thesis model without running a simulation or changing
its settings. **It has not been executed in MATLAB in the Codex cloud.** Static checks
cannot establish model compilation, toolbox licensing or numerical correctness.
Phase 1B.2 must wait for the actual university-machine results.

## Download and prepare

1. Download/update [THERMA](https://github.com/AsherFerdinand/THERMA) including
   `scripts/matlab/diagnose_reference.m`. Keep its directory layout; generated outputs
   are relative to the script's THERMA root, not MATLAB's current folder.
2. Download the [original thesis repository at the analysed commit](https://github.com/AsherFerdinand/SimulinkMATLAB-dynamic-hydronic-balancing-simulation/tree/a4b6451f74a436b8daa57633962c91202c5b39e3).
   Extract it somewhere **outside THERMA**. Required input:
   `model/Main_SpeedOptimisedVersionTannenweg.slx`. Keep supporting files for review,
   but do not add the original repository to the MATLAB path or run its scripts.
3. Use a fresh MATLAB R2024b session (the model was saved with Update 5). Required
   installed products are MATLAB, Simulink, Simscape and Simscape Fluids. Stateflow
   availability is also recorded; its separate licensing requirement needs confirmation
   on the university installation. No parallel, optimisation or ML toolbox is required.
4. Do not open/double-click the SLX yet. Review and loading are deliberately separate.
   No licence checkout, server address, licence number or credential is exported by
   the script. Availability tests are local booleans and do not guarantee compilation.

## Stage 1: archive review without loading the model

Set MATLAB's Current Folder to the **THERMA root**, then paste (change only `source`):

```matlab
addpath(fullfile(pwd, 'scripts', 'matlab'));
source = "C:/your/reference/model/Main_SpeedOptimisedVersionTannenweg.slx";
reportFile = diagnose_reference(source);
disp(reportFile)
```

Linux/macOS paths work too. The function accepts spaces in paths. It checks the exact
Phase 1A SHA-256, copies the SLX to a unique system temporary directory, verifies the
copy, and extracts archive data into an ignored run directory. It does **not** call
`load_system`, compile, resolve MATLAB expressions or execute embedded model code at
this stage. `ver` and selected `license('test', ...)` queries describe the local machine.

Each call creates a new `outputs/matlab/<unique-run>/` under THERMA containing:

- `diagnostics.json`: statuses, archive block/connection evidence, mappings and errors.
- `callbacks_review.json`: nonempty XML callback/function/script/initialization/code
  fields, including embedded controller code and mask code where present.
- `archive_review/`: complete extracted archive for manual inspection. It can contain
  binary workspace data; it is not a safe executable folder and must not be added to PATH.

Review JSON in MATLAB's Editor or a text editor. `load_status=not_attempted` is expected.
The callback list is a discovery aid, **not a security audit or proof that no callbacks
exist**. Inspect the extracted `simulink/blockdiagram.xml`, all system XML, masks,
configuration, code/data-source fields, Stateflow scripts, S-functions and external
references. Check Model Workspace data source metadata/binary content and external
files with a knowledgeable colleague if anything is unclear. A pinned hash proves file
identity, not trust. Do not approve unknown code. Use the partial report if review cannot
establish that loading is appropriate.

## Stage 2: explicitly authorise loading the reviewed bytes

Only after reviewing the exact archive/code, run:

```matlab
reviewedHash = "2b797e2b23320cf9514e1b761efeb7c39d8bf56f761b307776ade23330c1651f";
reportFile = diagnose_reference(source, ReviewedHash=reviewedHash);
```

Supplying the hash is your explicit acknowledgement that load-time callbacks, mask
initialization, linked libraries and relevant expressions have been reviewed. The
function does not suppress or edit them: doing so would change the reference behaviour.
Loading is **not sandboxed**. Review any non-MathWorks libraries/dependencies separately.
Use a fresh session without unrelated work; reviewed model callbacks can still affect
MATLAB session state. A previously loaded model with the same name blocks the operation;
close it yourself rather than allowing diagnostics to close or overwrite your work.

The temporary SLX keeps the original filename/model name. The script changes Current
Folder to the temporary directory during inspection, does not add reference paths,
then closes only its own model without saving, restores Current Folder and removes the
temporary SLX. It rehashes the original after cleanup. `source_unchanged=true` is the
preservation check. Extracted review evidence remains under ignored `outputs/`.
Loading from a clean directory may expose missing relative-path dependencies; this is
reported rather than fixed by adding unreviewed code to the path.

Loaded inspection records solver settings, workspace variable names/types and values
for the known scientific variables, effective dialog parameter expressions and selected
resolved numeric values, paired unit fields, model paths/port connectivity, reference
library/link status, controller scripts and thermostat candidates. Expression resolution
can execute MATLAB expressions, so it occurs only after review acknowledgement. Values
of unrelated base-workspace variables are never dumped.

## Optional Stage 3: compile diagnostics, with no simulation

After reviewing Stage 2 results and dependencies, explicitly request compilation:

```matlab
reportFile = diagnose_reference(source, ReviewedHash=reviewedHash, Compile=true);
```

This uses model compile/terminate calls, not `sim`. Compilation can execute initialization
callbacks, library/mask code and MATLAB Function compilation: approve only after review.
It may take time for Simscape to build; no sweeps or warm-up simulation are performed.
The workflow never changes parameters, solver settings, switch positions or logging.
Compilation errors/warnings are captured, and the original is still checked afterward.
`compile_status=compiled` means diagram compilation succeeded, **not** that the model
was simulated, all units were resolved, or a validation baseline exists.

## Reading the report

| Report section | What it establishes / limits |
|---|---|
| `source_sha256`, `source_sha256_after`, `source_unchanged` | Exact input identity and preservation. Hash mismatch stops before archive extraction/load. |
| `products`, `licences` | Installed product versions and selected feature availability tests only; no licence identifiers/servers. |
| `archive.systems` | Saved blocks, SID references, expressions, unit fields and raw line/branch endpoints; includes inactive/commented content. |
| `archive.room_and_valve_mapping.rooms` | 36 room paths, room-to-tag-to-floor-Mux wiring, and global indices when root Memory/Mux/floor widths trace unambiguously. Empty indices mean unresolved, never guessed. |
| `archive.room_and_valve_mapping.selectors`, `.valves` | All saved selector indices and gate-valve paths, with associated selector descendants in their heater subsystem. Missing indices are reported, not assigned artificial actuators. |
| `solver` | Effective loaded solver settings and literal duration when safely parseable. Expressions beyond numeric multiplication remain unresolved rather than evaluated arbitrarily. |
| `workspace`, `blocks` | Scientific workspace values, effective mask/dialog expressions, selected numeric resolution, paired units, mask enable/visibility metadata and connectivity. Saved alternatives are not automatically active. |
| `controllers` | Embedded function text and candidate relays/switches/thermostat-named blocks. A boiler Relay is not a room thermostat. |
| `compiled_ports` | Queried compiled Simulink port units/dimensions/sample times. Conserving/physical port units may remain unresolved; query errors are retained. |
| `errors`, `load_console`, `compile_console`, last-warning fields | Failures and console warnings; last-warning alone is not the full warning history. Inspect per-block query errors too. |

Use the mappings to associate indices 1, 13, 25 with actual rooms, then inspect their
saved heater and thermal/physical connectivity. A missing command path can be confirmed;
its modelling intent cannot be inferred solely from that absence. Confirm global Mux
order and active variants/widths before treating the map as a runtime signal contract.
Static re-tracing during Phase 1B.1 associates these indices with `EG/Raum1`,
`OG1/Raum1` and `OG2/Raum1`; those saved room subtrees have no gate valve or heater
subsystem. This explains the structural gap, not why the author chose that layout or
whether a historic scenario differed. The report includes `missing_actuation_rooms`.
No missing control scenarios are reconstructed.

Check temperature converters (`Unit`, `AffineConversion`), valve selector/filter/scaling
and opening units, source heat-flow conversion and pump/tank masks. Look for mass-flow
initialization/unit fields and compiled ports. If the physical-port unit is not accessible,
record it as unresolved and inspect the Simscape block documentation/property view in
the approved temporary model on a separate manual diagnostic run. A `mdot0_unit` field
is not proof that a measured flow output exists. No sensors/logging are added here.

## Common problems

- **HashMismatch:** wrong version, modified SLX or an HTML/LFS placeholder download.
  Obtain the pinned original; do not replace the expected checksum to force success.
- **Missing toolbox/licence or unresolved library:** keep the partial report; arrange
  university access to the named product/library. A licence test can pass while compile
  still fails. Do not share licence files, server details or university credentials.
- **Undefined variable:** inspect `workspace` and the parameter's per-block query error.
  Confirm the original workspace/data-source configuration; do not invent a value or
  import your entire interactive workspace to hide the problem.
- **Unit mismatch/invalid physical connection:** preserve the diagnostic and source
  settings. The saved unit-1 valve converter versus a dimensional opening is an existing
  question, not permission to repair the model in this task.
- **AlreadyLoaded:** save/close your own work and start a fresh MATLAB session, then retry.
- **Unresolved mappings or no separate local thermostat:** return the evidence. No match
  does not prove a historical scenario never existed; obtain the original configuration.
- **Write/Java/XML error:** use a writable THERMA checkout and standard MATLAB with JVM
  enabled. The workflow requires Java for hashing/XML and does not support `-nojvm`.
- **Interrupted run or close callback error:** inspect open models before closing them
  yourself. The report may be from the most recent checkpoint and lack final preservation
  fields. Recheck the original SHA-256; do not assume cleanup ran after a forced process exit.

## Return results and next gate

Review `diagnostics.json` and `callbacks_review.json` before sharing. Error/console text
and model expressions can contain local paths or licence diagnostics even though the
script does not deliberately collect them. Redact usernames, absolute paths, licence
servers and credentials, retaining error identifiers, model-relative paths and technical
messages. Transfer these two files as private attachments to the THERMA conversation;
do not commit them or the extracted SLX contents. `outputs/`, Simulink build caches and
editor autosaves are ignored. Do not use `git add -f` to bypass those rules.

Return the reviewed-load/compile report if possible; a partial Stage 1 report is useful
when execution is blocked. Codex will reconcile mappings, active units, scenario gaps
and diagnostics before proposing Phase 1B.2. No simulation or Python physics/ML work
should begin until those results are available.
