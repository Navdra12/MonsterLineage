# MonsterLineage Current State

Last updated: 2026-09-15

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

### Task 4 — Individual creature state

- needs and bounded progression
- lightweight semantic body-part injuries
- personality history with suspected and visible thresholds
- food memory and preference/aversion tracking
- significant-event memory with importance-based pruning
- multiplayer-safe `CreatureState` simulation data

## Current automated tests

Central runner:

`tests/run_all.gd`

Registered suites:

- `tests/test_rng_service.gd`
- `tests/test_localization_and_naming.gd`
- `tests/test_genome.gd`
- `tests/test_creature_state.gd`

Run the full suite:

```powershell
godot --headless --path . --script res://tests/run_all.gd
```

Smoke boot:

```powershell
godot --headless --path . --quit-after 2
```

There is currently no GitHub CI workflow. Test success must therefore be verified locally.

## Next task

### Task 5 — Deterministic forest-and-burrow zone generation

Planned scope:

- deterministic semantic zone generation
- forest and underground burrow terrain
- stable spawn points and nest candidates
- headless zone-generation tests

## Authoritative project documents

Implementation plan:

`docs/superpowers/plans/2026-09-14-v0-1-vertical-slice.md`

Design specification:

`docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md`

Repository code and tests are the source of truth for what is actually implemented.

## Branch state

- `main` — canonical integration/default branch
- `feat/v0-1-implementation` — previous integration branch

New work should normally happen on a task/feature branch and be merged into `main` after verification.

## Known status

- Tasks 1–4 are implemented and merged into `main`.
- The current test runner contains all four implemented suites.
- Task 5 is the next implementation task.
- Multiplayer remains a supported long-term direction and is not part of the v0.1 implementation.
- No save/load system is planned for v0.1.
- Prototype art is intentionally non-blocking for current system work.

## Update rule

Update this file whenever a task is merged into `main` or when a significant blocker changes.

Keep it factual and current. Record:

- what is actually merged
- what is currently in progress
- verification gaps or blockers
- the next task
- important workflow changes
