import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/services/file_picker_service.dart';

class CoverSectionEditor extends ConsumerStatefulWidget {
  const CoverSectionEditor({super.key, required this.sectionIndex});

  final int sectionIndex;

  @override
  ConsumerState<CoverSectionEditor> createState() => _CoverSectionEditorState();
}

class _CoverSectionEditorState extends ConsumerState<CoverSectionEditor> {
  late final TextEditingController _venueCtrl;
  late final TextEditingController _logoCtrl;
  late final TextEditingController _taglineCtrl;

  @override
  void initState() {
    super.initState();
    final s = _section;
    _venueCtrl = TextEditingController(text: s.venueName);
    _logoCtrl = TextEditingController(text: s.logoPath ?? '');
    _taglineCtrl = TextEditingController(text: s.tagline);
  }

  @override
  void didUpdateWidget(CoverSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex) {
      final s = _section;
      _venueCtrl.text = s.venueName;
      _logoCtrl.text = s.logoPath ?? '';
      _taglineCtrl.text = s.tagline;
    }
  }

  @override
  void dispose() {
    _venueCtrl.dispose();
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  CoverSection get _section =>
      ref.read(documentProvider).document!.sections[widget.sectionIndex]
          as CoverSection;

  void _update(CoverSection updated) =>
      ref.read(documentProvider.notifier).updateSection(widget.sectionIndex, updated);

  void _pushFromControllers(CoverSection base) {
    _update(
      base.copyWith(
        venueName: _venueCtrl.text,
        logoPath: _logoCtrl.text.isEmpty ? null : _logoCtrl.text,
        tagline: _taglineCtrl.text,
      ),
    );
  }

  Future<void> _pickLogo(CoverSection section) async {
    final path = await FilePickerService.pickImageFile(title: 'Select logo');
    if (path == null) return;
    _logoCtrl.text = path;
    _update(section.copyWith(logoPath: path));
  }

  @override
  Widget build(BuildContext context) {
    final section =
        ref.watch(documentProvider).document!.sections[widget.sectionIndex]
            as CoverSection;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cover page',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'cover  ·  full_page',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _venueCtrl,
            decoration: const InputDecoration(
              labelText: 'Venue name',
              hintText: 'e.g. Ristorante Al Fogolâr',
            ),
            onChanged: (_) => _pushFromControllers(section),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _taglineCtrl,
            decoration: const InputDecoration(
              labelText: 'Tagline',
              hintText: 'Optional subtitle shown below venue name',
            ),
            onChanged: (_) => _pushFromControllers(section),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _logoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Logo path',
                    hintText: './logo.png',
                  ),
                  onChanged: (_) => _pushFromControllers(section),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickLogo(section),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Browse'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
