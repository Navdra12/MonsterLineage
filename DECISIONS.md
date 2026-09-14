# MonsterLineage Decision Log

This file records accepted project and architecture decisions that should remain stable across implementation tasks.

Do not rewrite old decisions merely because the implementation evolves. If a decision is replaced, add a new entry that explicitly supersedes the previous one.

Primary references:

- `docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md`
- `docs/superpowers/plans/2026-09-14-v0-1-vertical-slice.md`
- `CURRENT_STATE.md`

---

## D001 — The player directly controls one creature

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Project-wide

MonsterLineage remains creature-first. The player directly controls one living individual rather than an abstract faction, colony, or empire cursor.

Large-scale lineage, faction, ecology, and civilization systems may exist later, but they must not replace direct creature-scale play as the core player perspective.

**Reason:** The central fantasy is inhabiting a concrete organism across a changing lineage.

---

## D002 — Major body-plan changes happen between generations

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Project-wide

A living creature may grow, molt, heal, strengthen existing structures, or undergo limited physiological changes.

Fundamental anatomy changes and major body-plan transitions belong primarily to descendants.

**Reason:** This keeps generational evolution meaningful and prevents one creature from freely transforming into unrelated forms during a single life.

---

## D003 — Biology is data-driven

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

Reusable biological definitions should be represented as data where practical.

Examples include:

- body plans
- traits
- species definitions
- naming profiles
- localization lexemes

Godot `Resource` and `.tres` content are the preferred representation for authored reusable biological data in v0.1.

**Reason:** New biological content should usually be addable without creating new hard-coded branches throughout gameplay logic.

---

## D004 — Shared definitions and individual runtime state are separate

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

Shared definition Resources must not contain mutable state belonging to one creature.

Shared definitions include objects such as:

- `BodyPlanDef`
- `TraitDef`
- `SpeciesDef`

Individual state includes objects such as:

- genome values
- age
- injuries
- needs
- personality
- memories
- temporary conditions

**Reason:** Godot Resources may be shared by many consumers. Creature-specific mutation of shared definitions would create aliasing and ownership bugs.

---

## D005 — Genetics is a gameplay model, not chromosome simulation

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Project-wide

MonsterLineage does not attempt chromosome-level biological realism.

The genetic model uses:

- body-plan identity
- modular inherited traits
- compatibility constraints
- recombination
- mutation
- developmental rules where required

The implementation should remain understandable, deterministic when seeded, and useful for gameplay.

**Reason:** The design needs meaningful heredity and variation without the complexity of full molecular genetics.

---

## D006 — Stable semantic IDs are authoritative

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

Simulation systems should exchange stable semantic identifiers rather than player-facing strings.

Examples:

- `arachnid_small`
- `move_speed`
- `web_strength`
- `nest_descriptor`

Player-facing translated text is presentation data and must not become the authoritative identity of simulation objects.

**Reason:** Stable IDs support localization, deterministic generation, testing, refactoring, and future content expansion.

---

## D007 — Simulation data must be independent from scene/UI nodes where practical

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

Core simulation data and services should be usable without requiring a rendered gameplay scene.

Scene nodes and UI consume simulation interfaces rather than owning the authoritative biological state.

Examples of headless-testable domains include:

- genomes
- creature state
- lineage
- naming
- localization logic
- procedural generation
- reproduction rules

**Reason:** The project depends heavily on deterministic automated testing and will later need simulation at multiple levels of detail.

---

## D008 — Random generation must be reproducible from explicit seeds

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

World generation, procedural naming, offspring generation, mutation, and other meaningful random systems should support reproducibility from explicit seeds.

v0.1 uses named RNG streams derived from a root seed.

Tests must not depend on uncontrolled global randomness when deterministic behavior is expected.

**Reason:** Reproducibility is required for debugging, testing, and eventually persistent procedural world history.

---

## D009 — Localization is part of the data model from the start

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Project-wide

Ukrainian is the initial complete locale for v0.1, with English support included in the localization foundation.

Gameplay-critical player-facing strings must not be hard-coded inside simulation logic.

Procedural names are stored as semantic records and rendered through locale-aware rules rather than assembled from already translated display strings.

**Reason:** Grammar-aware procedural naming and future language support require semantic information to survive independently of presentation text.

---

## D010 — v0.1 uses Godot 4.7.2 and GDScript

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** v0.1

The pinned engine target is:

`Godot 4.7.2 stable Standard`

v0.1 uses GDScript and built-in Godot systems. No third-party runtime or test dependency is required by the approved implementation plan.

**Reason:** A fixed engine/runtime target reduces avoidable compatibility problems while the foundation is being built.

---

## D011 — v0.1 is real-time with strong slowdown

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** v0.1

The main gameplay model is 2D top-down real-time.

Tactical decision-making uses strong slowdown rather than converting the game into a turn-based system.

**Reason:** The design requires immediate creature-scale movement and survival while still allowing deliberate tactical choices.

---

## D012 — v0.1 deliberately limits world scope

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** v0.1

The first vertical slice uses one persistent procedural zone combining the required prototype environments.

v0.1 does not implement the later full multi-region historical simulation.

**Reason:** The vertical slice must validate the creature → survival → reproduction → descendant-control loop before large-scale world simulation is added.

---

## D013 — No save/load system in v0.1

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** v0.1

The v0.1 acceptance path runs across several generations within one session.

Persistent save/load is intentionally deferred.

**Reason:** Save compatibility would add significant implementation cost before the foundational data models and gameplay loop are stable.

---

## D014 — Foundational systems require headless automated tests

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Development workflow

Foundational systems should be covered by automated tests and remain runnable headlessly.

The central test entry point is:

`tests/run_all.gd`

When a new suite belongs to the full test set, it must be registered without removing existing valid suites.

**Reason:** Genetics, procedural generation, lineage, and other simulation systems are easier to verify deterministically outside gameplay scenes.

---

## D015 — `main` is the canonical integration branch

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Development workflow

`main` is the canonical default/integration branch.

New implementation work should normally happen in task or feature branches and be merged into `main` after verification.

`CURRENT_STATE.md` describes what is actually integrated into the current baseline.

**Reason:** A stable canonical branch prevents task branches and old integration branches from becoming competing sources of truth.

---

# Adding future decisions

Add a new entry when a task makes a durable decision that meaningfully constrains later work.

Good candidates include:

- ownership of important state
- authoritative data representation
- cross-system dependency direction
- persistence format
- simulation level-of-detail strategy
- reproduction/inheritance representation
- major engine or tooling changes

Do not add routine implementation details that can be understood directly from the code.

If a decision changes, add a new decision with:

`Supersedes: DXXX`

and explain why the previous decision is no longer appropriate.
