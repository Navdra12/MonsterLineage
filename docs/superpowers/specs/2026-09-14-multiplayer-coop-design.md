# MonsterLineage — Multiplayer / Co-op Design Specification

Date: 2026-09-14
Status: Approved design specification; implementation planning not started

## 1. Purpose and scope

MonsterLineage should support private co-op as a long-term project direction, primarily for two players sharing one persistent sandbox world while each directly controls a creature and maintains a separate lineage.

The first multiplayer target is two players. The internal architecture must not hard-code `player1` / `player2`; it should use a collection of player slots so support can later increase to 3–4 players without replacing the ownership or networking model.

Multiplayer is not part of the current v0.1 acceptance scope. v0.1 remains a single-player vertical slice, but new simulation code must avoid assumptions that make future multiplayer expensive to add.

A future skirmish mode may reuse the same networking, creature-control, combat, replication, and timing foundations with different session rules.

## 2. Core networking model

Multiplayer is host-authoritative.

The host is authoritative for:

- `WorldState`
- `WorldClock`
- important RNG and generated events
- AI decisions
- combat outcomes
- genetics and offspring generation
- creature ownership
- lineage transitions
- saves and save revisions
- global slowdown and pause

Clients send input and requests, not authoritative gameplay results. The host validates, simulates, updates authoritative state, and replicates the result to relevant peers.

Client prediction may be used for the local player's movement. Remote entities are primarily interpolated between authoritative updates.

Conceptual structure:

```text
MultiplayerSession
├── WorldState
├── WorldClock
├── SaveService
├── NetworkSession
├── PlayerRegistry
│   ├── PlayerSlot
│   ├── PlayerSlot
│   └── ...
├── LineageRegistry
└── ZoneSimulationManager
```

A `PlayerSlot` should contain stable ownership/session data such as:

```text
player_profile_id
player_slot_id
controlled_creature_id
lineage_id
current_zone_id
connection_state
disconnect_mode
freeze_lock
```

## 3. Creatures, players, and lineages

A creature is a simulation entity, not a player object.

`CreatureState` must remain valid whether the creature is controlled by a human, controlled by AI, temporarily uncontrolled, or a former player creature that became an NPC.

Player ownership is external to creature state.

Each player has a separate `PlayerSlot` and separate `PlayerLineage`.

Biological ancestry is tracked independently from player progression:

- `FamilyGraph` — biological parent/child history in the world;
- `PlayerLineage` — the generational branch associated with one player slot.

Two player lineages may share ancestors or descendants without merging ownership.

A creature may have at most one active player controller.

## 4. First join and lineage creation

When a new player first joins an existing world, two entry paths are supported.

### 4.1 New lineage

The player creates a new starting creature and begins a separate lineage. The creature appears reasonably near the host, but not necessarily directly beside them.

### 4.2 Branch from host family

The player may choose an eligible descendant or relative of the host's family. That creature becomes the starting point of the joining player's own `PlayerLineage`.

Biological ancestry with the host's family remains intact, but future player lineage ownership remains separate.

An already controlled or reserved creature cannot be claimed.

## 5. Shared offspring and lineage transitions

A child of two player-controlled creatures exists only once in the world and belongs biologically to both parents.

Shared offspring are not automatically owned by either player. If one is eligible for both lineages, both players may see it as a candidate until one player successfully reserves it.

If both players try to claim the same descendant at nearly the same time, the host should not resolve ownership purely by network latency. The candidate enters a claim-conflict state and the players resolve it explicitly.

A lineage-transition candidate must be alive, biologically eligible, not controlled by another player, not reserved by another active player, and valid under the species/lifecycle rules.

If a player changes generation while the previous creature remains alive, the previous creature becomes an autonomous NPC and preserves its personality, preferences, memories, relationships, food memory, and history.

The world may also retain `control_history` for creatures.

## 6. Death and lineage extinction

If a controlled creature dies, the player's slot enters a lineage-transition state.

If eligible descendants exist, the player selects one and continues through it.

If no eligible descendants exist and the lineage is extinct, the player may start a new `PlayerLineage` in the same persistent world.

The old lineage remains part of world history and is marked extinct rather than deleted.

The death or extinction of one player's lineage does not reset the world or another player's lineage.

## 7. Session lifecycle and connectivity

A multiplayer session always has one host.

The project should support two connection paths over time:

- LAN / direct IP connection;
- invite / relay connection for easier internet play.

Gameplay systems must not depend directly on the transport implementation.

```text
Gameplay / Simulation
        ↓
NetworkSession
        ↓
Transport interface
        ├── LAN / ENet
        ├── Direct Internet
        └── Future Relay / Platform
```

The first practical networking milestone may begin with LAN/direct connection. Invite/relay support can be added later.

The design supports drop-in / drop-out play without restarting the world.

## 8. Disconnect modes

A player leaving normally can choose `AI` or `Frozen`.

### AI

The creature remains active and AI takes control. The player slot retains ownership.

AI may perform normal survival behavior such as eating, fleeing, defending itself, sleeping, and moving, but must not make irreversible player-level decisions such as transferring ownership, deleting a lineage, or selecting a generational successor.

If the AI-controlled creature is injured, moved, or killed while the player is away, that result is real.

### Frozen

If the player explicitly chooses Frozen:

```text
disconnect_mode = FROZEN
freeze_lock = true
```

The creature is removed from active simulation, remains reserved for its player slot, does not age, hunger, take damage, reproduce, or receive AI control, and cannot be claimed by another player.

If `freeze_lock = true`, the host cannot override the player's choice and switch the creature to AI.

## 9. Reconnect behavior

Short connection loss first enters a reconnect grace period.

```text
CONNECTED
↓
RECONNECTING
↓
DISCONNECTED_AI
or
DISCONNECTED_FROZEN
```

If reconnection succeeds, live control resumes. If not, the stored/default disconnect policy is applied.

A frozen creature first attempts to return at its exact saved disconnect location.

Fallback relocation is used only if the original point is invalid, inaccessible, inside objectively lethal terrain or an unavoidable lethal environmental hazard, or its zone cannot be loaded.

Fallback order:

```text
exact disconnect point
↓
nearest valid point in same local area
↓
nearest safe point in same zone
↓
known safe shelter / spawn fallback
```

A nearby predator alone is not enough to trigger relocation. This is recovery, not free fast travel.

## 10. Player identity

Each player has a stable local `player_profile_id`.

A live session may additionally issue temporary values such as:

```text
session_peer_id
reconnect_token
player_slot_id
```

The temporary token supports reconnect inside a session. The stable profile identity locates the player's existing slot in a saved world.

If the profile identity is lost because of another PC or reinstall, the host can manually reassign the old slot.

Duplicate simultaneous connections for the same profile are rejected by default.

## 11. Global time, slowdown, and pause

The world has one authoritative `WorldClock` containing at least:

```text
simulation_tick
time_scale
paused
```

No client or zone may advance authoritative simulation beyond the host's global tick.

All active zones exist in the same timeline.

Slowdown is the primary tactical time-control mechanic. Any connected player may request global slowdown; the host applies and replicates the authoritative `time_scale`.

Any connected player may request full global pause. Pause stops simulation time for the whole world while UI, menus, chat, and network heartbeat may continue operating.

The initial private co-op design does not require voting for slowdown or pause.

## 12. Multi-zone simulation

Players should eventually be able to occupy different active zones. Each `PlayerSlot` therefore has its own `current_zone_id`.

The zone system should conceptually support:

```text
HOST_LOCAL
DELEGATED_WORKER
BACKGROUND_COARSE
SUSPENDED
```

`HOST_LOCAL` is full active simulation on the host.

`DELEGATED_WORKER` is future client-assisted zone computation while the host remains authoritative.

`BACKGROUND_COARSE` is cheaper aggregate simulation for distant regions.

`SUSPENDED` is stored state that currently does not need active simulation.

The first multiplayer implementation does not need delegated simulation. It may begin with host-local active zones and coarse background simulation.

## 13. Future delegated simulation

Delegated simulation is an optimization path, not an initial requirement.

If profiling later shows that multiple active zones overload the host, the host may assign bounded zone work to a client.

A work package may include:

```text
zone_id
start_tick
target_tick
zone_snapshot
relevant_commands
rng_context
```

The worker may return:

```text
computed_until_tick
state_delta
generated_events
validation_metadata
```

The worker is not authority. The host controls the target tick, accepts or rejects results, retains final world state, and can reassign work.

A worker never advances authoritative world time beyond the assigned target tick.

If a worker disconnects, uncommitted worker results are discarded and the host resumes from the last authoritative zone revision.

Delegated simulation should be disabled for future competitive/skirmish sessions unless a stronger trusted-server model exists.

## 14. Cross-zone interactions

Zones should not directly mutate one another.

Cross-zone effects flow through authoritative world-level events.

```text
Zone A
  ↓
MigrationEvent
  ↓
WorldState / ZoneSimulationManager
  ↓
Zone B
```

This keeps zone simulation portable between host-local, delegated, coarse, and suspended modes.

## 15. Save ownership and replicated recovery copies

During a live session, the current host owns the authoritative save state.

Confirmed recoverable save revisions are also replicated to all connected players as non-authoritative backups.

A backup may later be promoted to authoritative when that player hosts the world.

This supports manual save transfer and recovery after crashes, internet failure, or power loss.

## 16. Save identity and revisioning

Each shared world save should contain metadata including:

```text
save_id
branch_id
revision
parent_revision
created_at
updated_at
checksum
format_version
game_version
```

`revision` increases after confirmed checkpoints.

`branch_id` and `parent_revision` detect divergent timelines.

If two players independently continue the same older revision, the game does not attempt to merge the histories automatically. It detects divergence and asks which branch to continue.

## 17. Checkpoints and save structure

The future save model combines periodic full snapshots with small incremental deltas and compaction.

```text
WorldSave/
├── metadata
├── latest_full_snapshot
├── recent_deltas
├── previous_snapshot_1
└── previous_snapshot_2
```

A normal background checkpoint targets roughly every 10 seconds, but this does not mean rewriting the whole world every 10 seconds.

Important events trigger immediate checkpoints, including controlled-creature death, birth, lineage transition, new-lineage creation, lineage extinction, zone transition, important creature claim, major structural world events, player exit, and normal session shutdown.

Full snapshots occur less often based on profiling, world size, and structural changes.

Old deltas are compacted so save size does not grow indefinitely simply because playtime is long.

## 18. Save performance and atomic writes

The save system must not serialize the live Godot scene tree directly on a background thread.

The simulation layer first captures a consistent data snapshot. Expensive serialization, compression, and disk writing may then occur asynchronously on safe data.

Writes are atomic:

```text
temporary file
↓
write
↓
checksum validation
↓
atomic replace / rename
↓
new revision becomes valid
```

A power loss during a write must leave the previous confirmed revision intact.

At least the latest three valid recovery points should be retained locally.

## 19. Backup replication and host failure

After the host commits a valid checkpoint, the new revision is replicated to connected clients as a non-authoritative backup.

Normal transfer should prefer deltas when possible. Full snapshots are sent when needed, such as first sync, large lag, compaction, or recovery.

If the host disappears:

```text
host connection lost
↓
session simulation stops
↓
no live host migration
↓
clients preserve latest valid backup
↓
return to recovery/session screen
```

Clients do not continue authoritative simulation independently.

On restart, the game compares copies of the same `save_id` and identifies the newest valid compatible revision. A player holding that copy may host the recovered world.

## 20. Network replication and interest management

The host does not replicate the entire world every frame.

Each client receives only a relevant `interest set`, normally including its current zone, nearby/visible areas, nearby creatures, combat state, required co-op state, relevant global events, and explicitly tracked entities.

Stable simulation `entity_id` values are authoritative. Local Godot `NodePath` or instance IDs are not network identity.

Replication uses state deltas and different update frequencies for different categories. Exact network rates are profiling decisions.

## 21. Prediction, interpolation, and authority boundaries

The local player's movement may be predicted immediately.

Clients maintain a short ordered input history. The host acknowledges processed inputs, and the client reconciles remaining unacknowledged input over authoritative state.

Remote creatures and NPCs are primarily interpolated between authoritative updates.

Clients may own purely local presentation state such as camera, UI, graphics settings, audio settings, keybinds, and local menus.

Gameplay-affecting results remain host-authoritative.

For combat, the client requests an attack; it does not declare damage.

For reproduction, the client requests the action; the host performs authoritative RNG and offspring generation.

For zone transfer, the client requests movement; the host validates and performs the transfer transaction.

## 22. Reliable and transient network events

Transient high-frequency state such as position and velocity may use unreliable ordered delivery because newer updates replace older ones.

Important events require reliable delivery, including birth, death, inventory transactions, lineage transitions, creature claims, zone transfers, pause state, save revisions, entity creation/destruction, and system/chat messages.

Short packet loss should not immediately disconnect a player. During a brief interruption the client may continue local movement prediction, UI, and animation, but may not independently confirm authoritative gameplay outcomes.

## 23. Friendly fire and session rules

Persistent co-op uses explicit `SessionRules`.

Representative fields include:

```text
mode
friendly_fire
max_players
allow_new_lineages
allow_family_branch_join
allow_pause_requests
allow_slowdown_requests
```

The campaign mode is `COOP_SANDBOX`.

Friendly fire is disabled by default. When disabled, player-controlled creatures cannot directly damage one another through normal attacks. When enabled, normal combat consequences apply between players.

The host can configure session-level rules, but host privileges do not override personal ownership protections such as another player's protected Frozen state.

Dangerous rule changes during a live session, such as enabling friendly fire, should be announced before taking effect.

## 24. Future skirmish

A future skirmish mode should reuse the multiplayer foundation rather than create a second networking stack.

Skirmish rules may later define teams, spawn rules, victory conditions, time limits, resources, respawn rules, and mandatory PvP.

It can reuse `NetworkSession`, `PlayerSlot`, creature control, combat, replication, `WorldClock`, and zone simulation.

Competitive/skirmish sessions may disable delegated simulation and use stricter validation than private co-op.

The project does not currently need a complex role hierarchy; `HOST` and `PLAYER` are sufficient.

## 25. Implementation boundaries for current development

This design changes architectural constraints now, but does not add multiplayer implementation to v0.1.

### Task 4

Task 4 should implement `CreatureState` as multiplayer-safe simulation data.

`CreatureState` should contain creature-specific state such as:

```text
creature_id
genome
needs
injuries
personality
food_memory
memory_log
```

It must not embed:

```text
player_number
network_peer_id
input
camera
UI
multiplayer transport
```

A creature's biological and simulation state must remain independent of the current controller.

### Later simulation tasks

Combat, reproduction, lineage, zone, and world systems should use stable IDs and explicit context rather than assuming exactly one player.

Reproduction creates world offspring. Ownership and lineage systems separately determine who may later claim or transition into those offspring.

Time control should converge toward one authoritative service rather than allowing unrelated systems to mutate global time scale independently.

### What not to build yet

Do not create unused multiplayer infrastructure solely for future use.

v0.1 does not need live networking, relay services, replicated saves, delegated workers, skirmish, or host migration.

## 26. Rollout

The intended rollout is:

1. Complete the v0.1 single-player vertical slice using multiplayer-safe simulation boundaries.
2. Add a Multiplayer Foundation milestone with `PlayerSlot`, `PlayerRegistry`, `NetworkSession`, stable network entity IDs, host-authoritative input, LAN/direct connection, two players, drop-in/drop-out, and reconnect.
3. Add Multiplayer Persistence with save/load, snapshots/deltas, replicated backups, crash/power-loss recovery, and manual host change through save ownership transfer.
4. Add Multi-zone Co-op where players may occupy different active zones while the host initially computes all active zones.
5. Add delegated zone simulation only if profiling proves it is needed.
6. Add invite/relay connectivity.
7. Add optional skirmish/session modes later.

## 27. Compatibility with existing project decisions

This specification preserves the current project principles: direct creature control, generational evolution, data-driven biology, separation of shared definitions from runtime state, deterministic seeded RNG, scene-independent simulation data where practical, headless testability, v0.1 as a limited vertical slice, and no save/load requirement inside v0.1 itself.

The new architectural constraint is that future simulation code must not assume one globally unique player entity.

## 28. Approved outcome

This specification is approved as the long-term multiplayer/co-op direction.

It does not authorize immediate implementation of the full multiplayer subsystem.

The next implementation step remains Task 4 of the existing v0.1 plan, adjusted so `CreatureState` and related simulation data do not embed single-player-only ownership assumptions.
