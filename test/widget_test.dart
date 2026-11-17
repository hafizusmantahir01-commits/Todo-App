// Unit tests for smart typing and prayer times. Run with: flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/utils/prayer_times.dart';
import 'package:todo_app/utils/smart_parser.dart';

void main() {
  // Sunday 15 Nov 2026, 10:00 AM
  final now = DateTime(2026, 11, 15, 10, 0);
  const lists = ['Inbox', 'Work', 'Health', 'Home', 'Study'];
  PrayerTimes? lahore(DateTime d) => PrayerTimes.forDay(d, cityById('lahore'));

  test('kal shaam 6 baje with list and priority', () {
    final p = SmartParser.parse('kal shaam 6 baje gym #health !high', now: now, listNames: lists);
    expect(p.title, 'Gym');
    expect(p.due, DateTime(2026, 11, 16, 18, 0));
    expect(p.listName, 'Health');
    expect(p.priority, Priority.high);
  });

  test('English: tomorrow at 5pm', () {
    final p = SmartParser.parse('call mom tomorrow at 5pm', now: now);
    expect(p.title, 'Call mom');
    expect(p.due, DateTime(2026, 11, 16, 17, 0));
  });

  test('Maghrib ke baad is 15 minutes after Maghrib', () {
    final p = SmartParser.parse('ammi ko call kal Maghrib ke baad', now: now, prayerTimes: lahore);
    final maghrib = lahore(DateTime(2026, 11, 16))![Prayer.maghrib];
    expect(p.title, 'Ammi ko call');
    expect(p.due, maghrib.add(const Duration(minutes: 15)));
    expect(p.anchor, 'after:maghrib');
  });

  test('prayer words stay in the title when prayer times are off', () {
    final p = SmartParser.parse('asr', now: now);
    expect(p.title, 'Asr');
    expect(p.due, isNull);
  });

  test('sadhe 4 baje = 4:30 PM', () {
    final p = SmartParser.parse('parson sadhe 4 baje meeting', now: now);
    expect(p.due, DateTime(2026, 11, 17, 16, 30));
  });

  test('plain numbers are not times', () {
    final p = SmartParser.parse('buy 5 apples', now: now);
    expect(p.title, 'Buy 5 apples');
    expect(p.due, isNull);
  });

  test('prayer times are in a sensible order', () {
    final t = lahore(DateTime(2026, 11, 15))!;
    expect(t[Prayer.fajr].isBefore(t[Prayer.dhuhr]), true);
    expect(t[Prayer.dhuhr].isBefore(t[Prayer.asr]), true);
    expect(t[Prayer.asr].isBefore(t[Prayer.maghrib]), true);
    expect(t[Prayer.maghrib].isBefore(t[Prayer.isha]), true);
    expect(t[Prayer.dhuhr].hour, inInclusiveRange(11, 12));
  });

  test('Urdu script: کل شام ۶ بجے جم', () {
    final p = SmartParser.parse('کل شام ۶ بجے جم', now: now);
    expect(p.title, 'جم');
    expect(p.due, DateTime(2026, 11, 16, 18, 0));
  });

  test('Urdu script: مغرب کے بعد', () {
    final p = SmartParser.parse('امی کو کال مغرب کے بعد', now: now, prayerTimes: lahore);
    expect(p.anchor, 'after:maghrib');
    expect(p.title, 'امی کو کال');
  });
}
