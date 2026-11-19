import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../utils/dates.dart';

/// A readable PDF of all tasks, lists and habits, to keep in Google Drive,
/// send on WhatsApp or print. (Restoring uses the backup file, not the PDF.)
class PdfReport {
  PdfReport._();

  static const _navy = PdfColor.fromInt(0xFF14213D);
  static const _gold = PdfColor.fromInt(0xFFC9A227);
  static const _muted = PdfColor.fromInt(0xFF5D6475);
  static const _soft = PdfColor.fromInt(0xFFF6EDCF);
  static const _row = PdfColor.fromInt(0xFFF7F6F2);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);

  static Future<bool> share() async {
    try {
      final s = AppStore.instance;
      final now = DateTime.now();
      final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
      final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
      final urdu = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
      final dir = currentLang == Lang.ur ? pw.TextDirection.rtl : pw.TextDirection.ltr;

      const h1 = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _white);
      const h2 = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy);
      const small = pw.TextStyle(fontSize: 9, color: _muted);
      const cell = pw.TextStyle(fontSize: 9.5, color: _navy);
      const head = pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _white);

      String status(Task t) => t.done ? tr('Done') : (t.due != null && t.due!.isBefore(dayStart(now)) ? tr('Overdue') : tr('Open'));
      String due(Task t) {
        final d = t.due;
        if (d == null) return '–';
        return t.hasTime ? '${fmtDate(d)} ${fmtTime(d)}' : fmtDate(d);
      }

      final open = s.tasks.where((t) => !t.done).length;
      final done = s.tasks.length - open;

      final content = <pw.Widget>[
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Todo App', style: const pw.TextStyle(fontSize: 11, color: _gold, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(tr('Backup report'), style: h1, textDirection: dir),
              pw.SizedBox(height: 4),
              pw.Text(
                '${s.userName.isEmpty ? '' : '${s.userName} · '}${fmtLongDate(now)} · ${fmtTime(now)}',
                style: const pw.TextStyle(fontSize: 10, color: _white),
                textDirection: dir,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _stat('${s.tasks.length}', tr('Tasks')),
              _stat('$open', tr('Open')),
              _stat('$done', tr('Done')),
              _stat('${s.habits.length}', tr('Habits')),
              _stat('${s.streak}', tr('Day streak')),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
      ];

      for (final l in s.lists) {
        final tasks = s.sortTasks(s.tasks.where((t) => t.listId == l.id));
        if (tasks.isEmpty) continue;
        content.add(pw.Text('${l.name} (${tasks.length})', style: h2, textDirection: dir));
        content.add(pw.SizedBox(height: 6));
        content.add(pw.TableHelper.fromTextArray(
          headers: [tr('Task'), tr('When'), tr('Priority'), tr('Status')],
          data: [
            for (final t in tasks)
              [
                t.subtasks.isEmpty ? t.title : '${t.title}  (${t.subDone}/${t.subtasks.length})',
                due(t),
                t.priority == Priority.none ? '–' : t.priority.label,
                status(t),
              ],
          ],
          headerStyle: head,
          cellStyle: cell,
          headerDecoration: const pw.BoxDecoration(color: _navy),
          oddRowDecoration: const pw.BoxDecoration(color: _row),
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(1.3),
            3: pw.FlexColumnWidth(1.3),
          },
          tableDirection: dir,
          headerDirection: dir,
        ));
        content.add(pw.SizedBox(height: 16));
      }

      if (s.habits.isNotEmpty) {
        final week = s.weekOf(now);
        content.add(pw.Text(tr('Habits'), style: h2, textDirection: dir));
        content.add(pw.SizedBox(height: 6));
        content.add(pw.TableHelper.fromTextArray(
          headers: [tr('Habit'), tr('Streak'), tr('This week')],
          data: [
            for (final h in s.habits)
              [
                h.name,
                tr('{n} days', {'n': s.habitStreak(h)}),
                '${week.where((d) => s.habitDone(h, d)).length}/7',
              ],
          ],
          headerStyle: head,
          cellStyle: cell,
          headerDecoration: const pw.BoxDecoration(color: _navy),
          oddRowDecoration: const pw.BoxDecoration(color: _row),
          tableDirection: dir,
          headerDirection: dir,
        ));
        content.add(pw.SizedBox(height: 16));
      }

      if (s.tasks.isEmpty && s.habits.isEmpty) {
        content.add(pw.Text(tr('No tasks yet.'), style: cell, textDirection: dir));
      }

      content.add(pw.Divider(color: _gold, thickness: 1));
      content.add(pw.Text(
        tr('This PDF is for reading and printing. To restore your data in the app, use “Save backup file”.'),
        style: small,
        textDirection: dir,
      ));

      final doc = pw.Document(title: 'Todo App backup', author: 'Todo App');
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: regular, bold: bold, fontFallback: [urdu]),
        textDirection: dir,
        footer: (context) => pw.Text('Todo App · ${fmtDate(now)}', style: small),
        build: (context) => content,
      ));

      final folder = await getApplicationDocumentsDirectory();
      final file = File('${folder.path}/todo-app-report-${dayKey(now)}.pdf');
      await file.writeAsBytes(await doc.save());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: tr('Todo App backup'),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  static pw.Widget _stat(String value, String label) => pw.Column(
        children: [
          pw.Text(value, style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
        ],
      );
}
