# Advanced Creature AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the old prey/predator prototype-brain approach with a controller-neutral, subjective, deterministic creature AI foundation, then integrate it with combat, webs, a field cricket, and a cunning frog predator for the v0.1 vertical slice.

**Architecture:** One universal `AIBrain` consumes persistent creature knowledge plus transient observations, chooses a goal with utility scoring, builds a bounded GOAP plan from only believed facts, executes capability-driven actions through existing `CreatureActor` interfaces, learns from outcomes, and exposes a debug snapshot. Task 8A builds and headless-tests the reasoning foundation; Task 8B integrates real perception, navigation, combat, web events, and live creature controllers.

**Tech Stack:** Godot 4.7.2 stable Standard, GDScript 2.0, Godot `Resource` / `.tres` content, existing named deterministic RNG service, existing headless test harness. No third-party runtime dependency.

**Spec:** `docs/superpowers/specs/2026-09-15-advanced-creature-ai-design.md`

## Global Constraints

- Keep `CreatureState` controller-independent: no `is_ai`, player number, network peer ID, local input, camera, or transport ownership.
- Persistent individual knowledge/learning may live on `CreatureState`; current goal/plan/action/target/route remain transient `AIBrain` state.
- AI reasons from observations and beliefs, never omniscient hidden world state.
- A planner may not use an unknown location, entity fact, hazard, or route.
- Shared definitions remain immutable data; individual mutable state remains separate.
- Cognition is a capability system with authored defaults, not a permanent species lock.
- Runtime behavior is capability-driven, not `if species == ...` branching.
- `CreatureActor.set_move_direction()` remains the movement-control boundary for AI and human controllers.
- All meaningful stochastic AI choices use the existing deterministic RNG service or deterministic stable tie-breaking; no uncontrolled `randf()` / global randomness.
- GOAP planning is bounded and event-driven; do not replan every frame.
- AI scheduling is staggered; ordinary thinking is distributed across simulation updates, while critical interrupts may wake a brain immediately.
- v0.1 implements `INSTINCTIVE` and `CUNNING` behavior. `SAPIENT` and `ADVANCED` remain architectural extension points only.
- Keep the current seven valid test suites in `tests/run_all.gd`; add new suites without removing any existing suite.
- Every task must run its focused test plus the central runner before commit.
- On Windows PowerShell, pipe Godot commands through `| Out-Host` before checking `$LASTEXITCODE`.
- Scan validation output for `SCRIPT ERROR`, `Parse Error`, failed resource loads, and runtime errors; do not rely on exit code alone.
- Do not implement networking, PlayerSlot, replicated saves, delegated zone workers, save/load, sapient diplomacy, language, tools, politics, colony strategy, neural networks, or reinforcement learning in these tasks.

---

# Phase 8A — AI Foundation

### Task 8A.1: Cognition, instincts, and persistent individual AI state

**Files:**
- Create: `src/data/brain_profile.gd`
- Create: `src/data/instinct_profile.gd`
- Create: `src/creatures/knowledge_state.gd`
- Create: `src/creatures/strategy_memory.gd`
- Create: `src/creatures/habit_state.gd`
- Modify: `src/creatures/creature_state.gd`
- Modify: `src/data/species_def.gd`
- Create: `content/ai/brain_profiles/instinctive.tres`
- Create: `content/ai/brain_profiles/cunning.tres`
- Create: `content/ai/instinct_profiles/field_cricket.tres`
- Create: `content/ai/instinct_profiles/frog_predator.tres`
- Create: `content/ai/instinct_profiles/arachnid.tres`
- Modify: `content/species/field_cricket.tres`
- Modify: `content/species/frog_predator.tres`
- Modify: `content/species/player_spider.tres`
- Create: `tests/test_ai_foundation.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `BrainProfile` Resource with fields `id: StringName`, `band: StringName`, `planning_depth: int`, `planning_expansion_budget: int`, `memory_depth: float`, `learning_rate: float`, `attention: float`, `supports_entity_recognition: bool`, `supports_strategy_learning: bool`, `supports_habits: bool`.
- Produces: `InstinctProfile` Resource with `id: StringName`, `goal_biases: Dictionary[StringName, float]`, `action_biases: Dictionary[StringName, float]`.
- Produces: `KnowledgeState` persistent controller-neutral knowledge container.
- Produces: `StrategyMemory.record_outcome(strategy_id: StringName, context_id: StringName, success: float, cost: float, learning_rate: float) -> void`.
- Produces: `StrategyMemory.cost_modifier(strategy_id: StringName, context_id: StringName) -> float`.
- Produces: `HabitState.record_success(habit_id: StringName, weight: float) -> void` and `HabitState.strength(habit_id: StringName) -> float`.
- `SpeciesDef` consumes shared default `BrainProfile` and `InstinctProfile`; individual creatures store a resolved `brain_profile_id` so future offspring/evolution can diverge from the species default.

- [ ] **Step 1: Write the failing profile and individual-state tests**

Add `tests/test_ai_foundation.gd` and register it after `test_web_system.gd` in `tests/run_all.gd` without removing existing suites. Start with tests equivalent to:

```gdscript
extends "res://tests/test_case.gd"

const BrainProfileData = preload("res://src/data/brain_profile.gd")
const InstinctProfileData = preload("res://src/data/instinct_profile.gd")
const CreatureStateData = preload("res://src/creatures/creature_state.gd")

func run() -> void:
    _test_brain_profile_capabilities_are_data()
    _test_creature_has_persistent_ai_learning_state()

func _test_brain_profile_capabilities_are_data() -> void:
    var profile := BrainProfileData.new()
    profile.id = &"test_cunning"
    profile.band = &"cunning"
    profile.planning_depth = 4
    profile.supports_strategy_learning = true
    assert_eq(profile.band, &"cunning", "brain band should be authored data")
    assert_eq(profile.planning_depth, 4, "planning depth should be authored data")
    assert_true(profile.supports_strategy_learning, "learning capability should be explicit")

func _test_creature_has_persistent_ai_learning_state() -> void:
    var creature := CreatureStateData.new()
    creature.brain_profile_id = &"cunning"
    creature.strategy_memory.record_outcome(&"direct_chase", &"field_cricket", 0.0, 1.0, 1.0)
    creature.habits.record_success(&"ambush_field_cricket", 1.0)
    assert_eq(creature.brain_profile_id, &"cunning", "individual cognition should not be locked to species lookup")
    assert_true(creature.strategy_memory.cost_modifier(&"direct_chase", &"field_cricket") > 1.0, "failure should raise learned cost")
    assert_true(creature.habits.strength(&"ambush_field_cricket") > 0.0, "successful repeated behavior should be persistable")
```

- [ ] **Step 2: Run the focused suite and verify RED**

Run in PowerShell:

```powershell
cd "C:\Users\Bogdan\Documents\MonsterLineage"
godot --headless --path . --script res://tests/run_all.gd | Out-Host
if ($LASTEXITCODE -eq 0) { throw "Expected RED before AI foundation exists" }
```

Expected: parse/load failure for the new AI profile/state classes or assertions failing because fields are missing.

- [ ] **Step 3: Implement the shared profile Resources**

`src/data/brain_profile.gd` must be a small read-only definition type:

```gdscript
class_name BrainProfile
extends Resource

@export var id: StringName
@export var band: StringName = &"instinctive"
@export_range(1, 8, 1) var planning_depth: int = 1
@export_range(8, 512, 1) var planning_expansion_budget: int = 32
@export_range(0.0, 1.0, 0.01) var memory_depth: float = 0.25
@export_range(0.0, 1.0, 0.01) var learning_rate: float = 0.10
@export_range(0.0, 1.0, 0.01) var attention: float = 0.50
@export var supports_entity_recognition := false
@export var supports_strategy_learning := false
@export var supports_habits := false
```

`src/data/instinct_profile.gd`:

```gdscript
class_name InstinctProfile
extends Resource

@export var id: StringName
@export var goal_biases: Dictionary[StringName, float] = {}
@export var action_biases: Dictionary[StringName, float] = {}

func goal_bias(goal_id: StringName) -> float:
    return maxf(float(goal_biases.get(goal_id, 1.0)), 0.0)

func action_bias(action_id: StringName) -> float:
    return maxf(float(action_biases.get(action_id, 1.0)), 0.0)
```

- [ ] **Step 4: Implement compact persistent strategy and habit learning**

`StrategyMemory` stores aggregate values by stable `strategy_id/context_id`, not event-by-event logs. Use a bounded normalized exponential update so one result influences but does not permanently dominate future choices. `cost_modifier()` must return `1.0` when no experience exists, >1 after bad outcomes, and <1 after repeated good outcomes, clamped to a safe range such as `0.5..2.0`.

`HabitState` stores a normalized strength per habit ID and uses the same style as `PersonalityState.record_behavior`: repeated successes asymptotically approach 1.0; unknown habit strength is 0.0.

- [ ] **Step 5: Add controller-neutral fields to `CreatureState` and shared defaults to `SpeciesDef`**

`CreatureState` adds only persistent individual fields:

```gdscript
var brain_profile_id: StringName = &"instinctive"
var knowledge: KnowledgeStateData = KnowledgeStateData.new()
var strategy_memory: StrategyMemoryData = StrategyMemoryData.new()
var habits: HabitStateData = HabitStateData.new()
```

Do not add current target, plan, action, AI flag, player ownership, or scene references.

`SpeciesDef` gains exported default `brain_profile` and `instinct_profile` Resources. Keep `cognition_band` only if required for compatibility while migrating content; if kept, mark it compatibility-only and ensure runtime AI resolves capabilities from `BrainProfile`, not from species-name branches. Update all three prototype species resources to point at profiles. `field_cricket` uses `instinctive`; `frog_predator` uses `cunning`; `player_spider` is configured to be AI-compatible with `cunning` capabilities without enabling AI control for the local player.

- [ ] **Step 6: Run focused and central tests GREEN**

```powershell
godot --headless --path . --script res://tests/run_all.gd | Out-Host
if ($LASTEXITCODE -ne 0) { throw "AI profile/state tests failed" }
```

Expected: `PASS: 8 suite(s)`.

- [ ] **Step 7: Commit**

```powershell
git add src/data src/creatures content/ai content/species tests
git commit -m "feat: add cognition profiles and persistent AI learning state"
```

---

### Task 8A.2: Observations, beliefs, confidence decay, and subjective knowledge

**Files:**
- Create: `src/gameplay/ai/perception/observation.gd`
- Create: `src/gameplay/ai/knowledge/belief_state.gd`
- Replace/expand: `src/creatures/knowledge_state.gd`
- Modify: `tests/test_ai_foundation.gd`

**Interfaces:**
- Produces: `Observation` with `channel`, `subject_id`, `position`, `confidence`, `tags`, `simulation_tick`.
- Produces: `KnowledgeState.ingest(observation: Observation) -> void`.
- Produces: `KnowledgeState.remember_spatial(key: StringName, position: Vector2, confidence: float, tick: int, tags: Dictionary = {}) -> void`.
- Produces: `KnowledgeState.decay_to_tick(current_tick: int, confidence_half_life_ticks: int) -> void`.
- Produces: `KnowledgeState.get_entity_belief(subject_id: StringName) -> BeliefState`.
- Produces: `KnowledgeState.get_spatial_belief(key: StringName) -> BeliefState`.

- [ ] **Step 1: Add RED tests for unknown facts, refresh, and decay**

Add tests asserting:

```gdscript
var knowledge := KnowledgeStateData.new()
assert_true(knowledge.get_spatial_belief(&"safe_gap_1") == null, "unknown locations must stay unknown")

var obs := ObservationData.new()
obs.channel = &"vision"
obs.subject_id = &"frog_1"
obs.position = Vector2(80, 40)
obs.confidence = 0.8
obs.simulation_tick = 100
knowledge.ingest(obs)
assert_true(knowledge.get_entity_belief(&"frog_1") != null, "perceived entity should become known")
assert_eq(knowledge.get_entity_belief(&"frog_1").last_known_position, Vector2(80, 40), "belief should preserve observed position")

var before := knowledge.get_entity_belief(&"frog_1").confidence
knowledge.decay_to_tick(200, 100)
var after := knowledge.get_entity_belief(&"frog_1").confidence
assert_true(after < before and after > 0.0, "unrefreshed belief confidence should decay without vanishing instantly")
```

Also test that a later high-confidence observation refreshes position/tick/confidence instead of creating a duplicate belief.

- [ ] **Step 2: Run RED**

Run the central runner and verify failure specifically comes from missing observation/belief behavior.

- [ ] **Step 3: Implement `Observation` and `BeliefState` as focused data classes**

`Observation` is transient. `BeliefState` stores the subjective summary:

```gdscript
class_name BeliefState
extends RefCounted

var key: StringName
var subject_id: StringName
var last_known_position := Vector2.ZERO
var last_observed_tick: int = 0
var confidence: float = 0.0
var tags: Dictionary = {}
```

Never store exact hidden target condition/genome/status fields here unless a future perception mechanic explicitly exposes an estimate.

- [ ] **Step 4: Implement knowledge ingestion and decay**

Use dictionaries keyed by stable semantic IDs. Decay must be deterministic and based on elapsed simulation ticks, not wall-clock time. Use an exponential half-life or equivalent monotonic formula. Remove beliefs only after confidence drops below a small threshold such as `0.01`; tests must not depend on dictionary iteration order.

- [ ] **Step 5: Run GREEN and commit**

Expected central result: `PASS: 8 suite(s)`.

```powershell
git add src/gameplay/ai src/creatures/knowledge_state.gd tests/test_ai_foundation.gd
git commit -m "feat: add subjective AI observations and beliefs"
```

---

### Task 8A.3: Utility goals with commitment and non-thrashing selection

**Files:**
- Create: `src/gameplay/ai/utility/goal_def.gd`
- Create: `src/gameplay/ai/utility/utility_goal_selector.gd`
- Create: `content/ai/goals/survive.tres`
- Create: `content/ai/goals/obtain_food.tres`
- Create: `content/ai/goals/rest.tres`
- Create: `content/ai/goals/investigate.tres`
- Modify: `tests/test_ai_foundation.gd`

**Interfaces:**
- `GoalDef`: `id`, `base_weight`, `commitment_margin`, `required_capabilities`.
- Produces: `UtilityGoalSelector.score_goal(goal: GoalDef, context: Dictionary, instinct_profile: InstinctProfile) -> float`.
- Produces: `UtilityGoalSelector.choose_goal(goals: Array[GoalDef], context: Dictionary, instinct_profile: InstinctProfile, current_goal: StringName, current_score: float) -> Dictionary` returning `{goal_id, score, changed}`.

- [ ] **Step 1: Add RED tests for hunger, severe threat, and commitment**

Use deterministic numeric context values, not scene nodes:

```gdscript
var context := {
    &"hunger": 0.90,
    &"energy_low": 0.10,
    &"perceived_threat": 0.00,
    &"known_food_confidence": 0.80,
}
assert_eq(selector.choose_goal(goals, context, instincts, &"", 0.0).goal_id, &"obtain_food", "hungry safe creature should seek food")

context[&"perceived_threat"] = 0.95
assert_eq(selector.choose_goal(goals, context, instincts, &"obtain_food", 0.70).goal_id, &"survive", "severe threat should interrupt feeding goal")

context[&"perceived_threat"] = 0.52
var near_tie := selector.choose_goal(goals, context, instincts, &"obtain_food", 0.70)
assert_eq(near_tie.goal_id, &"obtain_food", "small score differences must not cause goal thrashing")
```

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Implement explicit v0.1 scorers**

Do not build a general expression language. Keep YAGNI scorers for `survive`, `obtain_food`, `rest`, and `investigate`, each normalized to `0..1`, then multiply by authored `base_weight` and instinct bias. The design must allow adding scorers later without adding species branches.

- [ ] **Step 4: Implement commitment margin**

If current goal remains valid, switch only when the new score exceeds the current score by the current/new goal's configured margin, except when a goal reaches a critical interrupt threshold such as `survive >= 0.90`.

- [ ] **Step 5: Run GREEN and commit**

```powershell
git add src/gameplay/ai/utility content/ai/goals tests/test_ai_foundation.gd
git commit -m "feat: add utility goal selection with commitment"
```

---

### Task 8A.4: Bounded GOAP planning from believed facts only

**Files:**
- Create: `src/gameplay/ai/planning/ai_action_def.gd`
- Create: `src/gameplay/ai/planning/ai_plan.gd`
- Create: `src/gameplay/ai/planning/goap_planner.gd`
- Modify: `tests/test_ai_foundation.gd`

**Interfaces:**
- `AIActionDef`: `id`, `preconditions: Dictionary[StringName, Variant]`, `effects: Dictionary[StringName, Variant]`, `base_cost: float`, `required_capabilities: Array[StringName]`, `strategy_id: StringName`.
- Produces: `GoapPlanner.plan(initial_facts: Dictionary, desired_facts: Dictionary, actions: Array[AIActionDef], available_capabilities: Array[StringName], dynamic_costs: Dictionary[StringName, float], max_depth: int, max_expansions: int) -> AIPlan`.
- `AIPlan` contains ordered `action_ids`, `total_cost`, `expanded_states`, and `is_valid()`.

- [ ] **Step 1: Add RED tests for known/unknown gaps and capability filtering**

Create action definitions in the test:

```gdscript
move_to_gap: requires gap_known=true, effects at_gap=true
enter_gap: requires at_gap=true + capability small_gap, effects safe_from_large_predator=true
run_open: effects escaped=true, higher dynamic threat cost
```

Assert:
- with `gap_known=true` and `small_gap`, the cunning plan uses the gap;
- with no `gap_known` fact, the planner cannot invent the gap route;
- without `small_gap` capability, `enter_gap` is excluded;
- `expanded_states <= max_expansions`;
- same inputs produce the same ordered action IDs.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Implement deterministic bounded search**

Use a small Dijkstra/A*-style search over fact dictionaries. Canonicalize fact-state keys deterministically. Sort candidate actions by stable `StringName` when costs tie. Stop when desired facts are satisfied, `max_depth` is exceeded, or `max_expansions` is exhausted. Do not inspect `WorldState` or scene nodes inside the planner.

- [ ] **Step 4: Apply dynamic strategy/action costs**

Effective action cost:

```text
max(0.001, base_cost * authored_action_bias * learned_strategy_modifier + contextual_dynamic_cost)
```

The planner consumes already-computed modifiers; it must not reach into personality, knowledge, or combat services directly.

- [ ] **Step 5: Run GREEN and commit**

```powershell
git add src/gameplay/ai/planning tests/test_ai_foundation.gd
git commit -m "feat: add bounded subjective GOAP planner"
```

---

### Task 8A.5: Universal brain orchestration, learning, habits, scheduler, and debug snapshot

**Files:**
- Create: `src/gameplay/ai/ai_brain.gd`
- Create: `src/gameplay/ai/ai_scheduler.gd`
- Create: `src/gameplay/ai/learning/learning_system.gd`
- Create: `src/gameplay/ai/debug/ai_debug_snapshot.gd`
- Modify: `tests/test_ai_foundation.gd`

**Interfaces:**
- Produces: `AIBrain.bind(creature: CreatureState, brain_profile: BrainProfile, instinct_profile: InstinctProfile) -> void`.
- Produces: `AIBrain.ingest_observation(observation: Observation) -> void`.
- Produces: `AIBrain.think(context: Dictionary, available_actions: Array[AIActionDef], available_capabilities: Array[StringName], current_tick: int) -> void`.
- Produces: `AIBrain.interrupt(reason: StringName) -> void`.
- Produces: `AIBrain.record_action_outcome(strategy_id: StringName, context_id: StringName, success: float, cost: float) -> void`.
- Produces: `AIBrain.debug_snapshot() -> AIDebugSnapshot`.
- Produces: `AIScheduler.register_brain(creature_id: StringName, brain: AIBrain) -> void`, `unregister_brain(...)`, `advance(sim_delta: float, current_tick: int) -> Array[StringName]` returning IDs due for ordinary think updates.

- [ ] **Step 1: Add RED scenario tests**

Test the complete headless reasoning loop:
- hungry + safe -> `obtain_food`;
- severe threat observation -> interrupts food goal and changes to `survive`;
- repeated failed `direct_chase` raises learned modifier;
- repeated successful `ambush` raises habit strength only when profile supports habits;
- debug snapshot reports current goal, score, ordered plan, and relevant belief IDs;
- scheduler distributes three brains across different ordinary update slots rather than returning all every advance;
- `interrupt()` marks a brain due immediately even if its ordinary slot is later.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Implement `LearningSystem` as the only bridge from outcomes to persistent aggregates**

It delegates to `StrategyMemory` and `HabitState`, multiplying update weight by `BrainProfile.learning_rate`. It must not rewrite genome/species definitions.

- [ ] **Step 4: Implement `AIBrain` orchestration**

`AIBrain` owns transient observations, current goal/score, current plan, current action ID, tactical target ID, and interrupt flags. It may read `CreatureState.needs/personality/knowledge/strategy_memory/habits` but must not mutate controller ownership or directly move scene nodes.

- [ ] **Step 5: Implement deterministic staggered `AIScheduler`**

Assign each registered creature a stable slot derived from stable creature ID hashing modulo a small slot count. Ordinary think updates fire only for that slot. Critical interrupts maintain a due-now set. Scheduler behavior must be independent of dictionary iteration order.

- [ ] **Step 6: Implement debug snapshot**

`AIDebugSnapshot` should expose at least:

```gdscript
var creature_id: StringName
var cognition_band: StringName
var current_goal: StringName
var current_goal_score: float
var alternative_goal_scores: Dictionary[StringName, float]
var current_plan: Array[StringName]
var current_action: StringName
var relevant_beliefs: Array[StringName]
var last_plan_failure: StringName
```

This is diagnostic data only; gameplay logic must not depend on it.

- [ ] **Step 7: Run GREEN and commit**

```powershell
git add src/gameplay/ai tests/test_ai_foundation.gd
git commit -m "feat: add universal AI brain scheduler and introspection"
```

---

### Task 8A.6: Subjective tactical navigation and route failure recovery

**Files:**
- Create: `src/gameplay/ai/navigation/tactical_navigator.gd`
- Create: `src/gameplay/ai/navigation/route_state.gd`
- Modify: `tests/test_ai_foundation.gd`

**Interfaces:**
- Produces: `TacticalNavigator.find_route(zone: ZoneState, start: Vector2i, goal: Vector2i, can_enter: Callable, hazard_costs: Dictionary[Vector2i, float], risk_tolerance: float) -> Array[Vector2i]`.
- Produces: `TacticalNavigator.next_direction(route: Array[Vector2i], world_position: Vector2, cell_size: Vector2) -> Vector2`.
- `RouteState` tracks `route`, `destination`, `reason`, `target_id`, `last_progress_position`, `no_progress_seconds`, `failure_count`.

- [ ] **Step 1: Add RED navigation tests**

Build a small deterministic `ZoneState` grid in the test. Assert:
- navigator never routes through a cell rejected by `can_enter`;
- a known hazard-cost cell is avoided when a slightly longer safe route exists;
- with no hazard knowledge, the same cell has no supernatural penalty;
- changing `risk_tolerance` can select a shorter risky route under urgent escape context;
- repeated no-progress detection produces a route-invalid result after a fixed threshold.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Implement bounded grid routing**

Use deterministic 4- or 8-neighbor search matching existing top-down movement. Base cost + subjective hazard cost must be non-negative. Do not add a new global navigation framework or species-specific routing classes.

- [ ] **Step 4: Implement progress/stuck detection**

`RouteState` considers movement progress successful when world position changes by a minimum distance over a window. First failure allows local reroute; repeated failure invalidates the current plan so `AIBrain` can replan or fall back. Route failure reason must be visible in debug snapshot.

- [ ] **Step 5: Run full Task 8A verification**

```powershell
cd "C:\Users\Bogdan\Documents\MonsterLineage"
godot --headless --path . --script res://tests/run_all.gd | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Task 8A full suite failed" }

godot --headless --editor --path . --quit | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Task 8A editor validation failed" }

godot --headless --path . --quit-after 2 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Task 8A smoke boot failed" }

git diff --check
```

Expected central runner: `PASS: 8 suite(s)` and no parser/runtime/resource-load errors.

- [ ] **Step 6: Commit**

```powershell
git add src/gameplay/ai/navigation tests/test_ai_foundation.gd
git commit -m "feat: add subjective tactical AI navigation"
```

**Task 8A review gate:** Stop here. Review AI foundation behavior and test output before starting combat/world integration.

---

# Phase 8B — Combat and Living AI Integration

### Task 8B.1: Combat service, bite, venom, and injury consequences

**Files:**
- Create: `src/gameplay/combat/combat_service.gd`
- Create: `src/gameplay/combat/venom_status.gd`
- Create: `tests/test_combat_and_ai.gd`
- Modify: `tests/run_all.gd`
- Modify only if required: `src/creatures/creature_actor.gd`

**Interfaces:**
- Produces: `CombatService.can_bite(attacker: CreatureState, attacker_position: Vector2, target: CreatureState, target_position: Vector2) -> bool`.
- Produces: `CombatService.bite(attacker: CreatureState, target: CreatureState, rng: RandomNumberGenerator) -> Dictionary` with semantic result fields such as `hit`, `condition_damage`, `injury_part`, `injury_severity`, `venom_status`.
- Produces: `VenomStatus.tick(target: CreatureState, delta: float) -> void`.
- Combat remains authoritative service logic; AI requests attacks but does not directly assign outcomes.

- [ ] **Step 1: Add and register `tests/test_combat_and_ai.gd` with RED combat tests**

Test:
- higher `venom_potency` creates stronger venom effect;
- venom impairs before lethal damage rather than ordinary one-bite frog kills;
- leg injury lowers existing `CreatureActor.movement_speed()` modifier;
- lethal core/condition damage marks creature dead through existing condition/death path;
- same seeded combat RNG produces reproducible semantic result.

- [ ] **Step 2: Run RED**

Expected suite count after registration is 9; initial run fails because combat classes are missing.

- [ ] **Step 3: Implement minimum combat and venom model**

Use existing genome traits (`venom_potency`, `venom_capacity`, `chitin`, `body_size`) when present. Missing optional traits resolve safely to neutral/zero values. Keep anatomy lightweight and use existing `InjuryState` semantic parts; do not build Dwarf-Fortress-level anatomy.

- [ ] **Step 4: Run GREEN and commit**

Expected central result: `PASS: 9 suite(s)`.

```powershell
git add src/gameplay/combat src/creatures/creature_actor.gd tests
git commit -m "feat: add bite venom and combat consequences"
```

---

### Task 8B.2: Live perception adapter and capability-driven AI action execution

**Files:**
- Create: `src/gameplay/ai/perception/perception_system.gd`
- Create: `src/gameplay/ai/action_executor.gd`
- Create: `src/gameplay/ai/ai_controller.gd`
- Modify: `tests/test_combat_and_ai.gd`

**Interfaces:**
- Produces: `PerceptionSystem.observe(observer_state: CreatureState, observer_position: Vector2, targets: Dictionary, zone: ZoneState, current_tick: int) -> Array[Observation]`.
- Produces: `PerceptionSystem.observe_vibration(owner_state: CreatureState, world_position: Vector2, source_id: StringName, current_tick: int) -> Observation`.
- Produces: `AIActionExecutor.begin(action_id: StringName, context: Dictionary) -> void`, `advance(delta: float) -> Dictionary`, `cancel(reason: StringName) -> void`.
- Produces: `AIController.bind(brain: AIBrain, actor: CreatureActor, state: CreatureState, zone: ZoneState) -> void`.

- [ ] **Step 1: Add RED tests for visibility boundaries and executor capability checks**

Use explicit target positions and zone cells. Assert:
- targets outside sensory range produce no vision observation;
- targets inside range produce an observation with estimated—not hidden exact—tags;
- vibration creates an observation only through the vibration event path;
- `AIActionExecutor` refuses an action whose required capability is absent;
- AI movement is supplied through `CreatureActor.set_move_direction()` rather than directly assigning actor position.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Implement first-slice perception channels**

Implement vision, web vibration, and touch/contact only. Vision confidence is stable and deterministic based on distance/sensory range and simple concealment/terrain factors available in the current zone model. Do not add per-frame random detection flicker. Leave hearing/smell extension points without implementing them.

- [ ] **Step 4: Implement capability-driven action execution**

First supported action IDs should be enough for the 8B actors: `move_to`, `flee`, `seek_cover`, `investigate`, `wait`, `struggle`, `chase`, `bite`, `consume`. The executor calls existing actor/combat/web boundaries; it does not encode species names.

- [ ] **Step 5: Implement controller bridge**

`AIController` is scene/runtime glue. It owns no persistent learning state. It sets `actor.local_input_enabled = false`, feeds observations to the brain on scheduled updates, advances the current action, and handles critical interrupts. The controlled creature's `CreatureState` remains valid when the controller is removed.

- [ ] **Step 6: Run GREEN and commit**

```powershell
git add src/gameplay/ai tests/test_combat_and_ai.gd
git commit -m "feat: connect creature perception and AI action execution"
```

---

### Task 8B.3: Field-cricket instinctive behavior and web integration

**Files:**
- Create: `content/ai/actions/field_cricket_actions.tres` or equivalent small action-def resources if actions are stored individually
- Modify: `src/gameplay/web/web_system.gd` only if an explicit semantic AI event hook is needed
- Modify: `tests/test_combat_and_ai.gd`
- Modify later in this task: `src/game/main.gd`

**Interfaces:**
- Cricket goals: forage when safe; survive/flee when danger is perceived; seek known cover; struggle when restrained.
- Web trigger must produce a perception/interrupt path for the trapped intruder and keep the existing owner vibration-memory behavior intact.

- [ ] **Step 1: Add RED scenario tests for cricket**

Tests should create a cricket state/brain with instinctive profile and assert:
- safe + hungry -> `obtain_food`;
- nearby believed predator -> `survive`;
- known cover can be selected; unknown cover cannot;
- restrained context selects `struggle` over forage;
- after surviving a web encounter, the web area becomes a hazard belief with nonzero confidence;
- no separate `PreyBrain` class is required.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Define cricket action/goal availability from capabilities and instinct profile**

Do not branch on species inside `AIBrain` or planner. Species content selects the instinct profile; body/genome capabilities and current context filter available actions.

- [ ] **Step 4: Replace temporary deterministic drift in `main.gd` with AI-controlled cricket**

Remove `_cricket_anchor`, `_cricket_drift`, `_web_test_direction_is_traversable`, and the manual debug movement loop after the new controller works. Keep Task 7 manual web testability: cricket should still be able to encounter webs, become restrained, struggle, and trigger owner vibration feedback.

- [ ] **Step 5: Run GREEN and commit**

```powershell
git add src/game/main.gd src/gameplay/web content/ai tests/test_combat_and_ai.gd
git commit -m "feat: replace debug cricket drift with instinctive AI"
```

---

### Task 8B.4: Cunning frog predator with short planning, hazard memory, and chase abandonment

**Files:**
- Create/modify: `content/ai/instinct_profiles/frog_predator.tres`
- Create action-def content for frog-capable actions if not already generic
- Modify: `tests/test_combat_and_ai.gd`
- Modify: `src/game/main.gd`

**Interfaces:**
- Frog behavior: wander/investigate when no prey is known; pursue perceived small prey; bite when in range; abandon or replan a chase when route/body constraints make the target inaccessible; remember repeated bad routes/hazards; short `CUNNING` plans only.

- [ ] **Step 1: Add RED frog scenario tests**

Assert:
- perceived edible smaller target -> hunt/chase plan;
- target entering a known inaccessible small gap invalidates direct chase;
- planner chooses wait/reposition/search-other-route/abandon according to available actions rather than repeatedly trying the impossible cell;
- repeated failed chase into the same route increases learned strategy cost;
- a safe alternative route can be chosen from subjective hazard-cost navigation;
- frog never uses `small_gap` action when body capability is absent.

- [ ] **Step 2: Run RED**

- [ ] **Step 3: Add frog actor/controller to the manual prototype scene composition**

Create a frog `CreatureState` from `frog_predator.tres`, bind it to the same `CreatureActor` scene/controller adapter pattern, and attach the universal AI controller. Do not create `PredatorBrain`.

- [ ] **Step 4: Wire combat interrupts and learning outcomes**

Damage taken, lost target, inaccessible route, successful bite, failed chase, and target death produce semantic outcomes/interrupts. Learning updates persistent `StrategyMemory`; significant near-death or successful survival events may also go to existing `MemoryLog` with bounded importance.

- [ ] **Step 5: Run GREEN and commit**

```powershell
git add content/ai src/game/main.gd tests/test_combat_and_ai.gd
git commit -m "feat: add cunning frog predator AI"
```

---

### Task 8B.5: Final deterministic integration, introspection, and acceptance

**Files:**
- Modify: `tests/test_ai_foundation.gd`
- Modify: `tests/test_combat_and_ai.gd`
- Modify as needed: `src/game/main.gd`
- Modify after merge: `CURRENT_STATE.md`
- Modify if the durable AI decisions are not already recorded: `DECISIONS.md`

**Interfaces / acceptance:**
- Same seed + same initial observations/context yields the same goal and ordered plan in headless tests.
- Cricket and frog run through the universal AI architecture.
- Player spider remains under local human input but is AI-compatible for future former-player NPC use.
- No `PreyBrain` / `PredatorBrain` implementation exists.
- Web placement/restraint/vibration behavior from Task 7 remains valid.

- [ ] **Step 1: Add deterministic replay-style AI test**

Construct two fresh equivalent brain/state instances with the same profile, observations, learned state, and deterministic RNG configuration. Assert equal chosen goal, equal ordered plan IDs, and equal first navigation decision.

- [ ] **Step 2: Run all automated gates**

```powershell
cd "C:\Users\Bogdan\Documents\MonsterLineage"

godot --headless --path . --script res://tests/run_all.gd | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Full test suite failed" }

godot --headless --editor --path . --quit | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Editor validation failed" }

godot --headless --path . --quit-after 2 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Smoke boot failed" }

git diff --check
```

Expected: `PASS: 9 suite(s)` with no script parse/runtime/resource-load failures.

- [ ] **Step 3: Manual arena verification**

Run the prototype and verify observable behavior rather than exact hidden implementation:

```text
1. Cricket moves under AI, not fixed debug drift.
2. When safe/hungry it forages or explores rather than fleeing forever.
3. Player approaching the cricket can trigger flee/cover behavior.
4. Cricket can enter a web, becomes restrained, struggles, and the player still receives the existing vibration cue.
5. After a known web encounter the cricket can avoid the remembered hazard when a reasonable alternative exists.
6. Frog detects suitable prey, pursues, and bites when able.
7. If prey enters terrain the frog cannot traverse, the frog does not run into the obstacle indefinitely; it replans or abandons.
8. AI debug snapshot for selected cricket/frog explains current goal, score, plan, relevant belief, and last failure.
9. Player spider controls normally through local input throughout the test.
10. Task 7 web lifetime/silk regeneration behavior remains intact.
```

- [ ] **Step 4: Commit integration fixes only if manual verification found a reproducible defect**

Use TDD/systematic debugging for any defect. Do not bundle unrelated polish.

- [ ] **Step 5: Update factual project state after successful merge**

`CURRENT_STATE.md` should report Tasks 8A/8B separately, the new test-suite count/result, manual acceptance status, and next planned task. `DECISIONS.md` should contain durable accepted decisions such as universal subjective Utility+GOAP AI, controller-neutral persistent knowledge/learning, cognition as evolvable capabilities, and staggered deterministic scheduling. Do not rewrite old decisions; add new entries.

- [ ] **Step 6: Final documentation commit**

```powershell
git add CURRENT_STATE.md DECISIONS.md docs/superpowers/specs docs/superpowers/plans
git commit -m "docs: record advanced creature AI architecture and task state"
```

---

## Reference projects and licensing rule

Implementation may study known AI projects and open code for architecture and algorithms. Before copying literal implementation code, verify the exact source file/repository license and compatibility with MonsterLineage. Prefer reimplementation of concepts when the reference has reciprocal/copyleft or ambiguous provenance.

Approved reference directions from design discussion:

- Cataclysm: DDA — threat evaluation, tactical memory, danger maps; treat primarily as conceptual reference unless license implications are explicitly accepted.
- Veloren — active versus reduced/coarse simulation concepts; conceptual reference for future LOD.
- OpenXRay / S.T.A.L.K.E.R. A-Life — autonomous world simulation concepts; verify provenance before literal reuse.
- MIT Godot Utility AI / GOAP examples — useful for implementation patterns after exact license verification.

No third-party AI package is added as a runtime dependency in Task 8A/8B unless the user explicitly approves that dependency after review.

## Plan self-review

- Spec coverage: subjective perception/beliefs, utility, bounded GOAP, capability-driven actions, tactical navigation, learning, habits, cognition bands, deterministic scheduler, introspection, cricket/frog first slice, and former-player compatibility are all mapped to tasks.
- Scope: sapient/advanced systems, distant coarse world simulation, networking, save/load, social diplomacy, language, tools, and reinforcement learning remain out of scope.
- Type consistency: `CreatureState` owns persistent `knowledge`, `strategy_memory`, `habits`, and `brain_profile_id`; `AIBrain` owns transient reasoning state; `AIController` is runtime glue; `CreatureActor` remains movement boundary.
- Existing test suites are preserved. Expected suite count moves from 7 to 8 after `test_ai_foundation.gd`, then to 9 after `test_combat_and_ai.gd`.
