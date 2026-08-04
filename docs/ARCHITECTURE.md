# Void Trader — Architektur (Reboot)

Stack: Flutter + Flame + Dart-Core. Entwicklung ausschließlich containerisiert
(siehe docker/, compose.yml) — kein Flutter/Dart auf dem Host.

## Struktur

```
apps/
  void_trader/        Flutter-App + Flame-Szenen
packages/
  vt_core/             reine Dart-Simulation
  vt_world/            Weltgeneration, Tiles, Ebenen, Biome
  vt_physics/          Oberfläche: Fluid/Druck/Temperatur/Solid-State
  vt_npc/              NPC-Zustände, Bedürfnisse, Arbeit, Tagesabläufe
  vt_drones/           Drohnenlogik: Tasks, Autonomie, Steuerung, Flotten
  vt_content/          Startdaten/Balancing
assets/
  pixel-art/
docs/
  design/              Stitch-Mockups als UI-Vorlage (siehe DESIGN.md)
```

Details zur Rollenverteilung: siehe Vault-Notizen
Framework_Vermerk_Dart_Flutter_Flame_2026-08-04 und
Roadmap_Reboot_Planetenoberflaeche_2026-08-04.
