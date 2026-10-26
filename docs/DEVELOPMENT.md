# Development workflow

Use the Python 3.12 and uv commands in README.md. Run commands from the repository root.
For changes to dependencies, edit pyproject.toml, run `uv lock`, review the lockfile,
then run `uv sync --frozen` and all affected checks. Ordinary setup must not rewrite
manifests or the lockfile. Never commit secrets or generated datasets.

Required Phase 0 checks: pytest, Ruff lint and format, mypy, and `uv build` (wheel and
source distribution). CI runs these on Python 3.12. Optional external checks such as
MATLAB execution, browser tests, GPU training or Docker startup do not apply yet.
No CI execution on GitHub is claimed by a local check.

## Engineering boundaries

The initial package intentionally contains only project metadata configuration.
NumPy, SciPy and Pandas are available for subsequent scientific development. MATLAB
Engine, scikit-learn, XGBoost, PyTorch, FastAPI and frontend packages are deferred until
required; installing them now would not validate their future workflows.

Planned modules will separate physical components and solvers, scenario orchestration,
reference-model adapters, data pipelines, surrogate training and service/UI layers.
Do not let HTTP or database concerns determine the physics interfaces. Decide equations,
units, numerical methods and fidelity from reference evidence before implementing them.

SQLite uses Python's standard library when needed. PostgreSQL and Docker are deferred.
No license has been selected: do not assume permission to redistribute thesis assets
or project code without an explicit licensing decision.

## Reference handoff

Before Phase 1 execution, obtain the original model, supporting MATLAB scripts and data,
MATLAB release/toolbox requirements, and permission to use the assets. Inventory them
before running code. Record checksums, provenance and a baseline; preserve the original
files and operate on copies or documented runtime overrides. Do not commit large or
restricted assets without an explicit storage and licensing decision.

Record output names, units, sample times, initial conditions, solver settings, controller
logic and parameter sources. A documented baseline run is necessary before claiming
Python equivalence. The stated building size alone does not establish any physical
parameter or acceptance tolerance.
