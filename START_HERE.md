# THERMA C2.7 — R2024a byte-bounded CSV reader

1. Download the **C2.7 MATLAB ZIP** from replay-transfer (link in
   docs/C27_R2024A_READER_FIX.md), then use **Extract All**.
2. Choose a short, writable local path, for example `C:\THERMA_C27`.
   Open MATLAB R2024a with Simulink and Java enabled. R2021a/R2025a interfaces are retained
   by the prepared interface; do not mix releases within one study.
3. Set Current Folder to the extracted **THERMA_C27_MATLAB** folder containing
   this file and run_verification.m. Do not move any files or run inside the ZIP.
4. In the Command Window, first run:

   ```matlab
   run_verification("quick")
   ```

   This checks every packaged hash, executes all available MATLAB unit tests,
   generates the unchanged Simulink model and runs a **600 simulated-second smoke
   test**. It is not a full benchmark. Stop and preserve logs if tests fail.
5. Then run the actual four-experiment study:

   ```matlab
   run_verification("full")
   ```

   It runs no-solar/30 s, solar/30 s, solar/15 s and solar/5 s **sequentially**.
   Each includes 7 simulated warm-up days and 14 evaluation days. No runtime
   estimate is claimed; leave MATLAB running until the final index is printed.

No internet, Git, Python, Docker, FMU runtime or Simscape is needed on this PC.
The included unchanged builders create/save the real .slx model automatically.
No new MATLAB run was performed in Codex Cloud; numerical results remain pending.

## Storage and resuming

Default full mode saves the three standard replay exports, solver_metadata.json,
ordered energy_events.csv and generated model, but omits large simulation.mat and
full trajectory files. One simulation is released before starting the next.
To retain MAT/full trajectory, if storage permits:

```matlab
run_verification("full",'SaveSimulation',true,'SaveTrajectory',true)
```

Repeat the **same command/options** to resume after an interruption. Only completed
attempts with matching code/input/release/settings contracts and intact output hashes
are skipped. Corrupt/incomplete attempts are preserved and rerun in fresh folders.
Changing options/code/release requires fresh attempts. Never edit package inputs.
To deliberately rerun everything in fresh folders, use `'Resume',false`.

## What to send back

Outputs are under **outputs/boptest/c27/**:

- Session folders: MATLAB unit test CSV/MAT, Command Window diary, contract.json,
  and study_index.json (full mode). Quick mode has a smoke report/trajectory.
- Experiment folders: each contains separately named attempts. Preserve
  evaluation.csv, comparison_metadata.json, replay_run.json, solver_metadata.json,
  energy_events.csv and completion.json from the referenced successful attempts.

After full mode completes, ZIP the whole **outputs/boptest/c27** tree for transfer,
so the session index and its four relative experiment paths remain together. Large
optional MAT/trajectory/model files may instead be kept locally, **but** the original
completion receipt hashes every retained file, so full integrity verification/resume
requires those files too. The simplest option is default retention plus the whole tree.
Cloud analysis uses Python later; your university PC does not need Python.
If a chat upload exceeds 32 MiB, ZIP experiment folders and the session separately,
retaining their folder names/relative layout rather than sending a huge MAT file.

## If something fails

- Missing/changed file: re-extract the package into a fresh writable folder.
- Missing Simulink/licence: activate the university installation/licence.
- Test failure/incomplete test: stop; preserve test CSV/MAT and diary; do not bypass.
- Simulation error: preserve study_index.json if present, replay_run.json and diary.
  Recursive original causes are retained; send the reports, not only the last line.
- Already-open THERMA model: save unrelated work and close old generated THERMA models.
- Access denied/path issues: use a short local path, outside ZIP/read-only folders.

Existing C2.6C results and original reference packets are preserved. C2.7 has not
changed physical equations or fitted parameters. No convergence/real-world validation
claim follows merely from completing a run. See the C2.7 report and C3 design-only plan.


This updated package replaces only the event-export path, not the thermal model or
solver settings. Use a fresh extraction and keep previous results. Read
[the event-export fix and diagnostics](docs/C27_R2024A_READER_FIX.md). New MATLAB IO
regressions and university UNC resolution remain pending actual execution.

This revision corrects expected-EOF classification and removes the shared-workspace
cleanup callback. The original six event-export tests plus new EOF/cleanup regressions
must pass in quick mode before full mode. MATLAB success is not yet confirmed.


This revision removes numeric EOF-code assumptions entirely. It uses exact byte counts,
file positions, record validation and SHA-256. Run reproduce_boptest_csv_reader() after
adding scripts/matlab/boptest to record actual R2024a API observations if needed.
New MATLAB verification remains pending university execution.
