/// Islamic (Hijri) date using the tabular calendar. It can differ from the
/// moon-sighting date by a day, so the user can adjust it with [offsetDays].
class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;

  static HijriDate fromDate(DateTime g, {int offsetDays = 0}) {
    final d = DateTime(g.year, g.month, g.day + offsetDays);
    var y = d.year, m = d.month;
    final day = d.day;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;
    var l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j = (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) +
        ((l / 5670).floor()) * (((43 * l) / 15238).floor());
    l = l - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) - ((j / 16).floor()) * (((15238 * j) / 43).floor()) + 29;
    final hm = ((24 * l) / 709).floor();
    final hd = l - ((709 * hm) / 24).floor();
    final hy = 30 * n + j - 30;
    return HijriDate(hy, hm, hd);
  }

  bool get isRamadan => month == 9;
}
