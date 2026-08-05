import 'dart:math';

/// Wetterzustände (Roadmap Phase 3: Temperatur/Wetter). Weitere Zustände
/// (z.B. Schneesturm) kommen mit späteren Klima-/Biom-Phasen dazu.
enum Weather { clear, cloudy, rain, storm }

/// Deterministischer Wetterwechsel.
///
/// Wechselt in festen Zeitintervallen mit seed-basierter, aber
/// reproduzierbarer Zufälligkeit zwischen [Weather]-Zuständen — kein
/// globaler Zufall. Bei gleichem Seed und gleicher Abfolge von [update]-
/// Aufrufen entsteht immer dieselbe Wettergeschichte.
class WeatherSystem {
  final Random _random;
  final double checkIntervalSeconds;

  Weather _current;
  double _accumulator = 0;

  WeatherSystem({
    int seed = 0,
    this.checkIntervalSeconds = 120,
    Weather initial = Weather.clear,
  }) : assert(checkIntervalSeconds > 0, 'checkIntervalSeconds muss positiv sein'),
       _random = Random(seed),
       _current = initial;

  Weather get current => _current;

  /// Treibt den Wetterwechsel um [dtSeconds] Spielzeit voran. Kann pro
  /// Aufruf mehrere Übergänge auslösen, falls [dtSeconds] mehrere
  /// [checkIntervalSeconds] überspringt.
  void update(double dtSeconds) {
    if (dtSeconds <= 0) return;
    _accumulator += dtSeconds;
    while (_accumulator >= checkIntervalSeconds) {
      _accumulator -= checkIntervalSeconds;
      _current = _nextWeather(_current);
    }
  }

  /// Einfache Übergangsgewichte: Wetter bleibt meist stabil, Extremwetter
  /// (storm) folgt fast immer auf rain statt direkt auf clear.
  Weather _nextWeather(Weather from) {
    final roll = _random.nextDouble();
    switch (from) {
      case Weather.clear:
        if (roll < 0.7) return Weather.clear;
        if (roll < 0.95) return Weather.cloudy;
        return Weather.rain;
      case Weather.cloudy:
        if (roll < 0.4) return Weather.cloudy;
        if (roll < 0.7) return Weather.clear;
        if (roll < 0.95) return Weather.rain;
        return Weather.storm;
      case Weather.rain:
        if (roll < 0.5) return Weather.rain;
        if (roll < 0.8) return Weather.cloudy;
        return Weather.storm;
      case Weather.storm:
        if (roll < 0.6) return Weather.rain;
        return Weather.cloudy;
    }
  }
}
