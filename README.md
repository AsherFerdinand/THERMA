# THERMA

THERMA is a MATLAB/Simulink research project exploring building thermal dynamics
and hydronic heating control. It preserves a thesis reference, a reduced BESTEST
thermal-zone reconstruction, and a separate residential thermostat/valve/radiator
demonstration. Python supports reference analysis, provenance and packaging.

The residential model has user-reported successful native execution through C4.0.
Selected MATLAB evidence is archived; some original models and trajectories still
need backing up. BOPTEST comparisons quantify a reduced model's limitations;
they do not establish real-world validation. FLEXLAB is a separate experimental
test-cell candidate, not a residential replacement or an already-validated model.
No ML surrogate, production web application or new C4.3 physics is implemented.

## Run one MATLAB experiment

Use [MATLAB_QUICKSTART.md](MATLAB_QUICKSTART.md). The new lightweight C42B package
works in a fresh folder with an external FLEXLAB data path; no previous THERMA
installation, Git, Python or WSL is required on the university PC. The wrapper's
native R2025a verification remains pending. It performs measurement inspection,
not simulation, and returns a compact results ZIP.

Keep the historical university folder until its local storage audit and archival
receipts close preservation gaps. No automatic deletion is implemented.

## Engineering work

- [Residential heating](docs/C37_RESIDENTIAL_HEATING.md),
  [thermostat comparison](docs/C38_THERMOSTAT_COMPARISON.md),
  [BOPTEST comparison](docs/C39_BOPTEST_COMPARISON.md) and
  [integrated workbench](docs/C40_HEATING_SYSTEM.md).
- [FLEXLAB acquisition/feasibility](docs/C42B_VALIDATION_FEASIBILITY.md): authentic
  files acquired; CONDITIONAL separate single-zone envelope benchmark.
- [Milestone archive and missing backups](docs/PROJECT_MILESTONE_ARCHIVE.md).
- [Storage audit](docs/REPOSITORY_STORAGE_AUDIT.md) and
  [lightweight execution/results workflow](docs/LIGHTWEIGHT_MATLAB_WORKFLOW.md).
- [Roadmap](docs/ROADMAP.md), [progress](docs/PROGRESS.md) and
  [historical project overview](docs/archive/PROJECT_HISTORY_README_2026-11-10.md).

## Repository layout

`scripts/matlab/` contains the stable model builders/components; `configs/` holds
parameters. `experiments/` declares lightweight package dependencies, `tools/`
holds maintenance utilities, `verification/` and `docs/results/` preserve existing
evidence. `results/` describes future compact evidence imports. Original reference
measurements and generated outputs stay external/ignored. Stable source/evidence
paths have been retained rather than moved for appearance.

## Cloud development

Python3.12 and uv:

```bash
uv sync --frozen
uv run --frozen pytest
uv run --frozen ruff check .
uv run --frozen ruff format --check .
uv run --frozen mypy
# Build from a committed source revision; this tool runs in Codex, not on the PC.
uv run --frozen python tools/build_matlab_package.py C42B --output outputs/new_package
```

Read [AGENTS.md](AGENTS.md) and [development guidance](docs/DEVELOPMENT.md).
Keep verified physics and original evidence unchanged. Source provenance, native
MATLAB execution and reference/empirical validation are separate evidence categories.
