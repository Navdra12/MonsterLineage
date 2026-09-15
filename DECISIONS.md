# MonsterLineage Decision Log

This file records accepted project and architecture decisions that should remain stable across implementation tasks.

Do not rewrite old decisions merely because the implementation evolves. If a decision is replaced, add a new entry that explicitly supersedes the previous one.

Primary references:

- `docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md`
- `docs/superpowers/specs/2026-09-14-multiplayer-coop-design.md`
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


---

## D016 — Multiplayer is a supported long-term project direction

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Project-wide

Private co-op is an approved long-term direction for MonsterLineage.

The first multiplayer target is two players, but ownership structures must not hard-code exactly two slots. The current v0.1 milestone remains a single-player vertical slice.

**Reason:** Multiplayer should influence architectural boundaries now without expanding v0.1 into a networking milestone.

---

## D017 — Multiplayer uses a host-authoritative model

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer architecture

The host is authoritative for world simulation, time, combat outcomes, AI, genetics, important RNG/events, ownership, lineage transitions, and saves.

Clients send input and requests rather than authoritative gameplay results. Client prediction and interpolation may improve responsiveness, but host state remains final.

**Reason:** A single authority simplifies synchronization, validation, recovery, and internet play.

---

## D018 — Player ownership is external to creature state

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Architecture

`CreatureState` represents a creature, not a player.

Player/network ownership is stored externally through systems such as `PlayerSlot` and player registries. Creature simulation data must remain valid under human control, AI control, or no active controller.

**Reason:** The same creature may move between player control and AI over its life, and Task 4 must not embed single-player-only assumptions.

---

## D019 — Player lineages are separate from biological family history

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer / lineage

Each player has a separate `PlayerLineage`. Biological ancestry is tracked independently through world family relationships.

Player lineages may share ancestors or descendants without merging ownership. A creature may have at most one active player controller.

**Reason:** Shared offspring and family branches must remain biologically coherent without ambiguous multiplayer ownership.

---

## D020 — The world uses one authoritative global clock

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Simulation architecture

All active zones share one `WorldClock`.

No client or zone may advance authoritative simulation beyond the host's assigned global tick. Slowdown and full pause are global session-level time controls. Any connected player may request either; the host applies and replicates the authoritative result.

**Reason:** Separate time progression per player or zone would create irreconcilable world timelines.

---

## D021 — Disconnect supports protected Frozen and AI modes

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer lifecycle

A leaving player may choose AI control or protected Frozen state.

Protected Frozen removes the creature from active simulation and prevents the host from later overriding that choice to AI. On reconnect, the creature returns at its disconnect location unless that position is invalid or objectively lethally unsafe, in which case a nearby safe fallback is used.

**Reason:** Players need control over what happens to their creature while offline in a persistent shared world.

---

## D022 — Shared saves are host-authoritative but replicated for recovery

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Persistence / multiplayer

The current host owns the authoritative save during a live session.

Confirmed save revisions are replicated to connected players as non-authoritative backups. After host failure, the live session stops; a player with the newest valid backup may later host the recovered world.

Seamless live host migration is not required initially.

**Reason:** This protects shared progress against crashes, power outages, and connection loss without introducing split-brain simulation.

---

## D023 — Saves use snapshots, deltas, revisions, and atomic writes

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Persistence

The future save system should use periodic full snapshots plus incremental deltas and compaction.

Regular checkpoints target roughly a 10-second crash-loss window, with immediate checkpoints for critical events. Writes preserve the previous confirmed revision until the new revision is complete and validated.

Saves carry stable identity, revision, branch information, format version, and checksum data.

**Reason:** Frequent recovery checkpoints must not cause large gameplay stalls, unbounded save growth, or corruption during sudden power loss.

---

## D024 — Multi-zone co-op is a supported future capability

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer / simulation

Players should eventually be able to occupy different active zones.

The first multiplayer implementation may keep active-zone simulation on the host. Zone and player architecture must not require all players to share one `current_zone_id`.

**Reason:** Independent exploration is a desired co-op capability and should not require rewriting player ownership later.

---

## D025 — Delegated zone simulation is optional and non-authoritative

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Future performance architecture

If profiling later shows that multiple active zones overload the host, the host may delegate bounded zone-simulation work to client machines.

Delegated clients remain workers, not authorities. The host owns the target tick, accepts or rejects results, and retains authoritative world state.

Delegated simulation is not required until profiling demonstrates a need.

**Reason:** Client machines may help distribute simulation cost without allowing different parts of the world to advance independently.

---

## D026 — Networking transport is separated from gameplay logic

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer architecture

Gameplay and simulation depend on a `NetworkSession` abstraction rather than directly on a specific transport.

LAN/direct connection is the practical first connection mode. Invite/relay support may be added later over the same gameplay networking model.

**Reason:** Transport choice should not force changes to combat, genetics, creature control, or other simulation systems.

---

## D027 — Friendly fire is a session rule

**Date:** 2026-09-14  
**Status:** Accepted  
**Scope:** Multiplayer rules

Friendly fire is disabled by default in persistent co-op and may be enabled by host session rules.

Future skirmish modes may use different PvP, team, spawn, and victory rules while reusing the same multiplayer foundation.

**Reason:** Private co-op and future competitive play need different policy without requiring separate networking cores.

---

## D028 — Creature AI uses one universal reasoning architecture

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** AI architecture

All AI-controlled creatures use the same capability-driven architecture: subjective perception and beliefs feed Utility goal selection, bounded GOAP-style planning, and persistent learning and habits.

Prey and predator behavior must be expressed through profiles, capabilities, goals, actions, and context within this universal brain. Separate `PreyBrain` and `PredatorBrain` architectures are not permitted.

**Reason:** A universal architecture supports evolved creatures, individual variation, and control changes without multiplying species- or role-specific controller classes.

---

## D029 — AI reasons from subjective knowledge

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** AI architecture

AI decisions must be based on the creature's observations, beliefs, confidence, and persistent knowledge. An AI brain must not query omniscient `WorldState` data to learn facts the creature has not perceived.

Authoritative world data may resolve actions and outcomes, but it does not become free decision-making knowledge.

**Reason:** Subjective knowledge allows believable mistakes, meaningful perception, and different behavior among creatures that occupy the same world.

---

## D030 — Persistent AI experience belongs to the creature

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** AI / creature state

Persistent knowledge, strategy learning, and habits belong to the individual creature and survive controller changes.

Current goal, plan, action, tactical target, working observations, interrupt flags, and other controller/execution state are transient and do not belong to persistent creature state.

**Reason:** A creature must retain its learned behavioral history when control changes between a player and AI without persisting disposable runtime machinery.

---

## D031 — Cognition is an evolvable capability model

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** Biology / AI architecture

Cognition is represented through evolvable capabilities and bounded parameters such as memory, planning depth, learning, and habit formation. Authored species or instinct profiles provide defaults, but species identity does not permanently hard-code cognition.

**Reason:** Descendants and individuals must be able to vary cognitively without requiring new brain classes or a fixed species intelligence label.

---

## D032 — AI work is deterministic, staggered, bounded, and event-driven

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** AI / simulation architecture

Ordinary AI thinking is distributed across deterministic stable scheduling slots. Planning has explicit search bounds, and urgent gameplay events may trigger immediate interrupts rather than waiting for the next ordinary update.

Gameplay-affecting ordering and tie-breaking must be deterministic and must not depend on dictionary iteration order or uncontrolled randomness.

**Reason:** The AI must remain reproducible, responsive to critical events, and scalable without every creature performing unbounded planning every frame.

---

## D033 — Advanced AI delivery is split into Tasks 8A and 8B

**Date:** 2026-09-15
**Status:** Accepted
**Scope:** v0.1 implementation

Task 8A delivers the universal AI foundation and headless reasoning tests. Task 8B integrates combat, live perception and action execution, web interactions, and the first living cricket and frog behaviors.

The detailed execution authority is `docs/superpowers/plans/2026-09-15-advanced-creature-ai-implementation-plan.md`.

**Reason:** Separating reasoning infrastructure from living-world integration creates a review gate before combat and scene wiring expand the implementation surface.

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
