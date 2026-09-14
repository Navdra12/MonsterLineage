# MonsterLineage Current State

Last updated: 2026-09-14

## Active milestone

`v0.1` — generation-loop vertical slice.

The current target is a playable Godot prototype built around survival, reproduction, inherited variation, descendant control transfer, and lineage continuity within one session.

Canonical integration branch: `main`.

## Implemented

### Task 1 — Project bootstrap and deterministic test harness

- Godot 4.7.2 project bootstrap
- bootable main scene
- deterministic named RNG service
- game-time slowdown service
- headless test harness
- RNG tests

### Task 2 — Localization and procedural naming foundation

- locale service
- Ukrainian/English localization foundation
- semantic generated-name records
- locale-aware name rendering
- data-driven naming profiles and lexemes
- deterministic naming tests

### Task 3 — Body plans, traits, species, and genome model

- body-plan definitions and content
- trait definitions and content
- species definitions and prototype content
- individual `Genome` resource
- genome value access and cloning
- genome/resource validation tests

## Current automated tests

Central runner:

`tests/run_all.gd`

Registered suites:

- `tests/test_rng_service.gd`
- `tests/test_localization_and_naming.gd`
- `tests/test_genome.gd`

Run the full suite:

```powershell
godot --headless --path . --script res://tests/run_all.gd

Smoke boot:

godot --headless --path . --quit-after 2

There is currently no GitHub CI workflow. Test success must therefore be verified locally.

Next task
Task 4 — Individual creature state

Planned scope:

needs
injuries
personality
food memory
significant-event memory
aggregate CreatureState
tests/test_creature_state.gd

Task 4 should follow the existing 0.1 implementation plan rather than being redesigned independently.

Authoritative project documents

Implementation plan:

docs/superpowers/plans/2026-09-14-v0-1-vertical-slice.md

Design specification:

docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md

Repository code and tests are the source of truth for what is actually implemented.

Branch state
main — canonical integration/default branch
feat/v0-1-implementation — previous integration branch

New work should normally happen on a task/feature branch and be merged into main after verification.

Known status
Tasks 1–3 are merged.
The current test runner contains all three implemented suites.
Task 4 is not implemented yet.
No save/load system is planned for v0.1.
Prototype art is intentionally non-blocking for current system work.
Update rule

Update this file whenever a task is merged into main or when a significant blocker changes.

Keep it factual and current. Record:

what is actually merged
what is currently in progress
verification gaps or blockers
the next task
important workflow changes

Коміт назви:

```text
docs: fix current project state
