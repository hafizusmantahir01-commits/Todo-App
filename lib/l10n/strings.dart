import 'translations.dart';

/// App languages. Roman Urdu uses English letters, Urdu is right-to-left.
enum Lang { en, ur, roman }

extension LangX on Lang {
  String get nativeName => switch (this) {
        Lang.en => 'English',
        Lang.ur => 'اردو',
        Lang.roman => 'Roman Urdu',
      };
  /// Locale code for Flutter's built-in texts (date pickers etc.).
  String get localeCode => this == Lang.ur ? 'ur' : 'en';
  bool get rtl => this == Lang.ur;
}

/// Current language. Set by the store when it loads or changes.
Lang currentLang = Lang.en;

/// Translates an English UI string. Use {name} placeholders for values:
/// tr('{n} tasks left', {'n': 3}).
String tr(String english, [Map<String, Object?> args = const {}]) {
  var s = switch (currentLang) {
    Lang.en => english,
    Lang.ur => urdu[english] ?? english,
    Lang.roman => roman[english] ?? english,
  };
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Picks the singular or plural form, then translates.
String trn(int n, String one, String many, [Map<String, Object?> args = const {}]) =>
    tr(n == 1 ? one : many, {'n': n, ...args});

const _monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _monthsUr = ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];
const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _daysUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
const _daysRo = ['Peer', 'Mangal', 'Budh', 'Jumeraat', 'Juma', 'Hafta', 'Itwaar'];
const _hijriEn = ['Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah'];
const _hijriUr = ['محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی', 'جمادی الاول', 'جمادی الثانی', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذوالقعدہ', 'ذوالحجہ'];

String monthName(int m) => currentLang == Lang.ur ? _monthsUr[m - 1] : _monthsEn[m - 1];

String monthShort(int m) => currentLang == Lang.ur ? _monthsUr[m - 1] : _monthsEn[m - 1].substring(0, 3);

String dayName(int weekday) => switch (currentLang) {
      Lang.en => _daysEn[weekday - 1],
      Lang.ur => _daysUr[weekday - 1],
      Lang.roman => _daysRo[weekday - 1],
    };

String dayShort(int weekday) => currentLang == Lang.ur ? _daysUr[weekday - 1] : dayName(weekday).substring(0, 3);

/// One letter (or short word in Urdu) for compact week rows.
String dayInitial(int weekday) => currentLang == Lang.ur ? _daysUr[weekday - 1].substring(0, 1) : dayName(weekday)[0];

String hijriMonthName(int m) => currentLang == Lang.ur ? _hijriUr[m - 1] : _hijriEn[m - 1];
