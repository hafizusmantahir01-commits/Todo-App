import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../l10n/strings.dart';
import '../utils/dates.dart';

/// Saves all data to a file the user can keep (Drive, WhatsApp, Files), and loads it back.
class Backup {
  Backup._();

  static Future<bool> export() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/todo-app-backup-${dayKey(DateTime.now())}.json');
      await file.writeAsString(AppStore.instance.exportJson());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: tr('Todo App backup'),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns null if the user cancelled, true on success, false if the file was not a backup.
  static Future<bool?> restore() async {
    try {
      final file = await fs.openFile(acceptedTypeGroups: const [
        fs.XTypeGroup(label: 'Backup', extensions: ['json'], mimeTypes: ['application/json', 'text/plain', 'application/octet-stream']),
      ]);
      if (file == null) return null;
      final raw = await file.readAsString();
      return AppStore.instance.importJson(raw);
    } catch (_) {
      return false;
    }
  }
}
