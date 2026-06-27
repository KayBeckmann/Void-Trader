import 'dart:math';
import '../domain/star_system.dart';

class SystemGenerator {
  final Random _rng;

  SystemGenerator({int? seed}) : _rng = Random(seed);

  StarSystem generate({
    required String id,
    required SystemTier tier,
    required List<String> connectedSystemIds,
  }) {
    final name = _generateName(id);
    final planetCount = tier == SystemTier.outer ? _rng.nextInt(2) + 1 : _rng.nextInt(3) + 2;
    final hasAsteroids = tier != SystemTier.outer || _rng.nextBool();
    final faction = tier == SystemTier.outer ? 'npc.pirate' : _randomFrontierFaction();

    final planets = List.generate(planetCount, (i) => _generatePlanet(id, i, tier, faction));
    final asteroidFields = hasAsteroids ? [_generateAsteroidField(id)] : <AsteroidField>[];
    final jumpGates = connectedSystemIds
        .take(4)
        .toList()
        .asMap()
        .entries
        .map((e) => _generateGate(id, e.value, e.key, connectedSystemIds.length))
        .toList();

    return StarSystem(
      id: id,
      name: name,
      tier: tier,
      procedural: true,
      ownerFaction: tier == SystemTier.outer ? 'npc.none' : faction,
      planets: planets,
      asteroidFields: asteroidFields,
      jumpGates: jumpGates,
    );
  }

  Planet _generatePlanet(String systemId, int index, SystemTier tier, String faction) {
    final angle = _rng.nextDouble() * 2 * pi;
    final dist = 300.0 + _rng.nextDouble() * 600.0;
    final typeList = tier == SystemTier.outer
        ? ['mining', 'colony']
        : ['industrial', 'trade', 'colony', 'habitat', 'mining'];
    final type = typeList[_rng.nextInt(typeList.length)];
    final r = 35.0 + _rng.nextDouble() * 45.0;
    return Planet(
      id: '$systemId.p$index',
      name: '${_syllable()}${_syllable()} ${['Alpha', 'Beta', 'Prime', 'Station', 'Outpost'][_rng.nextInt(5)]}',
      type: type,
      x: dist * cos(angle),
      y: dist * sin(angle),
      radius: r,
      ownerFaction: tier == SystemTier.outer ? 'npc.none' : faction,
    );
  }

  AsteroidField _generateAsteroidField(String systemId) {
    final angle = _rng.nextDouble() * 2 * pi;
    final dist = 700.0 + _rng.nextDouble() * 400.0;
    return AsteroidField(
      id: '$systemId.belt',
      x: dist * cos(angle),
      y: dist * sin(angle),
      radius: 200.0 + _rng.nextDouble() * 300.0,
      richness: 0.2 + _rng.nextDouble() * 0.7,
    );
  }

  JumpGate _generateGate(String systemId, String targetId, int index, int total) {
    final angle = (2 * pi * index / total) + _rng.nextDouble() * 0.4;
    const dist = 1300.0;
    return JumpGate(
      id: '$systemId.gate_$targetId',
      targetSystemId: targetId,
      owner: 'npc.unknown',
      x: dist * cos(angle),
      y: dist * sin(angle),
    );
  }

  String _randomFrontierFaction() =>
      ['npc.consortium', 'npc.guild', 'npc.militia', 'npc.free'][_rng.nextInt(4)];

  String _generateName(String id) {
    return '${_syllable().toUpperCase()}${_syllable()}-${id.hashCode.abs() % 900 + 100}';
  }

  String _syllable() {
    const consonants = 'bcrdfghjklmnprstvwxz';
    const vowels = 'aeiou';
    final c = consonants[_rng.nextInt(consonants.length)];
    final v = vowels[_rng.nextInt(vowels.length)];
    return '$c$v';
  }
}
