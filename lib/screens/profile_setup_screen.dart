import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/strings.dart';
import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'preferences_screen.dart';

/// Name and picture. Shown after the intro screens, and from Profile to edit.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.editing = false});

  /// True when opened from Profile; Save then returns instead of continuing setup.
  final bool editing;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final store = AppStore.instance;
  late final TextEditingController _name;
  late String _tab;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: store.userName);
    _tab = store.avatarKind == 'photo' ? 'photo' : 'initial';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 720, maxHeight: 720, imageQuality: 85);
      if (file == null) return;
      final dir = await getApplicationDocumentsDirectory();
      // A new name each time so the picture refreshes everywhere.
      final dest = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(file.path).copy(dest);
      final old = store.photoPath;
      store.setAvatar(kind: 'photo', photo: dest);
      if (old != null && old != dest) {
        try {
          await File(old).delete();
        } catch (_) {}
      }
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) toast(context, tr('Could not open the picture. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continue() {
    store.setName(_name.text);
    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PreferencesScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.c;
        final hasPhoto = store.photoPath != null && File(store.photoPath!).existsSync();
        return Scaffold(
          backgroundColor: c.hero,
          appBar: AppBar(
            backgroundColor: c.hero,
            surfaceTintColor: Colors.transparent,
            foregroundColor: c.ink,
            title: widget.editing ? Text(tr('Edit profile'), style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)) : null,
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    children: [
                      if (!widget.editing) ...[
                        Text(tr('Your profile'),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.ink, height: 1.15)),
                        const SizedBox(height: 8),
                        Text(tr('Add your name and a picture. Tap your picture on the home screen any time to open settings.'),
                            style: TextStyle(fontSize: 15, color: c.muted, height: 1.45)),
                        const SizedBox(height: 24),
                      ],
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(44)),
                              child: UserAvatar(size: 120, radius: 40),
                            ),
                            if (_busy)
                              Positioned.fill(
                                child: Center(child: CircularProgressIndicator(color: c.orange)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(tr('Your name'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _name,
                        autofocus: false,
                        cursorColor: c.orange,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                        onChanged: (v) => store.setName(v),
                        decoration: InputDecoration(
                          hintText: tr('e.g. Usman'),
                          hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: c.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder:
                              OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.orange, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(tr('Picture'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            for (final t in const [('initial', 'Letter'), ('photo', 'Photo')])
                              Expanded(
                                child: Material(
                                  color: _tab == t.$1 ? c.sel : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() => _tab = t.$1);
                                      if (t.$1 == 'initial') store.setAvatar(kind: 'initial');
                                      if (t.$1 == 'photo' && hasPhoto) store.setAvatar(kind: 'photo');
                                    },
                                    child: SizedBox(
                                      height: 42,
                                      child: Center(
                                        child: Text(tr(t.$2),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _tab == t.$1 ? c.onSel : c.muted,
                                              height: 1,
                                            )),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_tab == 'photo') ...[
                        Row(
                          children: [
                            Expanded(
                              child: BigButton(
                                label: tr('Gallery'),
                                icon: Icons.photo_library_outlined,
                                primary: false,
                                height: 52,
                                onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BigButton(
                                label: tr('Camera'),
                                icon: Icons.photo_camera_outlined,
                                primary: false,
                                height: 52,
                                onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(tr('Your photo stays on this phone only.'), style: TextStyle(fontSize: 12.5, color: c.muted)),
                      ],
                      if (_tab != 'photo') ...[
                        const SizedBox(height: 16),
                        Text(tr('Background'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: [
                            for (final col in avatarColors)
                              Semantics(
                                button: true,
                                selected: store.avatarColor == col,
                                child: InkResponse(
                                  radius: 24,
                                  onTap: () => store.setAvatar(kind: 'initial', color: col),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(col),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: store.avatarColor == col ? c.ink : Colors.transparent, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: BigButton(
                      label: widget.editing ? tr('Save') : tr('Continue'),
                      icon: widget.editing ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
