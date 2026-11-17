import '../l10n/strings.dart';
import '../models/task.dart';
import 'prayer_times.dart';

enum TokenKind { date, time, prayer, list, tag, priority, repeat, energy }

/// A word or phrase in the input that the parser understood.
class TokenSpan {
  const TokenSpan(this.start, this.end, this.kind);
  final int start;
  final int end;
  final TokenKind kind;
}

/// Result of reading a free-text task like "kal shaam 6 baje gym #health !high".
class ParsedTask {
  ParsedTask({
    required this.title,
    this.due,
    this.hasTime = false,
    this.priority,
    this.listName,
    this.tags = const [],
    this.repeat,
    this.energy,
    this.anchor,
    this.spans = const [],
  });

  final String title;
  final DateTime? due;
  final bool hasTime;
  final Priority? priority;
  final String? listName;
  final List<String> tags;
  final Repeat? repeat;
  final Energy? energy;

  /// For example "after:maghrib", when the time came from a prayer. Show it with [anchorLabel].
  final String? anchor;
  final List<TokenSpan> spans;

  bool get hasExtras =>
      due != null || priority != null || listName != null || tags.isNotEmpty || repeat != null || energy != null;
}

/// Understands English and Roman Urdu for dates, times, prayer times,
/// priority, lists, tags, repeats and energy. Works fully offline.
class SmartParser {
  static const Map<String, int> _weekdays = {
    'mon': 1, 'monday': 1, 'peer': 1, 'pir': 1, 'somwar': 1,
    'tue': 2, 'tues': 2, 'tuesday': 2, 'mangal': 2,
    'wed': 3, 'wednesday': 3, 'budh': 3, 'budhwar': 3,
    'thu': 4, 'thur': 4, 'thurs': 4, 'thursday': 4, 'jumeraat': 4, 'jumerat': 4,
    'fri': 5, 'friday': 5, 'juma': 5, 'jumma': 5,
    'sat': 6, 'saturday': 6, 'hafta': 6, 'haftay': 6,
    'sun': 7, 'sunday': 7, 'itwar': 7, 'itwaar': 7, 'itvaar': 7,
    'پیر': 1, 'منگل': 2, 'بدھ': 3, 'جمعرات': 4, 'جمعہ': 5, 'ہفتہ': 6, 'اتوار': 7,
  };

  static const Map<String, int> _periods = {
    'subah': 9, 'subha': 9, 'morning': 9,
    'dopahar': 14, 'dopehar': 14, 'dopher': 14, 'afternoon': 14,
    'shaam': 18, 'sham': 18, 'evening': 18,
    'raat': 21, 'night': 21,
    'صبح': 9, 'دوپہر': 14, 'شام': 18, 'رات': 21,
  };

  static const Map<String, Prayer> _prayers = {
    'fajr': Prayer.fajr, 'fajar': Prayer.fajr,
    'zuhr': Prayer.dhuhr, 'zohar': Prayer.dhuhr, 'zohr': Prayer.dhuhr, 'dhuhr': Prayer.dhuhr, 'zuhar': Prayer.dhuhr,
    'asr': Prayer.asr, 'asar': Prayer.asr,
    'maghrib': Prayer.maghrib, 'magrib': Prayer.maghrib,
    'isha': Prayer.isha, 'esha': Prayer.isha,
    'فجر': Prayer.fajr, 'ظہر': Prayer.dhuhr, 'عصر': Prayer.asr, 'مغرب': Prayer.maghrib, 'عشاء': Prayer.isha, 'عشا': Prayer.isha,
  };

  static const Set<String> _baje = {'baje', 'bje', 'bajay', 'bajy', 'بجے'};
  static const Set<String> _after = {'baad', 'bad', 'after', 'بعد'};
  static const Set<String> _before = {'pehle', 'pehlay', 'before', 'پہلے'};
  static const Set<String> _joins = {'ke', 'se', 'k', 'کے', 'سے'};
  static const Set<String> _fillers = {'ko', 'ke', 'ka', 'ki', 'at', 'on', 'pe', 'par', 'by', 'se', 'کو', 'کے', 'کا', 'کی', 'پر', 'سے'};

  static final RegExp _timeRe = RegExp(r'^(\d{1,2})(?:[:.](\d{2}))?(am|pm|a|p)?$');

  /// Urdu and Arabic digits to 0-9, one character for one, so positions stay the same.
  static String _westernDigits(String s) {
    const urdu = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = urdu.indexOf(ch);
      final j = arabic.indexOf(ch);
      b.write(i >= 0 ? '$i' : (j >= 0 ? '$j' : ch));
    }
    return b.toString();
  }

  static DateTime _day(DateTime n, int plus) => DateTime(n.year, n.month, n.day + plus);

  static DateTime _nextWeekday(DateTime n, int weekday) {
    var diff = (weekday - n.weekday) % 7;
    if (diff == 0) diff = 7;
    return _day(n, diff);
  }

  static Repeat? _repeatWord(String w) {
    if (w == 'roz' || w == 'din' || w == 'day' || w == 'روز' || w == 'دن') return Repeat.daily;
    if (w == 'hafte' || w == 'hafta' || w == 'haftay' || w == 'week' || w == 'ہفتے') return Repeat.weekly;
    if (w == 'mahine' || w == 'maheene' || w == 'mahina' || w == 'month' || w == 'مہینے') return Repeat.monthly;
    return null;
  }

  /// [prayerTimes] returns the prayer times for a day, or null when prayer
  /// times are switched off. Without it, prayer words are kept in the title.
  static ParsedTask parse(
    String input, {
    DateTime? now,
    List<String> listNames = const [],
    PrayerTimes? Function(DateTime day)? prayerTimes,
  }) {
    final n = now ?? DateTime.now();
    input = _westernDigits(input);
    final matches = RegExp(r'\S+').allMatches(input).toList();
    final raw = matches.map((m) => m.group(0)!).toList();
    final lower = raw.map((t) => t.toLowerCase()).toList();
    final kinds = List<TokenKind?>.filled(raw.length, null);
    bool used(int i) => kinds[i] != null;
    void mark(int i, TokenKind k, [int count = 1]) {
      for (var j = i; j < i + count && j < raw.length; j++) {
        kinds[j] = k;
      }
    }

    DateTime? date;
    int? hour;
    var minute = 0;
    bool? pm;
    int? periodHour;
    Priority? priority;
    Energy? energy;
    Repeat? repeat;
    String? listName;
    Prayer? anchorPrayer;
    var anchorMode = 0; // -1 before, 0 at, 1 after
    final tags = <String>[];
    final canPray = prayerTimes != null && prayerTimes(n) != null;

    for (var i = 0; i < raw.length; i++) {
      if (used(i)) continue;
      final w = lower[i];
      final next = i + 1 < raw.length ? lower[i + 1] : '';
      final next2 = i + 2 < raw.length ? lower[i + 2] : '';

      if (w.startsWith('#') && w.length > 1) {
        final tag = raw[i].substring(1);
        String? match;
        for (final l in listNames) {
          if (l.toLowerCase() == tag.toLowerCase()) match = l;
        }
        if (match != null && listName == null) {
          listName = match;
          mark(i, TokenKind.list);
        } else {
          tags.add(tag);
          mark(i, TokenKind.tag);
        }
        continue;
      }

      if (w.startsWith('!') && w.length > 1) {
        final p = w.substring(1);
        Priority? pr;
        if (p == 'high' || p == 'h' || p == '1' || p == 'zaroori' || p == 'urgent') pr = Priority.high;
        if (p == 'medium' || p == 'med' || p == 'm' || p == '2') pr = Priority.medium;
        if (p == 'low' || p == 'l' || p == '3') pr = Priority.low;
        if (pr != null) {
          priority = pr;
          mark(i, TokenKind.priority);
          continue;
        }
      }
      if (w == 'urgent' || w == 'zaroori' || w == 'asap' || w == 'ضروری') {
        priority = Priority.high;
        mark(i, TokenKind.priority);
        continue;
      }

      if (w == '~easy' || w == '~low') {
        energy = Energy.low;
        mark(i, TokenKind.energy);
        continue;
      }
      if (w == '~medium' || w == '~normal') {
        energy = Energy.medium;
        mark(i, TokenKind.energy);
        continue;
      }
      if (w == '~hard' || w == '~high') {
        energy = Energy.high;
        mark(i, TokenKind.energy);
        continue;
      }

      // Prayer anchors: "after Fajr", "before Zuhr", "Maghrib ke baad", "Zuhr se pehle", "Asr".
      if (canPray) {
        if ((_after.contains(w) || _before.contains(w)) && _prayers.containsKey(next)) {
          anchorPrayer = _prayers[next];
          anchorMode = _after.contains(w) ? 1 : -1;
          mark(i, TokenKind.prayer, 2);
          i++;
          continue;
        }
        final pr = _prayers[w];
        if (pr != null) {
          anchorPrayer = pr;
          anchorMode = 0;
          var take = 1;
          if (_joins.contains(next) && (_after.contains(next2) || _before.contains(next2))) {
            anchorMode = _after.contains(next2) ? 1 : -1;
            take = 3;
          } else if (_after.contains(next) || _before.contains(next)) {
            anchorMode = _after.contains(next) ? 1 : -1;
            take = 2;
          }
          mark(i, TokenKind.prayer, take);
          i += take - 1;
          continue;
        }
      }

      if ((w == 'har' || w == 'every' || w == 'ہر') && next.isNotEmpty) {
        final r = _repeatWord(next);
        if (r != null) {
          repeat = r;
          mark(i, TokenKind.repeat, 2);
          i++;
          continue;
        }
        final wd = _weekdays[next];
        if (wd != null) {
          repeat = Repeat.weekly;
          date = _nextWeekday(n, wd);
          mark(i, TokenKind.repeat, 2);
          i++;
          continue;
        }
      }
      if (w == 'daily' || w == 'rozana' || w == 'everyday' || w == 'روزانہ') {
        repeat = Repeat.daily;
        mark(i, TokenKind.repeat);
        continue;
      }
      if (w == 'weekly') {
        repeat = Repeat.weekly;
        mark(i, TokenKind.repeat);
        continue;
      }
      if (w == 'monthly') {
        repeat = Repeat.monthly;
        mark(i, TokenKind.repeat);
        continue;
      }

      if (w == 'aaj' || w == 'aj' || w == 'today' || w == 'آج') {
        date = _day(n, 0);
        mark(i, TokenKind.date);
        continue;
      }
      if (w == 'tonight') {
        date = _day(n, 0);
        periodHour = 21;
        mark(i, TokenKind.date);
        continue;
      }
      if (w == 'kal' || w == 'tomorrow' || w == 'tmrw' || w == 'tmr' || w == 'کل') {
        date = _day(n, 1);
        mark(i, TokenKind.date);
        continue;
      }
      if (w == 'parson' || w == 'parso' || w == 'parsoon' || w == 'پرسوں') {
        date = _day(n, 2);
        mark(i, TokenKind.date);
        continue;
      }
      if ((w == 'next' || w == 'agle' || w == 'agly' || w == 'اگلے') && (next == 'week' || next == 'hafte' || next == 'haftay' || next == 'ہفتے')) {
        date = _day(n, 7);
        mark(i, TokenKind.date, 2);
        i++;
        continue;
      }
      if ((w == 'next' || w == 'agle' || w == 'agly') && _weekdays[next] != null) {
        date = _nextWeekday(n, _weekdays[next]!);
        mark(i, TokenKind.date, 2);
        i++;
        continue;
      }
      if (w == 'in' && int.tryParse(next) != null && (next2 == 'days' || next2 == 'day')) {
        date = _day(n, int.parse(next));
        mark(i, TokenKind.date, 3);
        i += 2;
        continue;
      }
      if (int.tryParse(w) != null && (next == 'din' || next == 'دن') && (next2 == 'baad' || next2 == 'bad' || next2 == 'بعد')) {
        date = _day(n, int.parse(w));
        mark(i, TokenKind.date, 3);
        i += 2;
        continue;
      }
      final wd = _weekdays[w];
      if (wd != null) {
        date = _nextWeekday(n, wd);
        mark(i, TokenKind.date);
        continue;
      }

      final ph = _periods[w];
      if (ph != null) {
        periodHour = ph;
        mark(i, TokenKind.time);
        continue;
      }

      if ((w == 'sadhe' || w == 'saade' || w == 'sade' || w == 'ساڑھے') && int.tryParse(next) != null && _baje.contains(next2)) {
        final h = int.parse(next);
        if (h >= 1 && h <= 12) {
          hour = h;
          minute = 30;
          mark(i, TokenKind.time, 3);
          i += 2;
          continue;
        }
      }

      final m = _timeRe.firstMatch(w);
      if (m != null) {
        final h = int.parse(m.group(1)!);
        final mm = m.group(2) != null ? int.parse(m.group(2)!) : 0;
        var suffix = m.group(3);
        var takeNext = false;
        if (suffix == null && (next == 'am' || next == 'pm')) {
          suffix = next;
          takeNext = true;
        }
        if (!takeNext && _baje.contains(next)) takeNext = true;
        final looksLikeTime = suffix != null || takeNext || m.group(2) != null;
        if (looksLikeTime && h <= 23 && mm < 60) {
          hour = h;
          minute = mm;
          if (suffix != null) pm = suffix.startsWith('p');
          mark(i, TokenKind.time, takeNext ? 2 : 1);
          if (takeNext) i++;
          continue;
        }
      }
    }

    // Joining words next to an understood word are not part of the title.
    for (var i = 0; i < raw.length; i++) {
      if (used(i) || !_fillers.contains(lower[i])) continue;
      final prev = i > 0 ? kinds[i - 1] : null;
      final nxt = i + 1 < raw.length ? kinds[i + 1] : null;
      final k = prev ?? nxt;
      if (k != null && k != TokenKind.tag && k != TokenKind.list && k != TokenKind.priority) kinds[i] = k;
    }

    int? finalHour;
    if (hour != null) {
      var h = hour;
      if (pm != null) {
        if (pm && h < 12) h += 12;
        if (!pm && h == 12) h = 0;
      } else if (h <= 12) {
        if (periodHour == 14) {
          if (h <= 6) h += 12;
        } else if (periodHour == 18) {
          if (h < 12) h += 12;
        } else if (periodHour == 21) {
          if (h >= 6 && h < 12) {
            h += 12;
          } else if (h == 12) {
            h = 0;
          }
        } else if (periodHour == null) {
          if (h >= 1 && h <= 7) h += 12;
        }
      }
      finalHour = h;
    } else if (periodHour != null) {
      finalHour = periodHour;
      minute = 0;
    }

    DateTime? due;
    var hasTime = false;
    String? anchor;
    if (anchorPrayer != null) {
      var day = date ?? _day(n, 0);
      DateTime anchored(DateTime d) {
        final t = prayerTimes!(d)![anchorPrayer!];
        final offset = anchorMode == 1 ? 15 : (anchorMode == -1 ? -30 : 10);
        return t.add(Duration(minutes: offset));
      }

      var at = anchored(day);
      if (date == null && at.isBefore(n)) {
        day = _day(n, 1);
        at = anchored(day);
      }
      due = at;
      hasTime = true;
      anchor = '${anchorMode == 1 ? 'after' : (anchorMode == -1 ? 'before' : 'at')}:${anchorPrayer.name}';
    } else if (finalHour != null) {
      hasTime = true;
      if (date != null) {
        due = DateTime(date.year, date.month, date.day, finalHour, minute);
      } else {
        var d = DateTime(n.year, n.month, n.day, finalHour, minute);
        if (d.isBefore(n)) d = DateTime(n.year, n.month, n.day + 1, finalHour, minute);
        due = d;
      }
    } else if (date != null) {
      due = date;
    }
    if (repeat != null && due == null) due = _day(n, 0);

    final titleTokens = <String>[
      for (var i = 0; i < raw.length; i++)
        if (!used(i)) raw[i]
    ];
    var title = titleTokens.join(' ').trim();
    if (title.isEmpty) title = input.trim();
    if (title.isNotEmpty) title = title[0].toUpperCase() + title.substring(1);

    final spans = <TokenSpan>[];
    for (var i = 0; i < raw.length; i++) {
      final k = kinds[i];
      if (k == null) continue;
      if (spans.isNotEmpty && spans.last.kind == k && spans.last.end + 1 >= matches[i].start) {
        final last = spans.removeLast();
        spans.add(TokenSpan(last.start, matches[i].end, k));
      } else {
        spans.add(TokenSpan(matches[i].start, matches[i].end, k));
      }
    }

    return ParsedTask(
      title: title,
      due: due,
      hasTime: hasTime,
      priority: priority,
      listName: listName,
      tags: tags,
      repeat: repeat,
      energy: energy,
      anchor: anchor,
      spans: spans,
    );
  }
}

/// Readable text for an anchor code such as "after:maghrib".
String anchorLabel(String code) {
  final parts = code.split(':');
  if (parts.length != 2) return code;
  Prayer? p;
  for (final x in Prayer.values) {
    if (x.name == parts[1]) p = x;
  }
  if (p == null) return code;
  return switch (parts[0]) {
    'after' => tr('After {p}', {'p': p.label}),
    'before' => tr('Before {p}', {'p': p.label}),
    _ => tr('At {p}', {'p': p.label}),
  };
}
