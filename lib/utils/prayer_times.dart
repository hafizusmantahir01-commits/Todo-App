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
  const City(this.id, this.name, this.lat, this.lng, {this.tz = 5, this.region = ''});
  final String id;
  final String name;
  final double lat;
  final double lng;

  /// Hours ahead of UTC (Pakistan is +5 all year, no daylight saving).
  final double tz;

  /// Province or country, shown under the name and used in search.
  final String region;
}

/// Pakistani cities and district towns, plus Gulf cities where many Pakistanis live.
const cities = <City>[
  City('lahore', 'Lahore', 31.5204, 74.3587, region: 'Punjab'),
  City('faisalabad', 'Faisalabad', 31.4504, 73.1350, region: 'Punjab'),
  City('rawalpindi', 'Rawalpindi', 33.5651, 73.0169, region: 'Punjab'),
  City('multan', 'Multan', 30.1575, 71.5249, region: 'Punjab'),
  City('gujranwala', 'Gujranwala', 32.1877, 74.1945, region: 'Punjab'),
  City('sialkot', 'Sialkot', 32.4945, 74.5229, region: 'Punjab'),
  City('bahawalpur', 'Bahawalpur', 29.3956, 71.6836, region: 'Punjab'),
  City('sargodha', 'Sargodha', 32.0740, 72.6861, region: 'Punjab'),
  City('sahiwal', 'Sahiwal', 30.6682, 73.1114, region: 'Punjab'),
  City('sheikhupura', 'Sheikhupura', 31.7131, 73.9783, region: 'Punjab'),
  City('jhang', 'Jhang', 31.2681, 72.3181, region: 'Punjab'),
  City('rahim_yar_khan', 'Rahim Yar Khan', 28.4202, 70.2952, region: 'Punjab'),
  City('gujrat', 'Gujrat', 32.5731, 74.0789, region: 'Punjab'),
  City('kasur', 'Kasur', 31.1187, 74.4462, region: 'Punjab'),
  City('dera_ghazi_khan', 'Dera Ghazi Khan', 30.0459, 70.6403, region: 'Punjab'),
  City('okara', 'Okara', 30.8138, 73.4534, region: 'Punjab'),
  City('chiniot', 'Chiniot', 31.7200, 72.9789, region: 'Punjab'),
  City('kamoke', 'Kamoke', 31.9747, 74.2232, region: 'Punjab'),
  City('hafizabad', 'Hafizabad', 32.0709, 73.6880, region: 'Punjab'),
  City('sadiqabad', 'Sadiqabad', 28.3091, 70.1307, region: 'Punjab'),
  City('burewala', 'Burewala', 30.1667, 72.6500, region: 'Punjab'),
  City('khanewal', 'Khanewal', 30.3017, 71.9321, region: 'Punjab'),
  City('muzaffargarh', 'Muzaffargarh', 30.0703, 71.1933, region: 'Punjab'),
  City('mandi_bahauddin', 'Mandi Bahauddin', 32.5861, 73.4917, region: 'Punjab'),
  City('jhelum', 'Jhelum', 32.9405, 73.7276, region: 'Punjab'),
  City('khanpur', 'Khanpur', 28.6475, 70.6567, region: 'Punjab'),
  City('pakpattan', 'Pakpattan', 30.3436, 73.3869, region: 'Punjab'),
  City('daska', 'Daska', 32.3243, 74.3500, region: 'Punjab'),
  City('gojra', 'Gojra', 31.1487, 72.6866, region: 'Punjab'),
  City('muridke', 'Muridke', 31.8022, 74.2554, region: 'Punjab'),
  City('bahawalnagar', 'Bahawalnagar', 29.9987, 73.2536, region: 'Punjab'),
  City('vehari', 'Vehari', 30.0442, 72.3441, region: 'Punjab'),
  City('toba_tek_singh', 'Toba Tek Singh', 30.9709, 72.4826, region: 'Punjab'),
  City('mianwali', 'Mianwali', 32.5850, 71.5436, region: 'Punjab'),
  City('attock', 'Attock', 33.7660, 72.3609, region: 'Punjab'),
  City('chakwal', 'Chakwal', 32.9328, 72.8630, region: 'Punjab'),
  City('narowal', 'Narowal', 32.1020, 74.8730, region: 'Punjab'),
  City('layyah', 'Layyah', 30.9693, 70.9428, region: 'Punjab'),
  City('lodhran', 'Lodhran', 29.5405, 71.6336, region: 'Punjab'),
  City('khushab', 'Khushab', 32.2967, 72.3525, region: 'Punjab'),
  City('bhakkar', 'Bhakkar', 31.6253, 71.0657, region: 'Punjab'),
  City('rajanpur', 'Rajanpur', 29.1044, 70.3301, region: 'Punjab'),
  City('nankana_sahib', 'Nankana Sahib', 31.4500, 73.7000, region: 'Punjab'),
  City('kot_addu', 'Kot Addu', 30.4700, 70.9670, region: 'Punjab'),
  City('wazirabad', 'Wazirabad', 32.4436, 74.1200, region: 'Punjab'),
  City('taxila', 'Taxila', 33.7456, 72.8085, region: 'Punjab'),
  City('murree', 'Murree', 33.9070, 73.3943, region: 'Punjab'),
  City('arifwala', 'Arifwala', 30.2906, 73.0657, region: 'Punjab'),
  City('kamalia', 'Kamalia', 30.7276, 72.6460, region: 'Punjab'),
  City('jaranwala', 'Jaranwala', 31.3333, 73.4167, region: 'Punjab'),
  City('shakargarh', 'Shakargarh', 32.2626, 75.1583, region: 'Punjab'),
  City('chichawatni', 'Chichawatni', 30.5301, 72.6916, region: 'Punjab'),
  City('pattoki', 'Pattoki', 31.0214, 73.8500, region: 'Punjab'),
  City('hasilpur', 'Hasilpur', 29.6929, 72.5509, region: 'Punjab'),
  City('ahmedpur_east', 'Ahmedpur East', 29.1431, 71.2576, region: 'Punjab'),
  City('chishtian', 'Chishtian', 29.7966, 72.8572, region: 'Punjab'),
  City('kharian', 'Kharian', 32.8167, 73.8833, region: 'Punjab'),
  City('talagang', 'Talagang', 32.9277, 72.4161, region: 'Punjab'),
  City('samundri', 'Samundri', 31.0639, 72.9548, region: 'Punjab'),
  City('pir_mahal', 'Pir Mahal', 30.7667, 72.4333, region: 'Punjab'),
  City('mian_channu', 'Mian Channu', 30.4400, 72.3540, region: 'Punjab'),
  City('kabirwala', 'Kabirwala', 30.4049, 71.8661, region: 'Punjab'),
  City('depalpur', 'Depalpur', 30.6700, 73.6531, region: 'Punjab'),
  City('renala_khurd', 'Renala Khurd', 30.8790, 73.5980, region: 'Punjab'),
  City('islamabad', 'Islamabad', 33.6844, 73.0479, region: 'Islamabad'),
  City('karachi', 'Karachi', 24.8607, 67.0011, region: 'Sindh'),
  City('hyderabad', 'Hyderabad', 25.3960, 68.3578, region: 'Sindh'),
  City('sukkur', 'Sukkur', 27.7052, 68.8574, region: 'Sindh'),
  City('larkana', 'Larkana', 27.5570, 68.2264, region: 'Sindh'),
  City('nawabshah', 'Nawabshah (Shaheed Benazirabad)', 26.2442, 68.4100, region: 'Sindh'),
  City('mirpur_khas', 'Mirpur Khas', 25.5276, 69.0111, region: 'Sindh'),
  City('jacobabad', 'Jacobabad', 28.2769, 68.4514, region: 'Sindh'),
  City('shikarpur', 'Shikarpur', 27.9556, 68.6382, region: 'Sindh'),
  City('khairpur', 'Khairpur', 27.5295, 68.7592, region: 'Sindh'),
  City('dadu', 'Dadu', 26.7319, 67.7750, region: 'Sindh'),
  City('thatta', 'Thatta', 24.7461, 67.9235, region: 'Sindh'),
  City('badin', 'Badin', 24.6560, 68.8370, region: 'Sindh'),
  City('tando_adam', 'Tando Adam', 25.7676, 68.6619, region: 'Sindh'),
  City('tando_allahyar', 'Tando Allahyar', 25.4600, 68.7200, region: 'Sindh'),
  City('umerkot', 'Umerkot', 25.3615, 69.7361, region: 'Sindh'),
  City('sanghar', 'Sanghar', 26.0465, 68.9481, region: 'Sindh'),
  City('ghotki', 'Ghotki', 28.0060, 69.3162, region: 'Sindh'),
  City('kashmore', 'Kashmore', 28.4326, 69.5836, region: 'Sindh'),
  City('mithi', 'Mithi', 24.7400, 69.8000, region: 'Sindh'),
  City('kotri', 'Kotri', 25.3659, 68.3080, region: 'Sindh'),
  City('matiari', 'Matiari', 25.5970, 68.4460, region: 'Sindh'),
  City('naushahro_feroze', 'Naushahro Feroze', 26.8401, 68.1224, region: 'Sindh'),
  City('kandhkot', 'Kandhkot', 28.2440, 69.1826, region: 'Sindh'),
  City('peshawar', 'Peshawar', 34.0151, 71.5249, region: 'Khyber Pakhtunkhwa'),
  City('mardan', 'Mardan', 34.1989, 72.0231, region: 'Khyber Pakhtunkhwa'),
  City('abbottabad', 'Abbottabad', 34.1688, 73.2215, region: 'Khyber Pakhtunkhwa'),
  City('mingora', 'Mingora (Swat)', 34.7717, 72.3602, region: 'Khyber Pakhtunkhwa'),
  City('kohat', 'Kohat', 33.5869, 71.4429, region: 'Khyber Pakhtunkhwa'),
  City('dera_ismail_khan', 'Dera Ismail Khan', 31.8314, 70.9019, region: 'Khyber Pakhtunkhwa'),
  City('bannu', 'Bannu', 32.9889, 70.6056, region: 'Khyber Pakhtunkhwa'),
  City('mansehra', 'Mansehra', 34.3302, 73.1968, region: 'Khyber Pakhtunkhwa'),
  City('swabi', 'Swabi', 34.1201, 72.4702, region: 'Khyber Pakhtunkhwa'),
  City('nowshera', 'Nowshera', 34.0153, 71.9747, region: 'Khyber Pakhtunkhwa'),
  City('charsadda', 'Charsadda', 34.1482, 71.7406, region: 'Khyber Pakhtunkhwa'),
  City('haripur', 'Haripur', 33.9946, 72.9106, region: 'Khyber Pakhtunkhwa'),
  City('chitral', 'Chitral', 35.8518, 71.7864, region: 'Khyber Pakhtunkhwa'),
  City('karak', 'Karak', 33.1163, 71.0937, region: 'Khyber Pakhtunkhwa'),
  City('batkhela', 'Batkhela', 34.6178, 71.9725, region: 'Khyber Pakhtunkhwa'),
  City('timergara', 'Timergara', 34.8282, 71.8413, region: 'Khyber Pakhtunkhwa'),
  City('hangu', 'Hangu', 33.5306, 71.0592, region: 'Khyber Pakhtunkhwa'),
  City('tank', 'Tank', 32.2167, 70.3833, region: 'Khyber Pakhtunkhwa'),
  City('lakki_marwat', 'Lakki Marwat', 32.6074, 70.9112, region: 'Khyber Pakhtunkhwa'),
  City('parachinar', 'Parachinar', 33.8992, 70.1008, region: 'Khyber Pakhtunkhwa'),
  City('battagram', 'Battagram', 34.6779, 73.0236, region: 'Khyber Pakhtunkhwa'),
  City('quetta', 'Quetta', 30.1798, 66.9750, region: 'Balochistan'),
  City('gwadar', 'Gwadar', 25.1264, 62.3225, region: 'Balochistan'),
  City('turbat', 'Turbat', 26.0023, 63.0440, region: 'Balochistan'),
  City('khuzdar', 'Khuzdar', 27.8000, 66.6167, region: 'Balochistan'),
  City('sibi', 'Sibi', 29.5430, 67.8773, region: 'Balochistan'),
  City('chaman', 'Chaman', 30.9210, 66.4597, region: 'Balochistan'),
  City('zhob', 'Zhob', 31.3410, 69.4494, region: 'Balochistan'),
  City('loralai', 'Loralai', 30.3705, 68.5980, region: 'Balochistan'),
  City('hub', 'Hub', 25.0496, 66.8796, region: 'Balochistan'),
  City('dera_murad_jamali', 'Dera Murad Jamali', 28.5467, 68.2233, region: 'Balochistan'),
  City('kalat', 'Kalat', 29.0225, 66.5900, region: 'Balochistan'),
  City('panjgur', 'Panjgur', 26.9645, 64.0903, region: 'Balochistan'),
  City('usta_muhammad', 'Usta Muhammad', 28.1781, 68.0453, region: 'Balochistan'),
  City('pishin', 'Pishin', 30.5810, 66.9940, region: 'Balochistan'),
  City('gilgit', 'Gilgit', 35.9208, 74.3144, region: 'Gilgit-Baltistan'),
  City('skardu', 'Skardu', 35.2971, 75.6333, region: 'Gilgit-Baltistan'),
  City('hunza', 'Hunza (Karimabad)', 36.3167, 74.6500, region: 'Gilgit-Baltistan'),
  City('chilas', 'Chilas', 35.4206, 74.0960, region: 'Gilgit-Baltistan'),
  City('muzaffarabad', 'Muzaffarabad', 34.3700, 73.4711, region: 'Azad Kashmir'),
  City('mirpur_ajk', 'Mirpur (AJK)', 33.1478, 73.7519, region: 'Azad Kashmir'),
  City('kotli', 'Kotli', 33.5156, 73.9019, region: 'Azad Kashmir'),
  City('rawalakot', 'Rawalakot', 33.8578, 73.7604, region: 'Azad Kashmir'),
  City('bagh', 'Bagh', 33.9803, 73.7765, region: 'Azad Kashmir'),
  City('bhimber', 'Bhimber', 32.9747, 74.0786, region: 'Azad Kashmir'),
  City('dubai', 'Dubai', 25.2048, 55.2708, region: 'UAE', tz: 4),
  City('abu_dhabi', 'Abu Dhabi', 24.4539, 54.3773, region: 'UAE', tz: 4),
  City('sharjah', 'Sharjah', 25.3463, 55.4209, region: 'UAE', tz: 4),
  City('riyadh', 'Riyadh', 24.7136, 46.6753, region: 'Saudi Arabia', tz: 3),
  City('jeddah', 'Jeddah', 21.4858, 39.1925, region: 'Saudi Arabia', tz: 3),
  City('makkah', 'Makkah', 21.3891, 39.8579, region: 'Saudi Arabia', tz: 3),
  City('madinah', 'Madinah', 24.5247, 39.5692, region: 'Saudi Arabia', tz: 3),
  City('dammam', 'Dammam', 26.4207, 50.0888, region: 'Saudi Arabia', tz: 3),
  City('doha', 'Doha', 25.2854, 51.5310, region: 'Qatar', tz: 3),
  City('kuwait_city', 'Kuwait City', 29.3759, 47.9774, region: 'Kuwait', tz: 3),
  City('muscat', 'Muscat', 23.5880, 58.3829, region: 'Oman', tz: 4),
  City('manama', 'Manama', 26.2285, 50.5860, region: 'Bahrain', tz: 3),
];

City cityById(String id) {
  for (final c in cities) {
    if (c.id == id) return c;
  }
  return cities.first; // Lahore
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
