# MonsterLineage Current State

Last updated: 2026-09-14

## Active milestone

`v0.1` — generation-loop vertical slice.

The approved 0.1 target is a playable Godot prototype built around one controllable creature, survival, reproduction, inherited variation, descendant control transfer, and a persistent lineage within a single session.

Canonical integration branch: `main`.

## Implemented

### Task 1 — Project bootstrap and deterministic test harness

Implemented and merged:

- Godot 4.7.2 project bootstrap
- bootable main scene
- deterministic named RNG service
- game-time slowdown service
- headless test harness
- RNG tests
- README commands for tests and smoke boot

### Task 2 — Localization and procedural naming foundation

Implemented and merged:

- locale service
- Ukrainian/English localization foundation
- semantic generated-name records
- locale-aware name rendering
- data-driven naming profiles and lexemes
- deterministic procedural naming tests

### Task 3 — Body plans, traits, species, and genome model

Implemented and merged:

- body-plan definitions and content
- trait definitions and content
- species definitions and prototype content
- individual `Genome` resource
- genome value access and cloning behavior
- resource-validation and genome tests

## Current automated tests

The central runner is:

`tests/run_all.gd`

It currently registers these suites:

- `tests/test_rng_service.gd`
- `tests/test_localization_and_naming.gd`
- `tests/test_genome.gd`

There is currently no GitHub CI workflow in the repository, so test success must be verified locally before claiming a task is complete.

Run the full suite with:

```powershell
godot --headless --path . --script res://tests/run_all.gd

Smoke-boot with:

godot --headless --path . --quit-after 2
Next task
Task 4 — Individual creature state, needs, injury, personality, food memory, and significant memory

Planned files include:

src/creatures/needs_state.gd
src/creatures/injury_state.gd
src/creatures/personality_state.gd
src/creatures/food_memory.gd
src/creatures/memory_log.gd
src/creatures/creature_state.gd
tests/test_creature_state.gd

Task 4 should be implemented from the existing 0.1 implementation plan rather than redesigned independently.

Authoritative project documents

Current 0.1 implementation plan:

docs/superpowers/plans/2026-09-14-v0-1-vertical-slice.md

Approved design specification:

docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md

Repository code and tests are the source of truth for what is actually implemented. The plan/specification describe intended behavior.

Branch state
main — canonical integration/default branch
feat/v0-1-implementation — earlier integration branch created before main became canonical

New implementation work should normally happen on a task/feature branch and be merged into main after verification.

Known status notes
Tasks 1–3 are merged into the current baseline.
The Task 3 merge previously touched tests/run_all.gd; the current runner preserves all three implemented suites.
Task 4 creature-state files are not part of the current implemented baseline yet.
No save/load system is planned for 0.1.
Prototype art is intentionally non-blocking for current system work.
Update rule

Update this file whenever a task is merged into main or when a significant blocker changes the development state.

Keep it short and factual. Record:

what is actually merged
what is currently being worked on
known blockers or verification gaps
the next planned task
changes to the canonical branch/workflow

Do not use this file as a replacement for the full design specification, implementation plan, or architecture documentation.


6. Унизу в `Commit changes` залиш:
```text
docs: add current project state
