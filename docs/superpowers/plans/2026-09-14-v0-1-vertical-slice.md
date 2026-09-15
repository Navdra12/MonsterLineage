# Monster Lineage Sandbox 0.1 Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Godot 0.1 vertical slice in which a weak spider survives, hunts with webs and venom, claims a nest, reproduces, produces genetically distinct daughters, transfers control to any daughter, and leaves the former player body behind as an autonomous NPC with learned preferences and behavioral history.

**Architecture:** Use Godot 4.7.2 stable with GDScript and data-driven `Resource` definitions. Simulation data is separated from scene/UI nodes: body plans, traits, genomes, individual state, lineage, naming, and localization are pure data/services that can be headless-tested; scenes consume those interfaces. The prototype uses one deterministic procedural zone and one detailed simulation level, while keeping IDs and interfaces compatible with future multi-zone, faction, language, and legacy systems.

**Tech Stack:** Godot 4.7.2 stable Standard build, GDScript 2.0, Godot `Resource` data assets, `TileMapLayer`, `CharacterBody2D`, `Area2D`, `Control`, built-in `Translation`/CSV import, built-in `FastNoiseLite`, Git. No third-party runtime or test dependencies.

**Spec:** `docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md`

## Global Constraints

- Engine: Godot 4.7.2 stable Standard build.
- Language: GDScript only for 0.1.
- Main gameplay: 2D top-down real-time with strong slowdown, not turn-based.
- Starting body: small spider-like creature only.
- Major body-plan changes happen only in descendants; 0.1 does not implement full body-plan replacement.
- 0.1 includes exactly one persistent procedural zone combining forest and underground burrows; no multi-region geopolitics.
- Simulation directly controls one creature; no RTS selection or colony micromanagement.
- No full chromosome simulation. Genetics uses body-plan IDs plus modular numeric/categorical traits.
- No gameplay-critical player-facing string may be hardcoded in simulation logic. Ukrainian is the initial complete locale.
- Procedural names are semantic records rendered by locale-aware templates; gameplay code must not concatenate translated display strings.
- World generation and offspring generation must be reproducible from explicit seeds.
- No procedural magic, Legacy Library, immortality, large colony simulation, firearms, full technology trees, historical language drift, exonym simulation, or cross-world progression in 0.1.
- No save/load system in 0.1. The vertical-slice acceptance test covers several generations in one session.
- Prototype art is functional placeholder art. Do not block system work on final animation or illustration.
- Each task ends with passing headless tests and a Git commit.

---

## File Structure

The 0.1 implementation creates the following responsibility boundaries.

```text
project.godot
README.md
assets/
  prototype/
    tiles.svg
    creature_icons.svg
localization/
  strings.csv
src/
  autoload/
    game_time.gd              # strong-slowdown state; no gameplay ownership
    rng_service.gd            # deterministic named RNG streams
    locale_service.gd         # UI locale switching only
  data/
    body_plan_def.gd          # authored body-plan capabilities
    trait_def.gd              # trait metadata/range/inheritance settings
    species_def.gd            # authored species/group prototype definitions
    naming_profile.gd         # data-driven semantic naming rules
    localized_lexeme.gd       # locale-specific grammatical forms for naming
  genetics/
    genome.gd                 # individual inherited values
    offspring_generator.gd    # seeded recombination/mutation
  creatures/
    creature_state.gd         # individual biological state and identity
    needs_state.gd            # hunger/energy
    injury_state.gd           # lightweight body-part injuries
    personality_state.gd      # learned behavioral tendencies
    food_memory.gd            # preference/aversion learning
    memory_log.gd             # significant event memory
    creature_actor.gd         # CharacterBody2D scene adapter/controller
  world/
    zone_state.gd             # semantic grid, spawn points, territory name
    zone_generator.gd         # deterministic forest+burrow generation
    world_view.gd             # TileMapLayer/collision rendering from ZoneState
  gameplay/
    web/
      web_segment.gd          # one placed web object
      web_system.gd           # placement, triggering, restraint, vibration events
    combat/
      combat_service.gd       # bite, damage, injury, venom application
      venom_status.gd         # timed venom state
    ai/
      ai_brain.gd             # universal Utility + bounded GOAP orchestration
      ai_scheduler.gd         # deterministic staggered/event-driven updates
      perception/             # observations and subjective belief updates
      planning/               # bounded goal/action planning from believed facts
      navigation/             # subjective tactical routing and recovery
    social/
      relationship_state.gd   # trust/fear/respect for prototype interactions
      interaction_service.gd  # feed/bond/reproduction readiness
    nest/
      nest_state.gd           # claimed burrow, food cache, clutch ownership
      nest_marker.gd          # world scene adapter
    reproduction/
      reproduction_service.gd # compatibility + clutch creation
      clutch_state.gd         # eggs/offspring group state
    lineage/
      lineage_graph.gd        # parent-child graph and branch identity
      generation_service.gd   # irreversible transfer and death fallback
  naming/
    generated_name.gd         # semantic name record
    name_generator.gd         # seeded profile-based semantic generation
    name_renderer.gd          # locale-aware rendering
  ui/
    hud.gd
    body_screen.gd
    nest_hub.gd
    lineage_screen.gd
    locale_menu.gd
  game/
    game_state.gd             # owns current run state and current controlled ID
    main.gd                   # scene composition and vertical-slice orchestration
scenes/
  main.tscn
  creature_actor.tscn
  world_view.tscn
  web_segment.tscn
  nest_marker.tscn
  ui/
    hud.tscn
    body_screen.tscn
    nest_hub.tscn
    lineage_screen.tscn
content/
  body_plans/
    arachnid_small.tres
    mothling_small.tres
    scarabkin_small.tres
    burrow_newt_small.tres
    insect_small.tres
    amphibian_predator.tres
  traits/
    body_size.tres
    move_speed.tres
    web_strength.tres
    web_adhesion.tres
    venom_potency.tres
    venom_capacity.tres
    chitin.tres
    metabolism.tres
    sensory_range.tres
    forelimb_dexterity.tres
    membrane_potential.tres
    regeneration.tres
  species/
    player_spider.tres
    mothling.tres
    scarabkin.tres
    burrow_newt.tres
    field_cricket.tres
    frog_predator.tres
  naming/
    arachnid_proto.tres
    mothling_proto.tres
  lexemes/
    uk_basic.tres
    en_basic.tres
    naming_terms.tres
tests/
  run_all.gd
  test_case.gd
  test_rng_service.gd
  test_localization_and_naming.gd
  test_genome.gd
  test_creature_state.gd
  test_zone_generator.gd
  test_web_system.gd
  test_combat_and_ai.gd
  test_social_and_nest.gd
  test_reproduction.gd
  test_generation_transfer.gd
  test_ui_models.gd
  test_vertical_slice.gd
```

---

### Task 1: Bootstrap the Godot project, deterministic test harness, and run shell

**Files:**
- Create: `project.godot`
- Create: `README.md`
- Create: `src/autoload/rng_service.gd`
- Create: `src/autoload/game_time.gd`
- Create: `tests/test_case.gd`
- Create: `tests/run_all.gd`
- Create: `tests/test_rng_service.gd`
- Create: `scenes/main.tscn`
- Create: `src/game/main.gd`

**Interfaces:**
- Produces: `RngService.configure(root_seed: int) -> void`
- Produces: `RngService.stream(stream_id: StringName) -> RandomNumberGenerator`
- Produces: `GameTime.set_slowed(value: bool) -> void`
- Produces: `TestCase.assert_true(value: bool, message: String) -> void`
- Produces: `TestCase.assert_eq(actual: Variant, expected: Variant, message: String) -> void`

- [ ] **Step 1: Create the minimal Godot project and input actions**

Create `project.godot` with renderer `gl_compatibility`, main scene `res://scenes/main.tscn`, and these input actions: `move_up`, `move_down`, `move_left`, `move_right`, `slow_time`, `bite`, `place_web`, `interact`, `open_body`, `open_lineage`, `open_nest`.

Set autoloads:

```ini
[autoload]
RngService="*res://src/autoload/rng_service.gd"
GameTime="*res://src/autoload/game_time.gd"
```

Set locale fallback:

```ini
[internationalization]
locale/fallback="uk"
```

Also create `README.md` with the pinned engine version, the headless test command `godot --headless --path . --script res://tests/run_all.gd`, the smoke-boot command `godot --headless --path . --quit-after 2`, and a one-paragraph statement that 0.1 is the generation-loop vertical slice from the linked design spec.

- [ ] **Step 2: Write the failing deterministic-RNG test**

Create `tests/test_rng_service.gd`:

```gdscript
extends "res://tests/test_case.gd"

func run() -> void:
    RngService.configure(123456)
    var a := RngService.stream(&"world")
    var first := [a.randi(), a.randi(), a.randi()]

    RngService.configure(123456)
    var b := RngService.stream(&"world")
    var second := [b.randi(), b.randi(), b.randi()]

    assert_eq(first, second, "same root seed and stream ID must reproduce sequence")

    RngService.configure(123456)
    var c := RngService.stream(&"offspring")
    assert_true(c.randi() != first[0], "different stream IDs must not share the same first value")
```

Create `tests/test_case.gd` with failure collection, and `tests/run_all.gd` as a `SceneTree` script that loads every suite listed explicitly, calls `run()`, prints failures, and exits with code `1` on failure and `0` on success.

- [ ] **Step 3: Run the test to verify the RNG service is missing**

Run:

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Expected: non-zero exit because `RngService.configure`/`stream` are not implemented.

- [ ] **Step 4: Implement named deterministic RNG streams**

`src/autoload/rng_service.gd`:

```gdscript
extends Node

var _root_seed: int = 1
var _streams: Dictionary = {}

func configure(root_seed: int) -> void:
    _root_seed = root_seed
    _streams.clear()

func stream(stream_id: StringName) -> RandomNumberGenerator:
    if not _streams.has(stream_id):
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("%s:%s" % [_root_seed, String(stream_id)])
        _streams[stream_id] = rng
    return _streams[stream_id]
```

`src/autoload/game_time.gd`:

```gdscript
extends Node

const NORMAL_SCALE := 1.0
const SLOWED_SCALE := 0.12
var slowed := false

func set_slowed(value: bool) -> void:
    slowed = value
    Engine.time_scale = SLOWED_SCALE if value else NORMAL_SCALE
```

- [ ] **Step 5: Create a bootable empty main scene**

`src/game/main.gd` should restore `Engine.time_scale = 1.0` in `_exit_tree()` and update slowdown from `Input.is_action_pressed("slow_time")` in `_process()`.

- [ ] **Step 6: Run tests and smoke boot**

Run:

```bash
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --quit-after 2
```

Expected: tests PASS; smoke boot exits without parser/runtime errors.

- [ ] **Step 7: Commit**

```bash
git add project.godot README.md src tests scenes
git commit -m "chore: bootstrap Godot 0.1 project and test harness"
```

---

### Task 2: Localization and semantic procedural naming foundation

**Files:**
- Create: `localization/strings.csv`
- Create: `src/autoload/locale_service.gd`
- Modify: `project.godot`
- Create: `src/data/localized_lexeme.gd`
- Create: `src/data/naming_profile.gd`
- Create: `src/naming/generated_name.gd`
- Create: `src/naming/name_generator.gd`
- Create: `src/naming/name_renderer.gd`
- Create: `content/naming/arachnid_proto.tres`
- Create: `content/naming/mothling_proto.tres`
- Create: `content/lexemes/uk_basic.tres`
- Create: `content/lexemes/en_basic.tres`
- Create: `content/lexemes/naming_terms.tres`
- Create: `tests/test_localization_and_naming.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `RngService.stream(stream_id)`
- Produces: `LocaleService.set_locale(locale_code: String) -> void`
- Produces: `NameGenerator.generate(profile: NamingProfile, kind: StringName, rng: RandomNumberGenerator) -> GeneratedName`
- Produces: `NameRenderer.render(name: GeneratedName, locale_code: String) -> String`
- `GeneratedName` fields: `kind: StringName`, `profile_id: StringName`, `proper_form: String`, `semantic_tokens: Array[StringName]`

- [ ] **Step 1: Write failing tests for locale switching and semantic name rendering**

Add a suite that constructs a `GeneratedName` with `kind=&"nest_descriptor"` and semantic tokens `&"silver"`, `&"web"`, then asserts:

```gdscript
assert_eq(NameRenderer.render(record, "uk"), "Лігво Срібної Павутини", "Ukrainian grammar template")
assert_eq(NameRenderer.render(record, "en"), "Nest of the Silver Web", "English grammar template")
```

Also seed the naming generator twice with the same seed and assert equal semantic records.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Expected: FAIL because naming and locale classes/resources do not exist.

- [ ] **Step 3: Implement locale switching using Godot TranslationServer**

`src/autoload/locale_service.gd`:

```gdscript
extends Node

signal locale_changed(locale_code: String)

func set_locale(locale_code: String) -> void:
    TranslationServer.set_locale(locale_code)
    locale_changed.emit(locale_code)

func current_locale() -> String:
    return TranslationServer.get_locale()
```

Register it as an autoload. Create `localization/strings.csv` with headers `keys,uk,en` and the prototype keys needed at this stage: `ui.hunger`, `ui.energy`, `ui.condition`, `ui.body`, `ui.lineage`, `ui.nest`, `ui.locale`, `name.nest_descriptor`, `name.territory_descriptor`, `name.group_descriptor`, `species.player_spider`, `species.mothling`, `species.scarabkin`, `species.burrow_newt`, `species.field_cricket`, and `species.frog_predator`. Later UI tasks extend the same file when they introduce new visible text.

- [ ] **Step 4: Implement semantic name records and locale-specific grammar forms**

`LocalizedLexeme` stores `id: StringName` and `forms_by_locale: Dictionary`. For the prototype, each locale form dictionary may contain keys such as `nom`, `gen`, `adj_nom_f`, `adj_gen_f`. `NameRenderer` selects a template by `GeneratedName.kind` and locale, then requests the required forms.

For the required nest example, store the locale templates in `localization/strings.csv`, not in GDScript:

```csv
keys,uk,en
name.nest_descriptor,Лігво %s %s,Nest of the %s %s
```

`NameRenderer` asks `TranslationServer` for `name.nest_descriptor`, then supplies the locale-appropriate lexeme forms. For Ukrainian it obtains `silver.adj_gen_f + web.gen`; for English it obtains `silver.nom + web.nom`. Do not store either the template or the final rendered string in simulation code or in `GeneratedName`.

- [ ] **Step 5: Implement phonotactic proper-name generation**

`NamingProfile` must contain `profile_id`, `onsets`, `nuclei`, `codas`, `min_syllables`, `max_syllables`, and weighted name-kind strategies. `NameGenerator` builds `proper_form` deterministically from the provided RNG and supports the 0.1 kinds `individual`, `nest_descriptor`, `group_descriptor`, and `territory_descriptor`; descriptor kinds return semantic token records rather than pre-rendered display strings.

- [ ] **Step 6: Run tests and smoke-switch locale**

Run:

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Expected: PASS for deterministic naming and Ukrainian/English rendering.

- [ ] **Step 7: Commit**

```bash
git add project.godot localization src/autoload/locale_service.gd src/data src/naming content/naming content/lexemes tests
git commit -m "feat: add localization and semantic naming foundation"
```

---

### Task 3: Body plans, traits, species definitions, and genome data model

**Files:**
- Create: `src/data/body_plan_def.gd`
- Create: `src/data/trait_def.gd`
- Create: `src/data/species_def.gd`
- Create: `src/genetics/genome.gd`
- Create: `content/body_plans/arachnid_small.tres`
- Create: `content/body_plans/mothling_small.tres`
- Create: `content/body_plans/scarabkin_small.tres`
- Create: `content/body_plans/burrow_newt_small.tres`
- Create: `content/body_plans/insect_small.tres`
- Create: `content/body_plans/amphibian_predator.tres`
- Create: all 12 trait `.tres` files listed in File Structure
- Create: six prototype species `.tres` files listed in File Structure
- Create: `tests/test_genome.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `Genome.get_value(trait_id: StringName) -> float`
- Produces: `Genome.set_value(trait_id: StringName, value: float) -> void`
- Produces: `Genome.clone_genome() -> Genome`
- `BodyPlanDef` fields: `id`, `display_key`, `base_parts`, `movement_capabilities`, `size_class`
- `TraitDef` fields: `id`, `display_key`, `min_value`, `max_value`, `mutation_sigma`, `inheritance_weight`
- `SpeciesDef` fields: `id`, `display_key`, `body_plan`, `base_genome`, `cognition_band`, `diet_tags`, `reproduction_tags`

- [ ] **Step 1: Write failing genome clamping and clone tests**

```gdscript
func run() -> void:
    var g := Genome.new()
    g.body_plan_id = &"arachnid_small"
    g.set_value(&"move_speed", 1.25)
    assert_eq(g.get_value(&"move_speed"), 1.25, "stored trait value")

    var copy := g.clone_genome()
    copy.set_value(&"move_speed", 0.75)
    assert_eq(g.get_value(&"move_speed"), 1.25, "clone must not alias source dictionary")
```

- [ ] **Step 2: Run tests and verify missing classes fail**

Run the headless suite; expect FAIL.

- [ ] **Step 3: Implement Resource classes with stable IDs**

`Genome` is a `Resource` with `body_plan_id: StringName` and `trait_values: Dictionary`. It contains no UI strings. `TraitDef.clamp_value(value)` owns clamping rules, while `Genome` stores normalized/actual values supplied by generation code.

- [ ] **Step 4: Author exactly twelve inherited prototype traits**

Use IDs and initial normalized ranges:

```text
body_size              0.60..1.40
move_speed             0.60..1.50
web_strength           0.50..1.60
web_adhesion           0.50..1.60
venom_potency          0.30..1.70
venom_capacity         0.40..1.60
chitin                 0.50..1.60
metabolism             0.60..1.50
sensory_range          0.60..1.60
forelimb_dexterity     0.00..1.50
membrane_potential     0.00..1.50
regeneration           0.00..1.20
```

Author six prototype body plans with capabilities appropriate to their silhouettes: `arachnid_small` (`wall_crawl`, `small_gap`), `mothling_small` (`ground_move`), `scarabkin_small` (`ground_move`), `burrow_newt_small` (`ground_move`, `small_gap`), `insect_small` (`ground_move`, `small_gap`), and `amphibian_predator` (`ground_move`).

Author the player spider around `1.0` for spider-native traits, `0.15` forelimb dexterity, `0.0` membrane potential, `0.10` regeneration.

Author three semi/intelligent groups with distinct trait biases: mothling favors sensory/membrane, scarabkin favors chitin/body size, burrow newt favors regeneration/dexterity. Author cricket prey and frog predator as non-reproductive ecosystem actors.

- [ ] **Step 5: Run tests and resource-load smoke test**

Add assertions that every species resource loads, references one of the six authored prototype body-plan IDs, and every genome trait ID resolves to a `TraitDef`.

- [ ] **Step 6: Commit**

```bash
git add src/data src/genetics content tests/test_genome.gd tests/run_all.gd
git commit -m "feat: add data-driven body plans species and genomes"
```

---

### Task 4: Individual creature state, needs, injury, personality, food memory, and significant memory

**Files:**
- Create: `src/creatures/needs_state.gd`
- Create: `src/creatures/injury_state.gd`
- Create: `src/creatures/personality_state.gd`
- Create: `src/creatures/food_memory.gd`
- Create: `src/creatures/memory_log.gd`
- Create: `src/creatures/creature_state.gd`
- Create: `tests/test_creature_state.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `CreatureState.creature_id: StringName`
- Produces: `CreatureState.genome: Genome`
- Produces: `CreatureState.needs: NeedsState`
- Produces: `CreatureState.injuries: InjuryState`
- Produces: `CreatureState.personality: PersonalityState`
- Produces: `CreatureState.food_memory: FoodMemory`
- Produces: `CreatureState.memory: MemoryLog`
- Produces: `NeedsState.tick(delta_seconds: float, metabolism: float) -> void`
- Produces: `PersonalityState.record_behavior(tag: StringName, weight: float) -> void`
- Produces: `FoodMemory.record_food(food_id: StringName, nutrition: float, context_tags: Array[StringName]) -> void`
- Produces: `MemoryLog.remember(event_id: StringName, importance: float, payload: Dictionary) -> void`

- [ ] **Step 1: Write failing behavior-history tests**

Test that repeated `record_behavior(&"cannibalism", 1.0)` crosses the visible threshold while a single small event does not; test that repeated `record_food(&"harpy_meat", ...)` ranks it above a less-used food; test that memory keeps high-importance events and prunes low-importance entries when capacity is exceeded.

- [ ] **Step 2: Run tests and verify failure**

Run the suite; expect missing state classes.

- [ ] **Step 3: Implement bounded numeric histories**

Use normalized tendency scores `0.0..1.0` for prototype personality dimensions. Apply diminishing increments:

```gdscript
func record_behavior(tag: StringName, weight: float) -> void:
    var current := float(tendencies.get(tag, 0.0))
    tendencies[tag] = clampf(current + (1.0 - current) * 0.12 * weight, 0.0, 1.0)
```

Visible threshold: `>= 0.60`; suspected threshold: `>= 0.35`.

`FoodMemory` stores `exposure`, `positive`, `negative`, and computes preference `positive - negative` with starvation-save events weighted more strongly and poisoning weighted negative.

- [ ] **Step 4: Implement needs and lightweight injuries**

`NeedsState` tracks `energy: float` and `hunger: float` in `0..100`. Hunger rises with metabolism; energy falls faster while sprinting/attacking in later scene code. `InjuryState` stores injuries by semantic body part IDs `core`, `legs`, `mouth`, with severity and effects. Do not model every organ in 0.1.

- [ ] **Step 5: Assemble `CreatureState` as pure data**

Give each individual stable IDs, species ID, genome, age stage (`hatchling`, `juvenile`, `adult`), condition, needs, injury, personality, food memory, memory log, and relationship dictionary. No node references belong in `CreatureState`.

- [ ] **Step 6: Run tests**

Expected: PASS for needs progression, behavior thresholds, food preference ranking, memory pruning, and injury lookup.

- [ ] **Step 7: Commit**

```bash
git add src/creatures tests/test_creature_state.gd tests/run_all.gd
git commit -m "feat: add individual creature history and survival state"
```

---

### Task 5: Deterministic forest-and-burrow zone generation and world presentation

**Files:**
- Create: `src/world/zone_state.gd`
- Create: `src/world/zone_generator.gd`
- Create: `src/world/world_view.gd`
- Create: `scenes/world_view.tscn`
- Create: `assets/prototype/tiles.svg`
- Create: `tests/test_zone_generator.gd`
- Modify: `tests/run_all.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `RngService`
- Produces: `ZoneGenerator.generate(seed: int, width: int, height: int) -> ZoneState`
- `ZoneState` fields: `width`, `height`, `cells`, `spawn_points`, `nest_candidates`, `territory_name: GeneratedName`
- Produces cell semantic types: `forest_floor`, `tree_block`, `burrow_floor`, `burrow_wall`, `climbable_wall`, `small_gap`
- Produces: `WorldView.build_from_state(zone: ZoneState) -> void`

- [ ] **Step 1: Write failing deterministic-map tests**

Generate `64x64` twice with seed `424242` and assert the cell arrays, player spawn, predator spawn, and nest candidate positions are identical. Assert that the map contains both `forest_floor` and `burrow_floor`, at least one nest candidate, and a connected traversable path from player spawn to one food spawn.

- [ ] **Step 2: Run tests and verify failure**

Run headless tests; expect missing generator.

- [ ] **Step 3: Implement the semantic grid generator**

Use `FastNoiseLite` for forest density and a deterministic cellular-automata pocket for burrows. The semantic generator must be independent from `TileMapLayer`; tests operate only on `ZoneState`.

Generation order:

1. Fill surface with forest floor.
2. Use noise threshold for tree blocks while reserving a 7x7 safe spawn clearing.
3. Carve one underground/burrow region in the lower third of the grid using seeded cellular automata.
4. Mark the burrow boundary as `climbable_wall` where adjacent to burrow floor.
5. Add 2–4 `small_gap` shortcuts accessible to small creatures.
6. Select one safe nest candidate in the burrow.
7. Select prey, predator, and social-group spawn points at minimum Manhattan distances from the player.
8. Validate connectivity; if required paths are disconnected, carve a deterministic corridor rather than rerolling indefinitely.

- [ ] **Step 4: Render `ZoneState` through `TileMapLayer`**

Create a four/six-cell prototype tile atlas from `assets/prototype/tiles.svg`. `WorldView` reads semantic cells and paints tiles, creates `StaticBody2D` collision only for truly blocked cells, and adds metadata/areas for climbable and small-gap cells.

- [ ] **Step 5: Add the world view to the main scene and smoke boot**

Main creates a `ZoneState` from fixed dev seed `424242` and builds the world. The scene must boot headlessly without requiring editor-authored runtime state.

- [ ] **Step 6: Run tests**

Expected: deterministic generator PASS and smoke boot PASS.

- [ ] **Step 7: Commit**

```bash
git add src/world scenes/world_view.tscn scenes/main.tscn assets/prototype tests/test_zone_generator.gd tests/run_all.gd
git commit -m "feat: generate deterministic forest and burrow zone"
```

---

### Task 6: Player creature controller, traversal, hunger, and active slowdown

**Files:**
- Create: `src/creatures/creature_actor.gd`
- Create: `scenes/creature_actor.tscn`
- Modify: `src/game/main.gd`
- Modify: `scenes/main.tscn`
- Create: `tests/test_ui_models.gd` (initial movement-state model assertions)
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `CreatureState`, `ZoneState`, `GameTime`
- Produces: `CreatureActor.bind_state(state: CreatureState) -> void`
- Produces signals: `state_changed(creature_id)`, `died(creature_id)`, `entered_food(food_id)`
- Produces capability checks: `can_enter_cell(cell_type: StringName) -> bool`

- [ ] **Step 1: Write failing capability tests**

Test a hatchling spider genome/body plan can enter `small_gap` and `climbable_wall`, cannot enter `tree_block`, and an adult scarabkin prototype cannot enter `small_gap`.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL because capability adapter is missing.

- [ ] **Step 3: Implement real-time movement from body-plan capabilities**

`CreatureActor` extends `CharacterBody2D`, reads directional actions into a normalized vector, applies speed derived from `move_speed * age_stage_modifier * injury_modifier`, and calls `move_and_slide()`.

Climbing prototype rule: while overlapping a climbable-wall area and the bound body plan contains capability `wall_crawl`, wall collision is temporarily excluded for that actor. Small gaps are `Area2D` transitions that only permit `size_class <= 1`.

- [ ] **Step 4: Connect slowdown and needs**

Holding `slow_time` sets `Engine.time_scale` through `GameTime`. `CreatureActor` calls `NeedsState.tick` from `_physics_process`; movement increases energy drain. At hunger `>= 90`, condition loss starts slowly. Eating later resets hunger through a single `consume_food(food_id, nutrition)` method that also records `FoodMemory`.

- [ ] **Step 5: Spawn the controlled spider from pure data**

`Main` creates `GameState` later; for this task create one `CreatureState` from the player-spider species resource and place its actor at `ZoneState.spawn_points.player`.

- [ ] **Step 6: Run tests and a manual control smoke test**

Automated command:

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Manual acceptance: launch the project, move with WASD, hold slowdown and observe visibly slower world motion, enter the marked climbable boundary, pass through a small gap, and confirm hunger rises over time.

- [ ] **Step 7: Commit**

```bash
git add src/creatures scenes/creature_actor.tscn src/game scenes/main.tscn tests
git commit -m "feat: add controllable spider traversal and survival loop"
```

---

### Task 7: Web placement, web triggering, restraint, and vibration sensing

**Files:**
- Create: `src/gameplay/web/web_segment.gd`
- Create: `src/gameplay/web/web_system.gd`
- Create: `scenes/web_segment.tscn`
- Create: `tests/test_web_system.gd`
- Modify: `tests/run_all.gd`
- Modify: `src/creatures/creature_actor.gd`
- Modify: `src/game/main.gd`

**Interfaces:**
- Produces: `WebSystem.place_web(owner: CreatureState, world_position: Vector2, normal: Vector2) -> WebSegment`
- Produces signal: `web_triggered(owner_id: StringName, intruder_id: StringName, world_position: Vector2)`
- `WebSegment` fields: `owner_id`, `strength`, `adhesion`, `durability`, `armed`
- Produces: `WebSegment.restraint_multiplier(target_body_size: float) -> float`

- [ ] **Step 1: Write failing deterministic web-stat tests**

Construct a genome with `web_strength=1.3`, `web_adhesion=1.2`, place a segment, and assert those values map to durability/restraint. Test that a larger target receives less restraint than a smaller target.

- [ ] **Step 2: Run tests and verify failure**

Expected: missing web system.

- [ ] **Step 3: Implement web scene and placement rules**

Allow placement only within `48 px` of the controlled spider and only on traversable or climbable terrain. Give the player a small silk reserve derived from metabolism/web traits; reserve regenerates slowly while fed. `place_web` consumes reserve and rejects placement when insufficient.

- [ ] **Step 4: Implement triggering and vibration memory**

When a non-owner creature enters a web `Area2D`, reduce its movement speed by the restraint multiplier, damage web durability over struggle time, and emit `web_triggered`. If the owner is within sensory range, add a high-importance memory `web_vibration` with position and intruder ID.

- [ ] **Step 5: Wire `place_web` input**

Pressing `place_web` places the segment toward the cursor/aim vector. Show a simple line/patch sprite; final art is not required.

- [ ] **Step 6: Run tests and manual trap check**

Manual acceptance: place a web, lure/spawn a cricket into it, observe slowdown, receive vibration cue, and see the web break after enough struggle.

- [ ] **Step 7: Commit**

```bash
git add src/gameplay/web scenes/web_segment.tscn src/creatures/creature_actor.gd src/game/main.gd tests/test_web_system.gd tests/run_all.gd
git commit -m "feat: add functional spider web traps"
```

---

### Task 8A — AI Foundation

Build the universal creature reasoning foundation before adding live combat or ecology actors. This phase introduces subjective observations and beliefs, Utility goal selection, bounded GOAP-style planning, capability-driven actions, persistent individual knowledge/strategy learning/habits, evolvable cognition profiles, deterministic staggered scheduling, tactical navigation, and AI introspection.

No species-specific `PreyBrain` or `PredatorBrain` is created. Authored profiles and creature capabilities configure the universal `AIBrain`.

Detailed files, interfaces, RED/GREEN steps, commits, and the Task 8A review gate are authoritative in:

`docs/superpowers/plans/2026-09-15-advanced-creature-ai-implementation-plan.md`

---

### Task 8B — Combat and Living AI Integration

After the Task 8A review gate, connect the universal foundation to bite, venom, injury consequences, feeding, live perception, movement/action execution, web events, and the prototype ecology actors.

The field cricket and frog predator must use the same `AIBrain` architecture. Their prey/predator differences come from subjective knowledge, cognition/instinct profiles, goals, available actions, and body capabilities—not separate brain classes.

Detailed files, interfaces, tests, integration order, manual acceptance, and commits are authoritative in:

`docs/superpowers/plans/2026-09-15-advanced-creature-ai-implementation-plan.md`

---

### Task 9: Prototype social groups, relationships, and nest claiming

**Files:**
- Create: `src/gameplay/social/relationship_state.gd`
- Create: `src/gameplay/social/interaction_service.gd`
- Create: `src/gameplay/nest/nest_state.gd`
- Create: `src/gameplay/nest/nest_marker.gd`
- Create: `scenes/nest_marker.tscn`
- Create: `tests/test_social_and_nest.gd`
- Modify: `tests/run_all.gd`
- Modify: `src/game/main.gd`

**Interfaces:**
- Produces: `RelationshipState.adjust(axis: StringName, amount: float) -> void`
- Produces: `InteractionService.offer_food(actor: CreatureState, target: CreatureState, food_id: StringName, nutrition: float) -> Dictionary`
- Produces: `InteractionService.reproduction_readiness(actor: CreatureState, target: CreatureState) -> float`
- Produces: `NestState.claim(founder_id: StringName, position: Vector2) -> void`
- `NestState` fields: `nest_id`, `founder_id`, `member_ids`, `food_cache`, `clutch_ids`, `generated_name`

- [ ] **Step 1: Write failing relationship/readiness tests**

Test that repeated food gifts increase trust, attacking decreases trust and raises fear, and a compatible mothling does not become reproduction-ready until trust reaches the prototype threshold `0.60`.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL.

- [ ] **Step 3: Implement multidimensional prototype relationships**

Use axes `trust`, `fear`, `respect`, `affection`, each clamped `-1..1` except fear `0..1`. Store reasons as a bounded list of recent/high-importance semantic events, not one friendship number.

- [ ] **Step 4: Implement prototype social interactions**

For 0.1:

- Mothling: compatible only after trust `>= 0.60`; food gift raises trust.
- Scarabkin: not used by the primary clutch path, but can gain/lose trust and demonstrates a different trait pool.
- Burrow newt: neutral group used for observation and naming/UI.

Generate a deterministic individual name for each representative and a deterministic semantic group name from that species' `NamingProfile`.

This task intentionally does not implement full final species-specific courtship systems.

- [ ] **Step 5: Implement one claimable burrow nest**

Give the three social-group representatives a minimal autonomous `wander_near_anchor` behavior through the universal `AIBrain` so they are living actors rather than stationary interaction terminals.

At the generated nest candidate, `interact` claims the burrow if unowned. Generate a semantic nest name with the current naming profile. Track founder, members, cached food count, and clutches. Claiming adds a significant memory event `claimed_nest`.

- [ ] **Step 6: Run tests and manual social/nest check**

Manual acceptance: claim the burrow, see its localized generated name, give food to the mothling representative, and observe trust/readiness feedback without hardcoded display strings.

- [ ] **Step 7: Commit**

```bash
git add src/gameplay/social src/gameplay/nest scenes/nest_marker.tscn src/game/main.gd tests/test_social_and_nest.gd tests/run_all.gd
git commit -m "feat: add prototype relationships and claimable nest"
```

---

### Task 10: Seeded reproduction, clutch generation, and meaningful offspring variation

**Files:**
- Create: `src/gameplay/reproduction/clutch_state.gd`
- Create: `src/gameplay/reproduction/reproduction_service.gd`
- Create: `src/genetics/offspring_generator.gd`
- Create: `tests/test_reproduction.gd`
- Modify: `tests/run_all.gd`
- Modify: `src/gameplay/nest/nest_state.gd`
- Modify: `src/game/main.gd`

**Interfaces:**
- Produces: `OffspringGenerator.generate(parent_a: Genome, parent_b: Genome, seed: int, count: int) -> Array[Genome]`
- Produces: `ReproductionService.create_clutch(parent_a: CreatureState, parent_b: CreatureState, nest: NestState, seed: int) -> ClutchState`
- `ClutchState` fields: `clutch_id`, `parent_ids`, `offspring_ids`, `incubation_remaining`, `nest_id`

- [ ] **Step 1: Write failing offspring determinism and diversity tests**

With fixed parent genomes and seed `9001`, generate six offspring twice and assert exact equality between runs. Within one clutch assert at least three distinct genome signatures. Assert every trait remains inside its `TraitDef` range.

Also assert directional inheritance:

- scarabkin-biased partner raises expected chitin/body-size mean;
- mothling-biased partner raises expected sensory/membrane mean.

The primary playable reproduction path uses the mothling prototype after social readiness.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL.

- [ ] **Step 3: Implement recombination and mutation**

For each trait:

```gdscript
var inherited := lerpf(parent_a_value, parent_b_value, rng.randf_range(0.20, 0.45))
var mutation := rng.randfn(0.0, trait_def.mutation_sigma)
var child_value := trait_def.clamp_value(inherited + mutation)
```

For lineage-native traits, weight parent A slightly more strongly in 0.1. Preserve latent low-valued traits rather than snapping them to zero. Body plan remains `arachnid_small` in 0.1; no full body-plan swap yet.

- [ ] **Step 4: Implement four emergent second-generation directions without classes**

Compute descriptive tags from genome thresholds for UI/AI only:

- `hunter`: high move speed + venom potency;
- `weaver`: high web strength + adhesion;
- `armored`: high chitin + body size;
- `proto_morph`: high dexterity or membrane potential.

These tags must be derived from genome values and must not replace the genome with a class enum.

- [ ] **Step 5: Implement clutch incubation and hatching**

Primary 0.1 clutch count: seeded `4..7`. Incubation requires a claimed nest. When incubation reaches zero, create child `CreatureState` records at stage `hatchling`, add them to nest and lineage later, and spawn actors with reduced size/speed and high dependency pressure.

- [ ] **Step 6: Run tests and manual clutch check**

Manual acceptance: bond with compatible mothling, create a clutch at the nest, wait through incubation, hatch at least four visually/statistically distinct daughters, and inspect derived direction tags.

- [ ] **Step 7: Commit**

```bash
git add src/gameplay/reproduction src/genetics/offspring_generator.gd src/gameplay/nest/nest_state.gd src/game/main.gd tests/test_reproduction.gd tests/run_all.gd
git commit -m "feat: add seeded clutch genetics and offspring variation"
```

---

### Task 11: Lineage graph, irreversible generation transfer, former-player NPC behavior, and death fallback

**Files:**
- Create: `src/gameplay/lineage/lineage_graph.gd`
- Create: `src/gameplay/lineage/generation_service.gd`
- Reuse/modify: the universal `AIBrain` foundation delivered by Task 8A
- Create: `src/game/game_state.gd`
- Create: `tests/test_generation_transfer.gd`
- Modify: `tests/run_all.gd`
- Modify: `src/game/main.gd`
- Modify: `src/gameplay/reproduction/reproduction_service.gd`

**Interfaces:**
- Produces: `LineageGraph.add_creature(creature_id, parent_ids: Array[StringName]) -> void`
- Produces: `LineageGraph.living_descendants(creature_id: StringName) -> Array[StringName]`
- Produces: `LineageGraph.eligible_fallbacks(creature_id: StringName, living_ids: Array[StringName]) -> Array[StringName]`
- Produces: `GenerationService.transfer_control(game: GameState, next_id: StringName) -> bool`
- Produces: `GenerationService.resolve_death(game: GameState, dead_id: StringName) -> StringName`
- `GameState` owns: `creatures`, `actors`, `lineage`, `current_creature_id`, `nest`, `zone`, `run_seed`

- [ ] **Step 1: Write failing lineage and transfer tests**

Build a family graph `mother -> daughter_a, daughter_b`, `daughter_a -> granddaughter`. Assert:

1. Transfer from mother to living daughter B succeeds.
2. Transfer back to mother is rejected after transfer.
3. The former mother remains alive and marked autonomous.
4. If daughter B dies childless, eligible fallback includes sister A before unrelated creatures.
5. If no eligible living lineage exists, `resolve_death` returns empty `StringName()` and marks run ended.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL.

- [ ] **Step 3: Implement lineage graph and `GameState` ownership**

Move run-level ownership out of `Main`. `Main` becomes composition/input/UI wiring. All living `CreatureState` objects live in `GameState.creatures`; actor nodes are adapters keyed by ID.

- [ ] **Step 4: Implement irreversible voluntary transfer**

Eligibility for 0.1 voluntary transfer: the target is alive, is a direct daughter of current creature, and may be any age stage including hatchling. On transfer:

1. mark former actor autonomous;
2. attach the universal `AIBrain` using the former player's persistent knowledge, strategy learning, habits, personality, food memory, significant memory, needs, and relationships;
3. set target actor player-controlled;
4. update `current_creature_id`;
5. remember `control_transferred` on both creatures.

Do not expose any path to transfer back.

- [ ] **Step 5: Make former-player NPC behavior reflect learned history**

The universal `AIBrain` reuses the creature's persistent learned state. Required 0.1 influences:

- high hunger raises food-seeking weight;
- strong food preference raises target-food weight;
- high protectiveness raises response to threatened offspring;
- high cannibalism tendency lowers the penalty for consuming dead close relatives during severe hunger;
- high caution lowers attack preference against stronger creatures;
- remembered successful web-hunt positions raise revisit weight when hungry.

Task 11 must not introduce a second former-player AI path. It extends the Task 8A Utility + bounded GOAP foundation only as required for lineage transfer behavior.

- [ ] **Step 6: Implement death fallback**

On controlled death, ask `LineageGraph.eligible_fallbacks` for living relatives ordered: daughters, sisters, nieces, aunts, cousins/other known close branch. Transfer automatically to the first eligible candidate for the prototype; the later UI may offer a choice. If none exist, show localized run-ended state.

- [ ] **Step 7: Run tests and manual transfer check**

Manual acceptance: choose a hatchling daughter, take control, observe the mother continue moving/feeding according to her prior preferences, then deliberately kill the controlled daughter and confirm fallback to another living relative.

- [ ] **Step 8: Commit**

```bash
git add src/gameplay/lineage src/game/game_state.gd src/gameplay/ai src/game/main.gd src/gameplay/reproduction tests/test_generation_transfer.gd tests/run_all.gd
git commit -m "feat: add lineage transfer autonomous former bodies and death fallback"
```

---

### Task 12: HUD, side-view body screen, nest hub, lineage screen, and locale menu

**Files:**
- Create: `src/ui/hud.gd`
- Create: `src/ui/body_screen.gd`
- Create: `src/ui/nest_hub.gd`
- Create: `src/ui/lineage_screen.gd`
- Create: `src/ui/locale_menu.gd`
- Create: `scenes/ui/hud.tscn`
- Create: `scenes/ui/body_screen.tscn`
- Create: `scenes/ui/nest_hub.tscn`
- Create: `scenes/ui/lineage_screen.tscn`
- Create: `assets/prototype/creature_icons.svg`
- Modify: `scenes/main.tscn`
- Modify: `localization/strings.csv`
- Modify: `tests/test_ui_models.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `GameState`, `CreatureState`, `LineageGraph`, `NestState`, `NameRenderer`, `LocaleService`
- Produces: `BodyScreen.present(creature: CreatureState) -> void`
- Produces: `NestHub.present(nest: NestState, game: GameState) -> void`
- Produces: `LineageScreen.present(lineage: LineageGraph, game: GameState) -> void`

- [ ] **Step 1: Write failing UI-view-model tests**

Without instantiating graphical scenes, create pure helper functions that return view dictionaries. Assert:

- HUD exposes condition, hunger, energy, visible injuries only;
- body view exposes current trait values and derived direction tags but not undiscovered universal evolution paths;
- lineage view includes known relatives and statuses but no unrelated hidden creature;
- switching locale changes rendered species/nest labels while semantic IDs stay unchanged.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL.

- [ ] **Step 3: Implement minimal HUD**

HUD shows localized labels for condition, hunger, energy, relevant injuries, silk reserve, and slowdown state. Keep genetics/social values off the normal HUD.

- [ ] **Step 4: Implement the large side-view body presentation**

Use modular placeholder SVG layers driven by genome values:

- body size scales overall silhouette;
- chitin changes shell thickness marker;
- forelimb dexterity changes forelimb shape marker;
- membrane potential displays a small lateral membrane when above `0.55`;
- venom/web traits display organ bars/icons rather than changing the top-down sprite.

This is a readability prototype, not final character art.

- [ ] **Step 5: Implement nest hub**

Show the current/former matriarch, hatchlings, clutch, nest name, cached food, and a control-transfer action for each living daughter. The action calls `GenerationService.transfer_control` and closes/rebuilds the panel afterward.

- [ ] **Step 6: Implement lineage screen**

Render a simple scrollable parent-child tree with creature names, living/dead status, current controlled marker, and derived evolutionary direction. The full centuries-scale branch visualization is not required in 0.1.

- [ ] **Step 7: Implement locale menu**

Expose Ukrainian and English buttons for prototype validation. On locale change, rebuild visible labels/names via `LocaleService` and `NameRenderer`; no simulation object is recreated or renamed semantically. Extend `localization/strings.csv` with every visible key introduced by Tasks 6–12, then add a test that enumerates those required keys and asserts the Ukrainian translation is non-empty and differs from the raw key.

- [ ] **Step 8: Run tests and manual UI check**

Manual acceptance: open body/nest/lineage screens; compare two genetically different daughters; switch locale while panels are open; confirm Ukrainian names/labels render correctly and top-down play resumes after closing panels.

- [ ] **Step 9: Commit**

```bash
git add src/ui scenes/ui assets/prototype/creature_icons.svg scenes/main.tscn localization tests/test_ui_models.gd tests/run_all.gd
git commit -m "feat: add localized body nest and lineage interfaces"
```

---

### Task 13: Vertical-slice integration, acceptance scenario, tuning, and release gate

**Files:**
- Create: `tests/test_vertical_slice.gd`
- Modify: `tests/run_all.gd`
- Modify: `src/game/main.gd`
- Modify: `src/game/game_state.gd`
- Modify: balancing values in `content/**/*.tres`
- Modify: `README.md`

**Interfaces:**
- Consumes all prior task interfaces.
- Produces no new subsystem API; this task proves the 0.1 loop works end to end.

- [ ] **Step 1: Write a headless end-to-end simulation test**

The test uses pure state/services instead of scene input. With fixed run seed `13371337`:

1. Generate the zone.
2. Create the starting spider.
3. Claim the generated nest.
4. Create a compatible mothling and set trust through the same `InteractionService` calls used by gameplay.
5. Create and hatch a clutch.
6. Assert at least four living daughters exist and at least three genome signatures differ.
7. Transfer control to a hatchling daughter.
8. Assert former mother is autonomous and retains food/personality history.
9. Kill the controlled daughter.
10. Assert control resolves to another living relative.
11. Repeat one more reproduction/transfer cycle using the new controlled creature so the lineage reaches at least generation 3.
12. Assert the run has not ended and lineage depth is `>= 3`.

- [ ] **Step 2: Run the full suite and fix any cross-system failures**

Run:

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Expected: all suites PASS with exit code `0`.

- [ ] **Step 3: Run parser/import smoke checks**

Run:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 3
```

Expected: resources import and the main scene boots without errors.

- [ ] **Step 4: Tune the early-survival numbers against explicit targets**

Use these 0.1 targets for a normal-skill manual run:

- starvation from full hunger should take roughly 12–18 real-time minutes if the player never eats;
- first cricket should be findable within roughly 60–120 seconds from spawn;
- one unprepared frog encounter should be dangerous but usually escapable through terrain;
- player should be able to place at least 4 ordinary web segments before silk starvation;
- first nest should be reachable within roughly 3–6 minutes if explored directly;
- first clutch should be achievable within roughly 12–25 minutes after learning the loop;
- hatchling control should feel substantially weaker than adult control for at least the first growth phase;
- no single second-generation direction should dominate all four of hunter/weaver/armored/proto-morph metrics.

Adjust only `.tres` data values and named constants; do not introduce special-case difficulty cheats.

- [ ] **Step 5: Perform the 0.1 design acceptance playtest**

Record pass/fail notes in `README.md` under `0.1 Vertical Slice Acceptance` for all eight spec success criteria:

1. weak spider is enjoyable before advanced evolution;
2. webs/hunting/hiding/injury/feeding create decisions;
3. offspring feel meaningfully different;
4. daughter selection changes play;
5. hatchling creates different pressures/history;
6. former player NPC behavior reflects prior play;
7. side-view presentation makes evolution legible;
8. lineage survives several generations without excluded future systems.

A criterion only passes when observed in a playable run, not merely because a unit test passes.

- [ ] **Step 6: Verify explicit exclusions stayed excluded**

Search the codebase and confirm there are no implemented systems for procedural magic, Legacy Library, historical world simulation, large colony jobs, firearms, full technology trees, or multi-region faction geopolitics. Data structures may reserve stable IDs/interfaces, but no runtime behavior for these systems belongs in 0.1.

- [ ] **Step 7: Final verification**

Run:

```bash
git status --short
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --quit-after 3
```

Expected: working tree contains only intentional acceptance-note/balance changes; all tests PASS; smoke boot succeeds.

- [ ] **Step 8: Commit**

```bash
git add README.md content src tests
git commit -m "feat: complete Monster Lineage Sandbox 0.1 vertical slice"
```

---

## Implementation Order and Review Gates

The task order is mandatory because later interfaces depend on earlier pure-data boundaries. After each task, review the diff before starting the next task. Reject any change that moves player-facing strings into simulation code, introduces per-hybrid character subclasses, lets scene nodes become the authoritative store of creature state, or adds excluded future systems “for convenience.”

Recommended execution grouping if using batch execution:

1. Tasks 1–4: project/data foundations.
2. Tasks 5–8B: immediate spider survival gameplay, with the Task 8A review gate before Task 8B integration.
3. Tasks 9–11: nest, reproduction, lineage transfer.
4. Tasks 12–13: presentation and vertical-slice acceptance.

## Definition of Done for 0.1

0.1 is complete only when all of the following are true in the same build:

- `godot --headless --path . --script res://tests/run_all.gd` exits `0`;
- the project boots without parser/import errors;
- the player can survive and hunt as a weak spider using webs, bite, venom, terrain, and feeding;
- one nest can be claimed;
- one social/reproductive path can produce a clutch;
- offspring are reproducibly generated yet meaningfully diverse;
- any living daughter, including a hatchling, can become the controlled creature;
- the former controlled body remains in-world and behaves from learned state;
- controlled death can fall back to another eligible living relative;
- body/nest/lineage screens make generational differences legible;
- Ukrainian UI/localized procedural names work and runtime locale switching does not alter semantic IDs;
- the lineage can reach at least generation 3 in a manual run without any system excluded by section 36.2 of the design spec.
