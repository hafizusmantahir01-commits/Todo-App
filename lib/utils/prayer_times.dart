import 'dart:math' as math;

import '../l10n/strings.dart';

/// The five daily prayers shown on the day arc.
enum Prayer { fajr, dhuhr, asr, maghrib, isha }

extension PrayerX on Prayer {
  String get label => switch (this) {
        Prayer.fajr => tr('Fajr'),
        Prayer.dhuhr => tr('Zuhr'),
        Prayer.asr => tr('Asr'),
        Prayer.maghrib => tr('Maghrib'),
        Prayer.isha => tr('Isha'),
      };
}

class City {
  const City(this.id, this.name, this.lat, this.lng, {this.tz = 5});
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double tz;
}

const cities = <City>[
  City('karachi', 'Karachi', 24.8607, 67.0011),
  City('lahore', 'Lahore', 31.5204, 74.3587),
  City('islamabad', 'Islamabad', 33.6844, 73.0479),
  City('rawalpindi', 'Rawalpindi', 33.5651, 73.0169),
  City('faisalabad', 'Faisalabad', 31.4504, 73.1350),
  City('multan', 'Multan', 30.1575, 71.5249),
  City('peshawar', 'Peshawar', 34.0151, 71.5249),
  City('quetta', 'Quetta', 30.1798, 66.9750),
  City('hyderabad', 'Hyderabad', 25.3960, 68.3578),
  City('sialkot', 'Sialkot', 32.4945, 74.5229),
  City('gujranwala', 'Gujranwala', 32.1877, 74.1945),
  City('bahawalpur', 'Bahawalpur', 29.3956, 71.6836),
  City('sargodha', 'Sargodha', 32.0740, 72.6861),
  City('abbottabad', 'Abbottabad', 34.1688, 73.2215),
  City('muzaffarabad', 'Muzaffarabad', 34.3700, 73.4711),
];

City cityById(String id) {
  for (final c in cities) {
    if (c.id == id) return c;
  }
  return cities[1];
}

/// Offline prayer-time calculation (University of Islamic Sciences, Karachi:
/// Fajr and Isha at 18 degrees). Asr uses the Hanafi or Shafi shadow factor.
class PrayerTimes {
  PrayerTimes._(this.times);

  final Map<Prayer, DateTime> times;
  DateTime operator [](Prayer p) => times[p]!;

  static final Map<String, PrayerTimes> _cache = {};

  static PrayerTimes forDay(DateTime day, City city, {bool hanafi = true}) {
    final key = '${day.year}-${day.month}-${day.day}-${city.id}-$hanafi';
    return _cache.putIfAbsent(key, () => _compute(day, city, hanafi));
  }

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _sin(double d) => math.sin(_rad(d));
  static double _cos(double d) => math.cos(_rad(d));
  static double _tan(double d) => math.tan(_rad(d));
  static double _asin(double x) => _deg(math.asin(x));
  static double _acos(double x) => _deg(math.acos(x.clamp(-1.0, 1.0)));
  static double _atan2(double y, double x) => _deg(math.atan2(y, x));
  static double _acot(double x) => _deg(math.atan(1 / x));
  static double _fix(double a, double b) {
    final r = a - b * (a / b).floorToDouble();
    return r < 0 ? r + b : r;
  }

  static double _julian(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
  }

  static PrayerTimes _compute(DateTime day, City city, bool hanafi) {
    final lat = city.lat;
    final jDate = _julian(day.year, day.month, day.day) - city.lng / (15 * 24);

    (double, double) sunPos(double jd) {
      final dd = jd - 2451545.0;
      final g = _fix(357.529 + 0.98560028 * dd, 360);
      final q = _fix(280.459 + 0.98564736 * dd, 360);
      final l = _fix(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g), 360);
      final e = 23.439 - 0.00000036 * dd;
      final ra = _atan2(_cos(e) * _sin(l), _cos(l)) / 15;
      final eqt = q / 15 - _fix(ra, 24);
      final decl = _asin(_sin(e) * _sin(l));
      return (decl, eqt);
    }

    double midDay(double t) => _fix(12 - sunPos(jDate + t).$2, 24);

    double angleTime(double angle, double t, {bool ccw = false}) {
      final decl = sunPos(jDate + t).$1;
      final noon = midDay(t);
      final v = (1 / 15) * _acos((-_sin(angle) - _sin(decl) * _sin(lat)) / (_cos(decl) * _cos(lat)));
      return noon + (ccw ? -v : v);
    }

    double asr(double factor, double t) {
      final decl = sunPos(jDate + t).$1;
      final angle = -_acot(factor + _tan((lat - decl).abs()));
      return angleTime(angle, t);
    }

    final fajr = angleTime(18, 5 / 24, ccw: true);
    final dhuhr = midDay(12 / 24);
    final asrT = asr(hanafi ? 2 : 1, 13 / 24);
    final maghrib = angleTime(0.833, 18 / 24);
    final isha = angleTime(18, 18 / 24);

    DateTime at(double hours) {
      final h = hours + city.tz - city.lng / 15;
      final mins = (h * 60).round();
      return DateTime(day.year, day.month, day.day).add(Duration(minutes: mins));
    }

    return PrayerTimes._({
      Prayer.fajr: at(fajr),
      Prayer.dhuhr: at(dhuhr).add(const Duration(minutes: 1)),
      Prayer.asr: at(asrT),
      Prayer.maghrib: at(maghrib),
      Prayer.isha: at(isha),
    });
  }

  /// The next prayer after [now], or null after Isha.
  Prayer? nextAfter(DateTime now) {
    for (final p in Prayer.values) {
      if (times[p]!.isAfter(now)) return p;
    }
    return null;
  }
}
