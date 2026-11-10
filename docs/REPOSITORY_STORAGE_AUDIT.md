# Repository/storage audit — 2026-11-10

Scope: the cloud checkout and currently published Git objects/transfer ZIPs.
**The university folder has not been measured.** No deletion, history rewriting,
force push or branch merge was performed. Original model/parameter/evidence paths
remain stable. [Machine-readable snapshot](REPOSITORY_STORAGE_SNAPSHOT.json)
records logical bytes, largest files/Git blobs, transfer archive inventory and
exact duplicate ZIP groups. [Milestone archive](PROJECT_MILESTONE_ARCHIVE.md)
separately documents missing native artifacts.

Classification: **KEEP** essential source/reference; **ARCHIVE** important history;
**REGENERATE** known generated output only after source/input checks; **EXCLUDE**
from experiment packages (not permission to delete); **REVIEW** unclear ownership,
backup or reproducibility. Unknown files are not deletion candidates.

| File/directory | Size (logical snapshot) | Purpose | GitHub status | Action |
|---|---:|---|---|---|
| Source snapshot,a57a62a |5,702,975B total | Complete prior engineering source/docs/compact evidence | Tracked feature branch | KEEP |
| scripts/ |512,187B | MATLAB components/builders and automation | Source tracked; caches,if any,ignored | KEEP required dependency closure;EXCLUDE unrelated experiments from run ZIP |
| src/,tests/ |354,659B /653,731B | Python analysis/software tests plus local caches | Source tracked,caches ignored | KEEP source in cloud;EXCLUDE from MATLAB run ZIP |
| data/ |6,325B | Reference metadata/acquisition instructions;raw data external | Metadata tracked;raw ignored | KEEP metadata;external measurements separate |
| tools/,experiments/,.github/,uv.lock | Small maintenance/configuration source | Packaging,CI and dependency lock | Tracked maintenance/engineering source | KEEP cloud;include only declared MATLAB/configuration dependencies on PC |
| configs/ |174,795B | Physical/reference/experiment parameters | Tracked | KEEP;no numerical changes |
| models/ |190B | Original-model acquisition/preservation guidance | README only;no native SLX | KEEP guidance;REVIEW missing native backups |
| verification/ |116,844B | Original C2 report,selected C3 reports/logs,case receipts | Tracked compact evidence | KEEP/ARCHIVE;selected summaries are not original report backup |
| docs/ |4,501,791B | Engineering history,figures and evidence metadata | Mostly tracked | ARCHIVE historical overview;retain stable reports/paths |
| outputs/ |2,286,062,890B (~2.13GiB) | FMU datasets/runtime/reference runs,replays,analysis/handoffs | Ignored;selected published ZIP bytes separately preserved | REVIEW/ARCHIVE;not safe blanket deletion |
| .venv/ |317,444,821B (~303MiB) | Cloud Python development environment | Ignored | EXCLUDE from MATLAB packages;regenerable via uv.lock,not assumed present on PC |
| .mypy_cache/,.pytest_cache/,.ruff_cache/ |13,730,711B combined | Cloud development caches | Ignored | EXCLUDE;regenerable,not engineering evidence |
| dist/ |4,086,336B | Python build products | Ignored | EXCLUDE/REGENERATE,not MATLAB inputs |
| .git/ |178,566,309B (~170MiB) | Local Git object store/history | Not shipped to university | KEEP cloud history;EXCLUDE from run packages |
| replay-transfer branch ZIPs |172,759,553B across22 ZIPs | Historical downloadable source/data/update snapshots | Published on separate branch | ARCHIVE unchanged;do not rewrite/delete existing artifacts |
| Cloud FLEXLAB acquisition outside THERMA |217,081,214B across35 original files | Authentic primary documents and measurements | External,not republished | KEEP external original data;licence unresolved;only six CSVs needed for C42B |
| Existing START*.md guides |~17KB combined | Historical phase-specific startup instructions | Tracked | Retain legacy guides;new packages use one MATLAB_QUICKSTART.md |

The source is small; accumulated execution data/environments/archives dominate.
There are **zero native `.slx` files** in the audited cloud checkout and in all22
transfer ZIPs. Every preserved model is a **builder/source**, not an archived native
model. No `.mat` or ZIP is tracked on the source branch. Source `.m` filenames
are unique by basename; shared C3 functions intentionally serve C3.4–C4.0.
Similar historical ZIPs are different revisions, not proven identical duplicates.
The cloud audit found **no exact duplicate ZIP groups**; the PC audit must check its
own copies before any duplicate-removal estimate.

Largest historical Git blobs are transfer artifacts: C26C all-in-one36,792,521B,
C26 solar packet36,415,347B,C28 standalone12,900,202B and repeated C27 revisions
~12.9MB each. Exact object IDs and paths are in the snapshot. They remain reachable
in original history; no reclamation through forbidden history rewriting is proposed.
Use small new execution ZIPs and reviewed release/external archives for future
large evidence instead. Inspecting ZIP members verified their CRCs and identities;
it did not prove MATLAB execution or revalidate numerical results.

## Cleanup proposal — nothing approved for deletion

| Candidate on university PC | Proposed action after verification and explicit approval | Potential savings |
|---|---|---|
| Duplicate identical ZIP copies | Keep at least one recoverable archive;review hash-identical extras | Sum of extra copies,computed by local audit;cloud verified0 |
| Superseded extracted packages | First back up unmatched SLX/MAT/results/autosaves;verify source/inputs and archive receipts | Folder size minus unique unbacked files;unknown until PC audit |
| slprj/,*.slxc | Confirm generated cache and absence of unique work | Actual local cache bytes;not measured |
| Python environment/caches/.git in a copied project | Not needed for MATLAB execution;preserve source/uv.lock/history elsewhere | If actually present;do not transfer cloud figures to PC estimates |
| Original reports,trajectories,models,*.asv | **KEEP: NOT YET BACKED UP unless exact preservation match exists** |0 approved |
| Original external FLEXLAB data | Store once in shared external folder,reuse by path | Avoid duplicated copies;retain originals/licence context |
| Old event CSVs/reference packets | Archive exact originals with input/source/solver provenance before review | Unknown;never discard essential validation records for size |

Six essential C42B CSVs total **52,960,350B (~53MB decimal)** and are not embedded
in the new ZIP. The execution source target is<10MB,actual delivery size/checksum
is in MAINTENANCE_DELIVERY.json. For illustration only,if a400MB installation has no
remaining unique artifacts after archival,keeping~53MB shared data plus a tiny run
folder could save roughly347MB before generated results. This is **not a measured
or approved deletion estimate**. The local audit determines actual byte totals and
preservation matches. A new temporary run folder may be discarded only after
important result receipts are archived and the user explicitly approves its removal.

Only the former cumulative README was archived (with relative links adjusted).
No physics source,reference configuration,original evidence or old startup guide
was removed or moved. The current README provides a short engineering overview.
The snapshot's dates/commits make it reproducible;maintenance-created sources are
covered separately by each new package manifest and its source commit.
