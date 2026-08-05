import 'dart:math';

/// Tageszeit-Zyklus (Roadmap Phase 3: Temperatur/Wetter).
///
/// [timeOfDay] läuft deterministisch von 0 (Mitternacht) über 0.5 (Mittag)
/// zurück zu 0/1 (nächste Mitternacht). Reine, headless testbare Simulation
/// ohne jede Abhängigkeit von Wallclock-Zeit — ausschließlich [update]
/// treibt sie an, mit fester Spielzeit-Dauer pro Tag.
class DayNightCycle {
  /// Länge eines vollen Tag/Nacht-Zyklus in Sekunden Spielzeit.
  final double dayLengthSeconds;

  double _timeOfDay;
  int _dayNumber = 0;

  DayNightCycle({this.dayLengthSeconds = 600, double startTimeOfDay = 0.25})
    : assert(dayLengthSeconds > 0, 'dayLengthSeconds muss positiv sein'),
      assert(
        startTimeOfDay >= 0 && startTimeOfDay < 1,
        'startTimeOfDay muss in [0, 1) liegen',
      ),
      _timeOfDay = startTimeOfDay;

  /// Tageszeit in `[0, 1)`: 0 = Mitternacht, 0.5 = Mittag.
  double get timeOfDay => _timeOfDay;

  /// Wie viele volle Zyklen seit dem Start bereits vergangen sind.
  int get dayNumber => _dayNumber;

  /// Grobe Tag/Nacht-Einteilung: 06:00–18:00 Uhr gilt als Tag.
  bool get isDay => _timeOfDay >= 0.25 && _timeOfDay < 0.75;

  bool get isNight => !isDay;

  /// Helligkeit in `[0, 1]`: voll hell zur Mittagszeit, dunkel um
  /// Mitternacht, dazwischen glatt interpoliert statt hart umzuschalten.
  double get lightLevel {
    final radians = (_timeOfDay - 0.5) * 2 * pi;
    return (cos(radians) + 1) / 2;
  }

  /// Treibt den Zyklus um [dtSeconds] Spielzeit voran.
  void update(double dtSeconds) {
    if (dtSeconds <= 0) return;
    final delta = dtSeconds / dayLengthSeconds;
    var next = _timeOfDay + delta;
    while (next >= 1) {
      next -= 1;
      _dayNumber++;
    }
    _timeOfDay = next;
  }
}
