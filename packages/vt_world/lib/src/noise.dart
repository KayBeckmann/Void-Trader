/// Deterministische, seed-basierte 2D-Value-Noise für Höhen-, Feuchtigkeits-
/// und Temperaturkarten (Roadmap Phase 2: prozedurale Weltgeneration).
///
/// Bewusst kein Perlin-/Simplex-Noise: Value-Noise mit Smoothstep-
/// Interpolation ist einfach, hat keine externen Abhängigkeiten und liefert
/// für Void Traders Zwecke (grobe Biom-/Höhlenverteilung) ausreichend
/// natürlich wirkende Ergebnisse.
class ValueNoise2D {
  final int seed;

  const ValueNoise2D(this.seed);

  /// Liefert einen deterministischen, geglätteten Wert in `[0, 1)` für die
  /// gegebene (kontinuierliche) Koordinate.
  double sample(double x, double y) {
    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final sx = _smooth(x - x0);
    final sy = _smooth(y - y0);

    final n00 = _latticeValue(x0, y0);
    final n10 = _latticeValue(x1, y0);
    final n01 = _latticeValue(x0, y1);
    final n11 = _latticeValue(x1, y1);

    final ix0 = _lerp(n00, n10, sx);
    final ix1 = _lerp(n01, n11, sx);
    return _lerp(ix0, ix1, sy);
  }

  double _smooth(double t) => t * t * (3 - 2 * t);

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _latticeValue(int x, int y) {
    final h = _hash(x, y) & 0xFFFFFF;
    return h / 0xFFFFFF;
  }

  /// Bewusst KEIN `Object.hash(seed, x, y)`: Dart mischt dort einen pro
  /// Isolate zufälligen Seed ein (Schutz vor Hash-Flooding-Angriffen auf
  /// Hash-Maps), der bei jedem Programmstart anders ausfällt. Für uns hieße
  /// das: derselbe Welt-Seed erzeugt bei jedem Neustart eine andere Welt —
  /// ein Bruch des in dieser Klasse dokumentierten Kernversprechens
  /// "gleicher Seed erzeugt immer denselben Inhalt". Innerhalb eines
  /// einzelnen Programmlaufs bleibt `Object.hash` stabil (deshalb ist der
  /// Bug lange unbemerkt geblieben), zwischen zwei Läufen aber nicht — siehe
  /// Bautagebuch-Eintrag zu diesem Fund. Stattdessen ein reiner, prozess-
  /// unabhängiger Ganzzahl-Mix (MurmurHash3-Finalizer-artig, zweimal
  /// angewendet für x und y).
  int _hash(int x, int y) {
    var h = (0x811c9dc5 ^ seed) & 0xFFFFFFFF;
    h = _mixIn(h, x);
    h = _mixIn(h, y);
    return h & 0x7FFFFFFF;
  }

  int _mixIn(int h, int value) {
    h = (h ^ value) & 0xFFFFFFFF;
    h = (h * 0x85ebca6b) & 0xFFFFFFFF;
    h = (h ^ (h >> 13)) & 0xFFFFFFFF;
    h = (h * 0xc2b2ae35) & 0xFFFFFFFF;
    h = (h ^ (h >> 16)) & 0xFFFFFFFF;
    return h;
  }
}

/// Ein für Weltkoordinaten skalierbares Noise-Feld.
///
/// [scale] steuert die "Zoomstufe": größere Werte erzeugen großflächigere,
/// sanftere Übergänge, kleinere Werte kleinteiligere Muster.
class NoiseField {
  final ValueNoise2D _noise;
  final double scale;

  NoiseField({required int seed, this.scale = 32})
    : assert(scale > 0, 'scale muss positiv sein'),
      _noise = ValueNoise2D(seed);

  /// Wert in `[0, 1)` für eine Welt-Tile-Koordinate. [zOffset] erlaubt es,
  /// pro z-Ebene ein anderes (aber weiterhin deterministisches) Muster aus
  /// demselben Feld zu ziehen, ohne echtes 3D-Noise zu benötigen.
  double valueAt(int worldX, int worldY, {double zOffset = 0}) {
    return _noise.sample(worldX / scale, worldY / scale + zOffset);
  }
}
