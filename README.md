# THERMA

A research project for a modular, web-based digital twin of hydronic building heating.
The project began with a MATLAB/Simulink bachelor's thesis describing a three-storey apartment
building with 36 rooms, a central boiler, distribution pipes, radiators and controllers.
The reference repository has been inspected statically; see [the inventory](docs/SIMULINK_INVENTORY.md).
Reference assets are not vendored, and raw validation datasets are not yet available.

Current scope: **Phase B — original BOPTEST FMU baseline executed**. No Python physics solver, surrogate, API or web UI
is implemented. Original-FMU reference outputs exist; no THERMA/Simulink equivalence
or performance improvement is claimed.

## Development

Prerequisites: Python 3.12 and [uv](https://docs.astral.sh/uv/). From the checkout root:

```bash
# The cache override works in cloud environments with a read-only home directory.
export UV_CACHE_DIR=/workspace/.cache/uv  # optional on other machines
uv sync --frozen
uv run --frozen pytest
uv run --frozen ruff check .
uv run --frozen ruff format --check .
uv run --frozen mypy
```

`uv.lock` pins runtime and development packages. `uv sync --frozen` creates `.venv` and
installs the project in editable mode. No services, credentials or MATLAB installation
are needed for Phase 0. Future dependencies will be added when their phases begin.

## Configuration

`configs/project.toml` contains non-physical project metadata. Load it explicitly:

```python
from therma.config import load_config

config = load_config("configs/project.toml")
print(config.name)
```

Paths resolve from the caller's working directory. The loader rejects unknown keys,
empty names and incorrect types. Physical schema, units and solver controls are deferred
until the reference model has been verified in MATLAB; no default physical values are assumed.

## Layout

- `src/therma/`: Python package and configuration loader
- `tests/`: automated tests
- `configs/`: versioned, non-secret configuration examples
- `docs/`: roadmap, progress, architecture decisions and reference handoff
- `models/simulink/`: guidance for preserving the original reference model
- `data/raw/`, `data/processed/`: local datasets; generated contents are ignored
- `notebooks/`, `scripts/`: reserved analysis and automation locations

Read [the roadmap](docs/ROADMAP.md), [progress](docs/PROGRESS.md), and
[development guidance](docs/DEVELOPMENT.md) before contributing.

Phase 1A deliverables: [migration plan](docs/MIGRATION_PLAN.md) and
[reference data plan](docs/REFERENCE_DATA_PLAN.md). University MATLAB diagnostics remain pending.

The selected independent reconstruction reference is now BOPTEST `bestest_hydronic`
(BESTEST Case 900 envelope). Read [the pinned physical/reference extraction](docs/BOPTEST_REFERENCE.md)
and its [machine-readable parameters](configs/references/boptest_bestest_hydronic.json).
The thesis model and local EN 12831 room-builder draft remain separate; neither has
been validated as a BOPTEST reconstruction. The original BOPTEST FMU has now run via
an isolated FMI runtime; MATLAB simulation is still pending.

See [baseline results and reproduction commands](docs/BOPTEST_BASELINE.md) and the
[envelope-first Simulink contract](docs/BOPTEST_SIMULINK_CONTRACT.md). Generated CSVs,
plots, FMUs and runtime environments remain under ignored `outputs/boptest/`.

The [C1 layered-envelope builder and university execution guide](docs/BOPTEST_SIMULINK_C1.md)
are prepared with 27 source-derived thermal states. MATLAB generation, compilation
and physics verification remain pending; no C2 room-air model is included.
