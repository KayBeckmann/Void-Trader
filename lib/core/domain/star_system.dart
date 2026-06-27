enum SystemTier { core, frontier, outer }

class JumpGate {
  final String id;
  final String targetSystemId;
  final String owner; // "npc.consortium" | "player" | "npc.guild"
  final double x;
  final double y;

  const JumpGate({
    required this.id,
    required this.targetSystemId,
    required this.owner,
    required this.x,
    required this.y,
  });

  factory JumpGate.fromJson(Map<String, dynamic> j) => JumpGate(
        id: j['id'] as String,
        targetSystemId: j['target_system'] as String,
        owner: j['owner'] as String? ?? 'npc.unknown',
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
      );
}

class AsteroidField {
  final String id;
  final double x;
  final double y;
  final double radius;
  final double richness; // 0–1

  const AsteroidField({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.richness,
  });

  factory AsteroidField.fromJson(Map<String, dynamic> j) => AsteroidField(
        id: j['id'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        radius: (j['radius'] as num?)?.toDouble() ?? 300.0,
        richness: (j['richness'] as num?)?.toDouble() ?? 0.5,
      );
}

class Planet {
  final String id;
  final String name;
  final String type; // industrial | trade | colony | habitat | mining
  final double x;
  final double y;
  final double radius;
  final String ownerFaction;
  final bool isPlayerBase;

  const Planet({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.radius,
    required this.ownerFaction,
    this.isPlayerBase = false,
  });

  factory Planet.fromJson(Map<String, dynamic> j) => Planet(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String? ?? 'habitat',
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        radius: (j['radius'] as num?)?.toDouble() ?? 60.0,
        ownerFaction: j['owner_faction'] as String? ?? 'npc.unknown',
        isPlayerBase: j['is_player_base'] as bool? ?? false,
      );
}

class StarSystem {
  final String id;
  final String name;
  final SystemTier tier;
  final bool procedural;
  final String ownerFaction;
  final List<Planet> planets;
  final List<AsteroidField> asteroidFields;
  final List<JumpGate> jumpGates;

  const StarSystem({
    required this.id,
    required this.name,
    required this.tier,
    required this.procedural,
    required this.ownerFaction,
    required this.planets,
    required this.asteroidFields,
    required this.jumpGates,
  });

  factory StarSystem.fromJson(Map<String, dynamic> j) => StarSystem(
        id: j['id'] as String,
        name: j['name'] as String,
        tier: SystemTier.values.firstWhere(
          (t) => t.name == j['tier'],
          orElse: () => SystemTier.frontier,
        ),
        procedural: j['procedural'] as bool? ?? true,
        ownerFaction: j['owner_faction'] as String? ?? 'npc.unknown',
        planets: (j['planets'] as List<dynamic>? ?? [])
            .map((p) => Planet.fromJson(p as Map<String, dynamic>))
            .toList(),
        asteroidFields: (j['asteroid_fields'] as List<dynamic>? ?? [])
            .map((a) => AsteroidField.fromJson(a as Map<String, dynamic>))
            .toList(),
        jumpGates: (j['jump_gates'] as List<dynamic>? ?? [])
            .map((g) => JumpGate.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}
