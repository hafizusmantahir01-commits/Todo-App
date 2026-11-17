import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import '../utils/prayer_times.dart';

/// Full-height list of cities with a search bar. Returns the chosen city id.
Future<String?> showCityPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.c.card,
    builder: (_) => _CityPicker(current: current),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({this.current});

  final String? current;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _q.text.trim().toLowerCase();
    final list = cities
        .where((ct) => q.isEmpty || ct.name.toLowerCase().contains(q) || ct.region.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        // Names that start with the search come first.
        if (q.isNotEmpty) {
          final sa = a.name.toLowerCase().startsWith(q), sb = b.name.toLowerCase().startsWith(q);
          if (sa != sb) return sa ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(tr('Your city'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _q,
              autofocus: true,
              cursorColor: c.orange,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: tr('Search city'),
                hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                suffixIcon: _q.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: tr('Clear'),
                        icon: Icon(Icons.close_rounded, color: c.muted),
                        onPressed: () => setState(_q.clear),
                      ),
                filled: true,
                fillColor: c.raised,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('No city found. Choose the nearest big city; prayer times will be within a few minutes.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, height: 1.45),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final ct = list[i];
                      final selected = ct.id == widget.current;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        title: Text(ct.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                        subtitle: Text(ct.region, style: TextStyle(color: c.muted, fontSize: 12.5)),
                        trailing: selected ? Icon(Icons.check_rounded, color: c.orange) : null,
                        onTap: () => Navigator.pop(context, ct.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
