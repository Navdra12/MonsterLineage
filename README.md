# Monster Lineage Sandbox

Monster Lineage Sandbox 0.1 targets Godot **4.7.2 stable Standard**. Version 0.1 is the generation-loop vertical slice described by the approved [Monster Lineage Sandbox design specification](docs/superpowers/specs/2026-09-14-monster-lineage-sandbox-design.md): it establishes the playable foundation for surviving as one creature, reproducing, and continuing through descendants without implementing the later large-scale simulation.

Run the headless test suite:

```powershell
godot --headless --path . --script res://tests/run_all.gd
```

Smoke-boot the project:

```powershell
godot --headless --path . --quit-after 2
```
