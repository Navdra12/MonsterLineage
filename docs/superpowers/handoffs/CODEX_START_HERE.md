# Codex execution handoff — Monster Lineage Sandbox 0.1

## Required context

Read these files first, in order:

1. `docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md`
2. `docs/superpowers/plans/2026-09-14-v0-1-vertical-slice.md`
3. This file.

The design spec is authoritative. The implementation plan is the execution contract for 0.1.

## Environment

- Godot 4.7.2 stable Standard build must be installed and available as `godot` on PATH.
- GDScript only.
- Work in isolated Git worktrees. Never implement directly on `master`.
- Use strict TDD: failing test -> observe correct failure -> minimal implementation -> passing test -> commit.
- Run after every task:

```bash
godot --headless --path . --script res://tests/run_all.gd
godot --headless --path . --quit-after 2
```

## Superpowers / Codex setup

Use the Superpowers skills. Prefer `subagent-driven-development` when multi-agent support is enabled.

Codex multi-agent support can be enabled in `~/.codex/config.toml`:

```toml
[features]
multi_agent = true
```

Do not invent model identifiers. Inspect the current Codex model/preset allowlist first.

For every spawned worker explicitly set both model and reasoning effort.

## Model routing

Use the strongest available coding/reasoning preset (Astra if it is available in this Codex session) for:

- Task 3: body plans, traits, species, genome data model — **High reasoning**
- Task 7/8 integration where web, combat and AI meet — **High reasoning**
- Task 10: reproduction and offspring generation — **High reasoning**
- Task 11: lineage and irreversible generation transfer — **High reasoning**
- Task 13: full vertical-slice integration and final review — **High reasoning**

Use a faster standard coding model for mechanical/scaffold tasks:

- Task 1: bootstrap/test harness — **Medium reasoning**
- Task 2: localization/naming foundation — **Medium reasoning**
- Task 4: individual state containers — **Medium reasoning**
- simple UI/resource authoring and deterministic smoke tests — **Medium reasoning**

Escalate to the strongest preset when a task becomes cross-cutting or a fix loop reaches repeated failures.

## First execution wave

### Gate: Task 1 must complete first

Implement **Task 1 exactly as written in the implementation plan**. Do not start later production code before its headless tests and smoke boot pass.

Commit expected:

```text
chore: bootstrap Godot 0.1 project and test harness
```

### After Task 1, parallelize Task 2 and Task 3

Create two worktrees from the Task 1 commit.

**Worker A — Task 2**

- Scope: localization + semantic procedural naming only.
- Recommended model: fast/standard coding model.
- Reasoning: Medium.
- Do not touch genetics files.

**Worker B — Task 3**

- Scope: body plans + 12 traits + six prototype species + genome model only.
- Recommended model: strongest available coding preset / Astra if available.
- Reasoning: High.
- Do not touch localization/naming files.

Both tasks currently add their test suite to `tests/run_all.gd`; this is the expected small integration conflict. Preserve both registrations during merge.

Review each task against the spec and plan before integration. Do not accept a task merely because tests pass.

## Controller prompt

Use this as the controller instruction after opening the repository:

> Execute the approved `Monster Lineage Sandbox 0.1 Vertical Slice Implementation Plan` using Superpowers. Read the design spec first; it is authoritative. Use strict TDD and isolated worktrees. Complete Task 1 first and verify both the full headless suite and smoke boot. After Task 1, dispatch Task 2 and Task 3 in parallel worktrees. Route Task 3 to the strongest available coding preset (Astra if present) with High reasoning; route Task 2 to a faster standard coding preset with Medium reasoning. Explicitly set model and reasoning effort for every worker. Review each task for spec compliance and code quality before integrating it. Resolve the expected `tests/run_all.gd` conflict by keeping both suites. Do not implement features outside the 0.1 plan.

## Stop conditions

Stop and report rather than guessing if:

- Godot is not exactly 4.7.2 stable or cannot execute headlessly;
- the RED test cannot be observed failing for the intended missing behavior;
- a task requires changing an approved interface from the plan;
- a destructive, shared-branch, publish, or push operation is required.
