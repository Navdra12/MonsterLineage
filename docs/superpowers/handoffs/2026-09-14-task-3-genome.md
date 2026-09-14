# Task 3 — genome and biological content

Scope: Task 3 of the approved 0.1 plan, based on Task 1 commit `36ca477`.

## Ownership and extension boundaries

- `SpeciesDef` is a shared biological template, not a character. It references a
  `BodyPlanDef` and a baseline `Genome`, plus cognition, diet and reproduction tags.
  Treat authored resources as read-only. Create each individual's inherited data
  with `species.base_genome.clone_genome()`; never mutate the shared baseline.
- `BodyPlanDef` supplies stable part IDs, movement capabilities and traversal size.
  Trait values modify relevant structures; a nonzero value does not create a
  missing organ or grant a movement capability. For example, mothling wing parts
  and membrane potential do not enable flight in 0.1.
- `Genome` stores a body-plan ID and numeric trait values. Its dictionary uses
  `StringName` keys and float values, preventing nested mutable values from
  compromising clone isolation. Missing traits read as zero expression. Definitions
  clamp expressed values; Genome neither clamps nor knows the prototype trait list.
  Non-web species omit web traits rather than receiving artificial web organs or
  storing zero outside an expressed trait's positive range.
- `TraitDef` owns numeric ranges, mutation sigma and inheritance weight. The twelve
  authored traits use the exact planned ranges; sigma `0.08` and weight `1.0` are
  initial content settings, not an implemented inheritance algorithm.
- Individual condition, age, injuries, personality and knowledge remain outside
  these resources. Task 3 adds no individual-state containers or lifecycle logic.
  Body-plan identity is assigned when forming a genome. Adult gameplay must keep
  it fixed; future descendant formation may choose another plan. This task does
  not implement either adult transformation or descendant body-plan replacement.
- Neither the genome nor species class assumes arachnid parts, egg stages, molts,
  binary parentage or a universal age curve. A new stable morphology uses the same
  resource classes with different data. Future lifecycle rules belong alongside
  species biology, without adding lifecycle state to the genome.

Content consists of six body plans, twelve traits and six species. Spider and
mothling share `prototype_clutch`; scarabkin and newt have separate compatibility
tags. Empty cricket/frog reproduction tags exclude them from prototype reproduction,
not from biological reproduction in the eventual ecosystem. No compatibility
algorithm, offspring generator or evolution-direction classifier is implemented.
Species display keys match Task 2's `species.<id>` catalog contract; localization
files remain Task 2's responsibility.

## TDD evidence

All RED runs below used the complete suite and exited `1` before the corresponding
implementation/fix. The subsequent GREEN runs reported `PASS: 2 suite(s)`, exit `0`.

1. Genome storage/clone: `Genome resource class must exist` (1 failed assertion).
   Implemented scalar storage, zero for absent traits, and independent clone data.
2. Trait clamping: `TraitDef resource class must exist` (1 failed assertion).
   Implemented definition-owned clamping, including boundaries and custom ranges.
3. Authored content: `traits authored resource count (actual: 0, expected: 12)` and
   missing body/species resources (28 failed assertions total). Authored the resource
   classes and 24 assets; checked references, values, biases and composition.
4. Fresh-checkout regression: removing the generated global class cache exposed
   unresolved `Genome`/`BodyPlanDef` references. Script-instantiation assertions
   made this an explicit failing suite (8 failed assertions). Explicit dependency
   preloads and script-based clone construction fixed loading without editor state.
5. Review regression: all six species keys failed the planned locale-catalog
   contract, e.g. `actual: SPECIES_PLAYER_SPIDER, expected: species.player_spider`.
   Corrected the six resource keys; suite returned GREEN.

One preliminary test parse error used the reserved identifier `trait`; it was
corrected before recording the intended trait-clamping RED.

## Verification and review

Engine: Godot `4.7.2.stable.official.ed1daf0bf`, Standard build.

```powershell
godot --headless --path . --editor --quit | Out-Host
godot --headless --path . --script res://tests/run_all.gd | Out-Host
godot --headless --path . --quit-after 2 | Out-Host
```

`Out-Host` makes PowerShell wait for the Windows GUI executable and populate
`$LASTEXITCODE`. The complete suite passes both with and without the generated
class cache. Import and main-scene smoke checks exit `0` without engine/script
errors when run with normal user-log and Windows certificate-store access.

An independent read-only architecture/code review found the species localization
key mismatch above and no other actionable Task 3 issues. The mismatch was fixed
with a regression test.

No approved interface or scope deviation. The additional fresh-checkout regression,
resource-script checks and this handoff document support reliable integration.
Task 4 and later systems remain unimplemented.
