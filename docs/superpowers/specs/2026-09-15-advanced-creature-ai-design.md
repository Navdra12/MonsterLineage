# MonsterLineage — Advanced Creature AI Design

Date: 2026-09-15
Status: Approved design specification
Scope: Project-wide AI architecture; first implementation slice is v0.1 Tasks 8A and 8B

## 1. Purpose

MonsterLineage treats creature AI as a core game feature rather than a small combat helper.

The system must support three goals at the same time:

1. creatures that behave like organisms with their own needs, routines, territory, shelter, food-seeking, fear, and survival priorities;
2. creatures that can adapt tactically instead of relying on fixed `if target visible -> chase` scripts;
3. creatures that remember experience, learn from outcomes, develop habits, and remain individually recognizable over long lifetimes.

The architecture must also support the project-wide generational design: a creature previously controlled by a player may later become an autonomous NPC while preserving its own personality, memories, preferences, knowledge, and learned behavior.

This document replaces the old v0.1 assumption that Task 8 would be built around separate `PreyBrain` and `PredatorBrain` implementations plus a small action scorer.

## 2. Chosen architecture

The accepted architecture is a hybrid of:

- subjective perception and beliefs;
- utility-based goal selection;
- GOAP-style short-horizon planning;
- capability-driven actions;
- tactical navigation;
- episodic memory and persistent knowledge;
- outcome-based learning;
- habit formation;
- deterministic scheduling and bounded planning.

Conceptually:

```text
Real World
   ↓
Perception
   ↓
Observations
   ↓
Beliefs / Knowledge
   ↓
Needs + Instincts + Personality + Memory
   ↓
Utility Goal Selection
   ↓
GOAP Planner
   ↓
Action Executor
   ↓
Tactical Navigation / Combat / Interaction
   ↓
Outcome Evaluation
   ↓
Learning + Memory + Habit Updates
```

The same universal AI architecture is used for prey, predators, spiders, later former-player NPCs, and future evolved creatures. Species/body-plan identity changes data and available capabilities, not the existence of a separate hard-coded brain class.

## 3. Core architectural rule: subjective AI

AI must reason from what the creature perceives and believes, not from omniscient access to authoritative world state.

A creature may know or believe that:

- a predator was last seen at a location;
- a web hazard exists in an area;
- a food source was previously found nearby;
- a specific creature is dangerous;
- a gap is a reliable escape route;
- a route was recently blocked.

These beliefs may be uncertain, stale, incomplete, or wrong.

The planner must not use facts that the creature has never perceived, learned, or inherited through an allowed knowledge mechanism.

Examples:

```text
known safe gap + large predator
→ planner may use the gap

unknown safe gap + large predator
→ planner must not use the gap
```

AI must never receive exact hidden values such as another creature's current condition, genome, internal status effects, or precise threat score unless a future mechanic explicitly exposes that information.

## 4. Separation of individual state and AI controller state

`CreatureState` remains controller-independent simulation data.

Long-term state belonging to the individual creature may live with the creature:

```text
CreatureState
├── needs
├── injuries
├── personality
├── food_memory
├── memory
├── knowledge          # new persistent subjective knowledge
├── strategy_memory    # learned outcomes by strategy/context
└── habits             # learned reusable behavior patterns
```

Transient AI execution state does not belong in `CreatureState`:

```text
AIBrain
├── current_observations
├── current_goal
├── current_plan
├── current_action
├── tactical_target
├── route_state
└── transient_interrupt_state
```

`CreatureState` must not gain fields such as `is_ai`, `player_number`, network ownership, local input, camera, or multiplayer transport data.

The same creature remains valid under human control, AI control, temporary lack of control, or future multiplayer ownership.

## 5. Universal AI components

The target architecture is approximately:

```text
AIBrain
├── PerceptionSystem
├── BeliefState / KnowledgeState
├── DriveEvaluator
├── UtilityGoalSelector
├── GoapPlanner
├── ActionExecutor
├── TacticalNavigator
├── LearningSystem
└── DebugSnapshot
```

Supporting content/data includes:

```text
BrainProfile
InstinctProfile
GoalDef
AIAction definitions
```

The implementation should keep these responsibilities independently testable and avoid one oversized AI class.

## 6. Perception

Perception converts the real simulated world into subjective observations.

Initial supported channels for the first implementation slice:

- vision;
- vibration;
- touch/contact.

The architecture must allow later channels such as:

- hearing;
- smell;
- heat;
- tracks;
- magical or evolved senses.

An observation may contain information such as:

```text
channel = vision
subject_id = creature_42
observed_position = ...
estimated_size = medium
confidence = 0.82
simulation_tick = ...
```

Perception quality may depend on:

- sensory capability;
- genome/phenotype;
- distance;
- target movement;
- target visibility/concealment;
- environmental conditions;
- attention;
- injury or fatigue where relevant.

Detection should not randomly flicker every frame. Prefer accumulated evidence/confidence over independent per-frame random checks.

## 7. Working perception, beliefs, and episodic memory

The system distinguishes three layers.

### 7.1 Working perception

Immediate observations such as:

```text
"I see a frog now."
"A strong vibration happened on my web."
```

This is transient.

### 7.2 Knowledge / beliefs

Longer-lived subjective state such as:

```text
subject_id = frog_12
last_known_position = ...
last_observed_tick = ...
confidence = 0.61
estimated_danger = 0.84
believed_injured = 0.70
```

Spatial beliefs may include:

- known food location;
- known shelter;
- known web hazard;
- known predator area;
- known escape gap;
- known nest;
- known water or future species-specific resources.

Belief confidence decays when information is not refreshed.

### 7.3 Episodic memory

Existing `MemoryLog` remains the bounded store for significant events.

Examples:

- nearly killed by a frog;
- escaped through a specific gap;
- successful web ambush;
- poisoning from a food source;
- clutch birth;
- betrayal or protection in future social systems.

Common low-value spatial beliefs should naturally fade. Important episodic memories may persist much longer and may influence personality or learning.

## 8. Imperfect evaluation

AI should not have perfect estimates of other creatures.

Threat, injury, strength, speed, or intent may be represented as uncertain estimates with confidence rather than exact values.

A young or low-cognition creature may classify roughly:

```text
large moving creature → dangerous
```

A cunning creature may recognize:

```text
same frog as before
frog cannot enter this gap
frog is likely injured
```

Experience may improve estimate quality over time.

This uncertainty is intentional and may cause believable mistakes, including overestimating harmless threats or underestimating dangerous opponents.

## 9. Drives and utility goal selection

Utility chooses the creature's current goal, not the exact action sequence.

Representative goals include:

```text
survive
obtain_food
rest
seek_shelter
protect_offspring
defend_territory
investigate
hunt
avoid_known_hazard
socialize
mate
```

Only goals required by the current implementation slice should be authored initially.

Goal score may depend on:

- needs;
- perceived threat;
- injury;
- instinct weights;
- personality;
- confidence in relevant beliefs;
- expected reward;
- expected risk;
- relationships in future social use cases.

Example:

```text
obtain_food =
    hunger
    × known_food_value
    × belief_confidence
    × personality_modifier
    × safety_modifier
```

Utility scoring should use explicit bounded considerations/response functions rather than large hard-coded condition trees where practical.

## 10. Goal commitment and interrupts

AI must not oscillate between nearly equal goals.

The current goal receives commitment/inertia. A new goal must exceed the current goal by a meaningful margin unless:

- the current plan becomes invalid;
- a critical interrupt occurs;
- a survival emergency requires immediate switching.

Example:

```text
current obtain_food = 0.74
survive = 0.78
→ keep current goal

survive = 0.93
→ interrupt and switch to survive
```

Critical events may trigger immediate reevaluation:

- took damage;
- entered restraint;
- predator detected at close range;
- target died;
- route became invalid;
- web broke;
- food disappeared;
- major vibration or equivalent species-specific danger cue.

Minor stimuli must not constantly cancel plans.

## 11. GOAP-style planning

The planner answers: "How can I reach the selected goal from what I currently believe?"

Actions expose at least:

```text
requirements
effects
base_cost
dynamic_cost
execution interface
```

Representative actions:

```text
MoveToKnownFood
MoveToGap
EnterSmallGap
Hide
Wait
Investigate
Flee
Chase
Ambush
Struggle
Bite
Consume
Rest
```

The planner uses only actions currently available through cognition, body capabilities, environmental context, and known facts.

The first cunning implementation uses short plans, approximately 2–5 actions when appropriate.

Planning must be bounded by a search budget. If no ideal plan is found within the allowed budget, the brain chooses a safe fallback or simpler valid behavior instead of performing unbounded search.

## 12. Dynamic action cost

Action cost must depend on the current creature and context.

For example, attack cost may include:

```text
target_estimated_threat
injury_risk
distance
energy_cost
bad_past_experience
hunger_pressure
aggression
confidence
```

The same action therefore may be attractive for one individual and undesirable for another.

Repeated poor outcomes may raise the learned cost of a strategy. Repeated success may lower its learned cost within bounded limits.

## 13. Capability-driven actions

AI must not branch on species names for ordinary behavior.

Avoid:

```text
if species_id == &"player_spider":
    use_web()
```

Prefer:

```text
if current body/genome exposes web placement capability:
    web-related actions are available
```

Examples of capability-driven behavior:

- `small_gap` enables traversal/escape actions;
- `wall_crawl` enables appropriate routes;
- web organs enable web actions;
- flight later enables aerial movement/actions;
- manipulators later enable tool actions.

This allows future evolution to alter AI behavior without creating a new brain class for every morphology.

## 14. Tactical navigation

GOAP chooses the logical action sequence. `TacticalNavigator` handles local route execution.

Movement should route through the existing `CreatureActor` controller interface rather than directly mutating scene positions.

The tactical navigator evaluates subjective route cost, not only shortest geometric distance.

Conceptual cell/segment cost:

```text
terrain_cost
+ believed_hazard
+ threat_exposure
+ web_risk
+ injury_penalty
+ visibility/exposure penalty
+ crowding
```

The same path may have different cost depending on the action intent.

Example route intent:

```text
destination = gap_12
reason = escape
target = frog_3
acceptable_risk = low
```

Cunning creatures may:

- route around known hazards;
- seek cover;
- use known gaps;
- break line of sight;
- choose safer approach directions;
- revisit remembered food/shelter.

Instinctive creatures use simpler local movement and immediate obstacle/danger avoidance.

## 15. Failure handling and stuck recovery

AI must detect lack of progress.

Expected sequence:

```text
movement makes no progress
→ try a small local alternative
→ if still blocked, invalidate route
→ if repeated, lower confidence in route/belief
→ replan
→ if no plan exists, use safe fallback
```

If an action fails because the body cannot traverse a cell, the planner receives a semantic failure reason such as `inaccessible_terrain` rather than silently retrying forever.

This is necessary to avoid NPCs repeatedly walking into trees, walls, inaccessible gaps, or other blocked routes.

## 16. Learning

Learning is deterministic rule-based adaptation, not runtime neural-network or reinforcement-learning training.

The first architecture supports three learning layers.

### 16.1 World learning

Examples:

```text
"this area is dangerous"
"food is often found here"
"this gap is a reliable escape route"
```

### 16.2 Entity learning

Examples:

```text
"this frog is aggressive"
"this creature fed me"
"this individual is dangerous"
```

### 16.3 Strategy learning

Compact outcomes such as:

```text
ambush / field_cricket = high success
direct_chase / field_cricket = mediocre success
direct_attack / frog = poor outcome
```

Outcome updates should remain bounded and interpretable.

## 17. Habits

Repeated successful behavior may become a reusable habit.

Example:

```text
when hungry + cricket nearby
→ approach from cover
→ web
→ bite
```

Habits serve three purposes:

1. preserve recognizable individual behavior;
2. reduce repeated planner work for familiar situations;
3. allow a former player creature to continue using strategies that were repeatedly practiced while under player control.

Habits are preferences/templates, not unconditional scripts. They can be rejected when current conditions make them unsafe or impossible.

## 18. Instincts and individual variation

A universal `AIBrain` does not imply identical behavior across species.

Behavior emerges from:

```text
AIBrain
+ BrainProfile
+ InstinctProfile
+ body capabilities
+ genome/phenotype
+ age/injury/fatigue
+ personality
+ experience
= individual behavior
```

`InstinctProfile` provides authored starting biases such as:

```text
field_cricket:
  flee_from_large_creatures = very_high
  forage = high
  seek_cover = high
  investigate_unknown = low

frog_predator:
  pursue_small_prey = high
  ambush = medium
  territoriality = medium
  investigate_movement = high

arachnid:
  web_hunting = high
  vibration_attention = very_high
  ambush = high
  small_gap_escape = high
```

These are data-driven starting tendencies, not fixed scripts.

Experience may modify behavior within plausible bounds. Learned confidence should not magically erase hard physiological limits or completely invert strong innate survival responses without a designed mechanic.

## 19. Cognition architecture

Cognition is evolvable capability, not a permanent species label and not one raw `intelligence` number.

Relevant dimensions may include:

```text
memory_depth
planning_depth
belief_complexity
entity_recognition
prediction
attention
learning_rate
social_reasoning
```

User-facing/design bands provide coarse capability groups:

### Instinctive

- immediate perception and reactive utility;
- short working memory;
- one-step or near-one-step behavior;
- strong reliance on instincts;
- minimal strategy learning.

### Cunning

- persistent beliefs;
- entity recognition;
- short GOAP plans;
- hazard and route learning;
- strategy learning;
- simple prediction and ambush/retreat behavior.

### Sapient — future

Architecture supports but v0.1 does not implement:

- abstract goals;
- deliberate teaching;
- tools;
- cooperation;
- deception;
- language-mediated knowledge.

### Advanced — future

Architecture supports later extensions such as:

- hierarchical planning;
- long-term projects;
- culture/politics reasoning;
- advanced social strategy.

Species/body plan may establish normal ranges or developmental constraints, but genome/neural traits and evolution may allow unusual individuals or later lineages to cross cognition bands.

## 20. AI scheduling and performance

AI work runs at different frequencies.

```text
Physics/action execution
→ every relevant physics tick

Immediate reflex interrupts
→ event-driven / high frequency

Perception
→ frequent but staggerable

Utility reevaluation
→ less frequent and staggered

GOAP planning
→ only on new goal, invalid plan, or important new information

Learning/memory updates
→ event-driven
```

GOAP must not run every frame for every creature.

An `AIScheduler` distributes ordinary expensive thinking across frames/ticks so large groups do not all reevaluate simultaneously.

Critical events may wake an AI immediately.

Planning depth and search budget are bounded by cognition/profile and performance constraints.

## 21. Simulation level of detail

The architecture must remain compatible with future world simulation LOD:

```text
ACTIVE
- detailed perception
- utility
- GOAP
- tactical execution

REDUCED
- less frequent perception/replanning
- simplified execution

COARSE
- no CharacterBody2D requirement
- aggregated decisions such as forage/hunt/rest/travel/migrate/reproduce
```

Only the detailed active-zone behavior is required in Tasks 8A/8B.

The same individual `CreatureState` persists across simulation levels. Reduced/coarse simulation must not replace an NPC with an unrelated fake entity.

## 22. Determinism

Meaningful AI variation must use deterministic project RNG rather than uncontrolled global randomness.

Decision randomness, where required, should derive from stable context such as:

```text
creature_id
decision type
decision sequence or authoritative simulation tick
```

Goals:

- same seed + same observations/events → reproducible decision;
- headless tests can reproduce AI failures;
- future host-authoritative multiplayer remains feasible;
- debugging does not depend on uncontrolled random state.

Determinism does not require every creature to behave identically: personality, knowledge, memory, genome, and different event histories naturally produce different decisions.

## 23. Introspection and debugging

AI must expose an interpretable debug snapshot from the first implementation slice.

A snapshot should be able to explain fields such as:

```text
creature_id
cognition band/profile
current goal and utility score
runner-up goals
current plan/current action
relevant beliefs with confidence
perceived threat
last plan failure and reason
relevant memory/strategy modifiers
current route intent
```

Example:

```text
Creature: cricket_12
Cognition: CUNNING
Goal: ESCAPE_DANGER (0.91)
Other goals:
  OBTAIN_FOOD = 0.43
  REST = 0.11
Plan:
  MoveToGap
  EnterGap
  Hide
Threat belief:
  frog_2
  confidence = 0.74
  estimated danger = 0.88
Last plan failure:
  direct_escape
  reason = route_blocked
```

The purpose is to make wrong behavior diagnosable without guessing from animations alone.

## 24. Automated testing strategy

AI foundation must be testable headlessly without requiring full rendered gameplay.

Core Task 8A scenario tests include at least:

```text
hungry + safe
→ choose obtain_food

hungry + severe threat
→ choose survive

known safe gap + incompatible predator
→ cunning planner may use gap

unknown gap + same predator
→ planner must not use gap

belief not refreshed
→ confidence decays

repeated failed strategy
→ learned future cost increases

repeated successful strategy
→ preference/habit formation can occur

capability unavailable
→ dependent action is excluded from plan

same deterministic seed + same observations
→ same decision

near-equal utility values
→ commitment prevents rapid goal thrashing
```

Task 8B adds real scene/integration tests around movement, webs, combat, injuries, and actual creature actors.

All new suites must be added to `tests/run_all.gd` without removing existing suites.

## 25. Task 8A — AI Foundation

Task 8A builds the architecture without requiring complete combat integration.

Expected responsibilities:

```text
src/gameplay/ai/
├── ai_brain.gd
├── ai_scheduler.gd
├── perception/
│  ├── observation.gd
│  └── perception_system.gd
├── knowledge/
│  ├── belief_state.gd
│  └── knowledge_state.gd
├── utility/
│  ├── goal_def.gd
│  └── utility_selector.gd
├── planning/
│  ├── ai_action.gd
│  ├── ai_plan.gd
│  └── goap_planner.gd
├── learning/
│  ├── strategy_memory.gd
│  └── habit_state.gd
├── navigation/
│  └── tactical_navigator.gd
└── debug/
   └── ai_debug_snapshot.gd
```

Data/content responsibilities may include:

```text
src/data/
├── brain_profile.gd
└── instinct_profile.gd

content/ai/
├── brain_profiles/
└── instinct_profiles/
```

Exact file count may be reduced if implementation review shows that some types are unnecessary. Responsibility boundaries are more important than mechanically creating every suggested file.

Task 8A completion means the headless AI reasoning tests are green and the foundation can support both instinctive and cunning profiles without hard-coded prey/predator subclasses.

## 26. Task 8B — Combat and living AI integration

Task 8B connects the AI foundation to the actual creature/world simulation and implements the combat portion originally planned for old Task 8.

It includes:

- bite;
- venom;
- injury consequences relevant to combat and movement;
- threat evaluation from subjective information;
- integration with `CreatureActor` movement;
- web restraint/struggle interaction;
- route failure/replanning in the real zone;
- manual AI arena verification.

First behavioral roles:

### Field cricket — primarily Instinctive

- forage;
- flee perceived danger;
- seek simple cover;
- struggle when restrained;
- retain simple hazard knowledge where allowed by profile.

### Frog predator — Cunning

- detect prey through available senses;
- pursue prey;
- use short plans;
- abandon impossible or excessively costly chases;
- remember relevant hazards/routes;
- replan when target enters inaccessible terrain.

### Player spider — AI-compatible, not AI-controlled during normal player play

The same universal AI foundation must be able to operate a spider body through capabilities and profiles, but Task 8B does not replace local player control.

This prepares later former-player NPC behavior without implementing generational handoff early.

## 27. Integration with existing systems

### CreatureActor

AI supplies movement intent through the same controller-facing API used by other controllers. AI should not directly set world positions to bypass traversal rules.

### Web system

AI consumes semantic events such as restraint and vibration. Web knowledge remains subjective: an unseen/unknown web is not automatically treated as a hazard.

### Combat service

AI requests actions such as bite. Combat code remains authoritative for validation, damage, venom, injury, and death effects.

AI does not directly declare that an attack succeeded or that a target is dead.

### Personality

Existing learned personality tendencies may modify utility or dynamic action cost.

### MemoryLog

Existing episodic memory remains the bounded significant-event history. Knowledge and strategy learning do not replace it.

### Multiplayer architecture

AI remains controller-side logic over controller-independent creature state. Future multiplayer host authority controls authoritative AI decisions. No network ownership field is added to `CreatureState`.

## 28. External implementation references and licensing

The project may study open or publicly described AI systems for architecture and algorithms.

Useful categories/references include:

- Godot utility-AI implementations for considerations/response curves and modular scoring;
- small Godot GOAP implementations for planner/action structure;
- Cataclysm: DDA for threat evaluation, local danger reasoning, NPC state, and tactical failure handling;
- Rain World for creature-centric perception and autonomous ecology;
- S.T.A.L.K.E.R./OpenXRay A-Life concepts for active/offline simulation architecture;
- Veloren rtsim concepts for persistent actors across simulation detail levels;
- Dwarf Fortress for persistent individual memory/personality consequences.

Before copying any source code directly, verify the exact repository/file license and compatibility with MonsterLineage. If license compatibility is uncertain or undesirable, reproduce only the general algorithmic idea with an original implementation.

MIT/permissive reference implementations are preferred when direct structural adaptation is useful.

The project should not add a third-party runtime dependency merely to obtain the AI architecture unless a later explicit decision approves it.

## 29. Non-goals for Tasks 8A/8B

Do not implement in this slice:

- sapient diplomacy;
- language;
- teaching;
- tool use;
- deception systems;
- faction politics;
- colony strategy;
- hierarchical long-term civilization planning;
- reinforcement learning;
- neural-network inference/training;
- distant coarse world simulation;
- multiplayer networking;
- a save/load system.

The architecture should leave extension points for these systems without implementing them prematurely.

## 30. Durable decisions introduced by this design

The following should be recorded in `DECISIONS.md` after repository review:

1. MonsterLineage uses one universal capability-driven AI architecture rather than species-specific prey/predator brain classes.
2. AI reasons from subjective perception, beliefs, and persistent creature knowledge rather than omniscient world state.
3. Utility selects goals; GOAP-style bounded planning selects action sequences.
4. Cognition is evolvable capability, not a fixed species label or single intelligence stat.
5. Long-term knowledge/learning/habits belong to the individual creature; transient goal/plan/execution state belongs to the AI controller.
6. AI scheduling and planning are bounded, staggered, event-driven, and deterministic where gameplay-affecting.
7. Task 8 is split into Task 8A AI Foundation and Task 8B Combat/AI Integration.

## 31. Acceptance summary

The architecture is successful when MonsterLineage can eventually produce creatures that:

- act for their own survival rather than only reacting to the player;
- make different choices because they perceive and remember different things;
- use body capabilities instead of hard-coded species scripts;
- choose goals through needs/instinct/personality;
- build short context-sensitive plans;
- learn from success and failure;
- develop recognizable habits;
- make believable mistakes because their knowledge is incomplete;
- remain performant and debuggable;
- preserve their individual behavioral history when control changes from player to AI.
