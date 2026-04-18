import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/app_settings.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/format_settings.dart';
import 'package:imprint/data/models/s3_config.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/providers/settings_provider.dart';
import 'package:imprint/presentation/widgets/color_picker_field.dart';
import 'package:imprint/services/s3_service.dart';

class SettingsPopup extends StatefulWidget {
  const SettingsPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SettingsPopup(),
    );
  }

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Document'),
                Tab(text: 'App'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [_DocumentTab(), _AppTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Document tab
// ============================================================================

class _DocumentTab extends ConsumerStatefulWidget {
  const _DocumentTab();

  @override
  ConsumerState<_DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends ConsumerState<_DocumentTab> {
  late PdfFormat _editingFormat;

  // A4 fields
  late final TextEditingController _a4FontCtrl;
  late final TextEditingController _a4SectionsCtrl;
  late final TextEditingController _a4ItemFontCtrl;
  late final TextEditingController _a4DescFontCtrl;
  late final TextEditingController _a4FooterFontCtrl;
  late final TextEditingController _a4LogoSizeCtrl;
  late bool _a4ShowFooter;
  late bool _a4ShowFee;
  late Color _a4Color;
  late Color _a4ItemColor;
  late Color _a4DescColor;
  late Color _a4FooterColor;
  late Color _a4BgColor;

  // A5 fields
  late final TextEditingController _a5FontCtrl;
  late final TextEditingController _a5SectionsCtrl;
  late final TextEditingController _a5ItemFontCtrl;
  late final TextEditingController _a5DescFontCtrl;
  late final TextEditingController _a5FooterFontCtrl;
  late final TextEditingController _a5LogoSizeCtrl;
  late bool _a5ShowFooter;
  late bool _a5ShowFee;
  late Color _a5Color;
  late Color _a5ItemColor;
  late Color _a5DescColor;
  late Color _a5FooterColor;
  late Color _a5BgColor;

  // Document level
  late final TextEditingController _feeCtrl;
  late final TextEditingController _footerNoteCtrl;
  late bool _enableA4;
  late bool _enableA5;
  late bool _enableS3Upload;
  late String _priceSymbol;

  @override
  void initState() {
    super.initState();
    final doc = ref.read(documentProvider).document ?? Document.empty();
    final a4 = doc.settings.a4;
    final a5 = doc.settings.a5;

    _editingFormat = doc.settings.activeFormat;

    _a4FontCtrl = TextEditingController(text: a4.titleFontSize.toStringAsFixed(0));
    _a4SectionsCtrl = TextEditingController(text: a4.sectionsPerPage.toString());
    _a4ItemFontCtrl = TextEditingController(text: a4.itemFontSize.toStringAsFixed(1));
    _a4DescFontCtrl = TextEditingController(text: a4.descFontSize.toStringAsFixed(1));
    _a4FooterFontCtrl = TextEditingController(text: a4.footerFontSize.toStringAsFixed(1));
    _a4LogoSizeCtrl = TextEditingController(text: a4.logoSize.toStringAsFixed(0));
    _a4ShowFooter = a4.showFooter;
    _a4ShowFee = a4.showFee;
    _a4Color = a4.color;
    _a4ItemColor = a4.itemColorValue;
    _a4DescColor = a4.descColorValue;
    _a4FooterColor = a4.footerColorValue;
    _a4BgColor = a4.backgroundColorValue;

    _a5FontCtrl = TextEditingController(text: a5.titleFontSize.toStringAsFixed(0));
    _a5SectionsCtrl = TextEditingController(text: a5.sectionsPerPage.toString());
    _a5ItemFontCtrl = TextEditingController(text: a5.itemFontSize.toStringAsFixed(1));
    _a5DescFontCtrl = TextEditingController(text: a5.descFontSize.toStringAsFixed(1));
    _a5FooterFontCtrl = TextEditingController(text: a5.footerFontSize.toStringAsFixed(1));
    _a5LogoSizeCtrl = TextEditingController(text: a5.logoSize.toStringAsFixed(0));
    _a5ShowFooter = a5.showFooter;
    _a5ShowFee = a5.showFee;
    _a5Color = a5.color;
    _a5ItemColor = a5.itemColorValue;
    _a5DescColor = a5.descColorValue;
    _a5FooterColor = a5.footerColorValue;
    _a5BgColor = a5.backgroundColorValue;

    _feeCtrl = TextEditingController(
      text: (doc.fee ?? 0) == 0 ? '' : doc.fee!.toStringAsFixed(2),
    );
    _footerNoteCtrl = TextEditingController(text: doc.footerNote ?? '');

    _enableA4 = doc.settings.enableA4;
    _enableA5 = doc.settings.enableA5;
    _enableS3Upload = doc.settings.enableS3Upload;
    _priceSymbol = doc.settings.priceSymbol;
  }

  @override
  void dispose() {
    _a4FontCtrl.dispose();
    _a4SectionsCtrl.dispose();
    _a4ItemFontCtrl.dispose();
    _a4DescFontCtrl.dispose();
    _a4FooterFontCtrl.dispose();
    _a4LogoSizeCtrl.dispose();
    _a5FontCtrl.dispose();
    _a5SectionsCtrl.dispose();
    _a5ItemFontCtrl.dispose();
    _a5DescFontCtrl.dispose();
    _a5FooterFontCtrl.dispose();
    _a5LogoSizeCtrl.dispose();
    _feeCtrl.dispose();
    _footerNoteCtrl.dispose();
    super.dispose();
  }

  void _pushA4() {
    final doc = ref.read(documentProvider).document;
    if (doc == null) return;
    final s = doc.settings.a4;
    ref.read(documentProvider.notifier).updateDocument(
      doc.copyWith(
        settings: doc.settings.copyWith(
          a4: FormatSettings(
            titleFontSize: double.tryParse(_a4FontCtrl.text) ?? s.titleFontSize,
            primaryColor: _a4Color.toARGB32(),
            sectionsPerPage: int.tryParse(_a4SectionsCtrl.text) ?? s.sectionsPerPage,
            showFooter: _a4ShowFooter,
            showFee: _a4ShowFee,
            itemFontSize: double.tryParse(_a4ItemFontCtrl.text) ?? s.itemFontSize,
            itemColor: _a4ItemColor.toARGB32(),
            descFontSize: double.tryParse(_a4DescFontCtrl.text) ?? s.descFontSize,
            descColor: _a4DescColor.toARGB32(),
            footerFontSize: double.tryParse(_a4FooterFontCtrl.text) ?? s.footerFontSize,
            footerColor: _a4FooterColor.toARGB32(),
            logoSize: double.tryParse(_a4LogoSizeCtrl.text) ?? s.logoSize,
            backgroundColor: _a4BgColor.toARGB32(),
          ),
        ),
      ),
    );
  }

  void _pushA5() {
    final doc = ref.read(documentProvider).document;
    if (doc == null) return;
    final s = doc.settings.a5;
    ref.read(documentProvider.notifier).updateDocument(
      doc.copyWith(
        settings: doc.settings.copyWith(
          a5: FormatSettings(
            titleFontSize: double.tryParse(_a5FontCtrl.text) ?? s.titleFontSize,
            primaryColor: _a5Color.toARGB32(),
            sectionsPerPage: int.tryParse(_a5SectionsCtrl.text) ?? s.sectionsPerPage,
            showFooter: _a5ShowFooter,
            showFee: _a5ShowFee,
            itemFontSize: double.tryParse(_a5ItemFontCtrl.text) ?? s.itemFontSize,
            itemColor: _a5ItemColor.toARGB32(),
            descFontSize: double.tryParse(_a5DescFontCtrl.text) ?? s.descFontSize,
            descColor: _a5DescColor.toARGB32(),
            footerFontSize: double.tryParse(_a5FooterFontCtrl.text) ?? s.footerFontSize,
            footerColor: _a5FooterColor.toARGB32(),
            logoSize: double.tryParse(_a5LogoSizeCtrl.text) ?? s.logoSize,
            backgroundColor: _a5BgColor.toARGB32(),
          ),
        ),
      ),
    );
  }

  void _pushDoc() {
    final doc = ref.read(documentProvider).document;
    if (doc == null) return;
    final feeText = _feeCtrl.text.replaceAll(',', '.');
    final fee = feeText.isEmpty ? null : double.tryParse(feeText);
    final note = _footerNoteCtrl.text.isEmpty ? null : _footerNoteCtrl.text;
    ref.read(documentProvider.notifier).updateDocument(
      doc.copyWith(fee: fee, footerNote: note),
    );
  }

  void _pushDocSettings() {
    final doc = ref.read(documentProvider).document;
    if (doc == null) return;
    ref.read(documentProvider.notifier).updateDocument(
      doc.copyWith(
        settings: doc.settings.copyWith(
          enableA4: _enableA4,
          enableA5: _enableA5,
          enableS3Upload: _enableS3Upload,
          priceSymbol: _priceSymbol,
        ),
      ),
    );
  }

  void _setFormat(PdfFormat format) {
    setState(() => _editingFormat = format);
    final doc = ref.read(documentProvider).document;
    if (doc == null) return;
    ref.read(documentProvider.notifier).updateDocument(
      doc.copyWith(settings: doc.settings.copyWith(activeFormat: format)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isA4 = _editingFormat == PdfFormat.a4;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // ── Format selector (active for editing) ──────────────────
        _SectionLabel('Format settings'),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Editing', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 12),
            SegmentedButton<PdfFormat>(
              segments: const [
                ButtonSegment(value: PdfFormat.a4, label: Text('A4')),
                ButtonSegment(value: PdfFormat.a5, label: Text('A5')),
              ],
              selected: {_editingFormat},
              onSelectionChanged: (s) => _setFormat(s.first),
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Active format settings ────────────────────────────────
        if (isA4)
          _FormatFields(
            fontCtrl: _a4FontCtrl,
            sectionsCtrl: _a4SectionsCtrl,
            itemFontCtrl: _a4ItemFontCtrl,
            descFontCtrl: _a4DescFontCtrl,
            footerFontCtrl: _a4FooterFontCtrl,
            logoSizeCtrl: _a4LogoSizeCtrl,
            titleColor: _a4Color,
            itemColor: _a4ItemColor,
            descColor: _a4DescColor,
            footerColor: _a4FooterColor,
            bgColor: _a4BgColor,
            showFooter: _a4ShowFooter,
            showFee: _a4ShowFee,
            onChanged: _pushA4,
            onTitleColorChanged: (c) { setState(() => _a4Color = c); _pushA4(); },
            onItemColorChanged: (c) { setState(() => _a4ItemColor = c); _pushA4(); },
            onDescColorChanged: (c) { setState(() => _a4DescColor = c); _pushA4(); },
            onFooterColorChanged: (c) { setState(() => _a4FooterColor = c); _pushA4(); },
            onBgColorChanged: (c) { setState(() => _a4BgColor = c); _pushA4(); },
            onShowFooterChanged: (v) { setState(() => _a4ShowFooter = v); _pushA4(); },
            onShowFeeChanged: (v) { setState(() => _a4ShowFee = v); _pushA4(); },
          )
        else
          _FormatFields(
            fontCtrl: _a5FontCtrl,
            sectionsCtrl: _a5SectionsCtrl,
            itemFontCtrl: _a5ItemFontCtrl,
            descFontCtrl: _a5DescFontCtrl,
            footerFontCtrl: _a5FooterFontCtrl,
            logoSizeCtrl: _a5LogoSizeCtrl,
            titleColor: _a5Color,
            itemColor: _a5ItemColor,
            descColor: _a5DescColor,
            footerColor: _a5FooterColor,
            bgColor: _a5BgColor,
            showFooter: _a5ShowFooter,
            showFee: _a5ShowFee,
            onChanged: _pushA5,
            onTitleColorChanged: (c) { setState(() => _a5Color = c); _pushA5(); },
            onItemColorChanged: (c) { setState(() => _a5ItemColor = c); _pushA5(); },
            onDescColorChanged: (c) { setState(() => _a5DescColor = c); _pushA5(); },
            onFooterColorChanged: (c) { setState(() => _a5FooterColor = c); _pushA5(); },
            onBgColorChanged: (c) { setState(() => _a5BgColor = c); _pushA5(); },
            onShowFooterChanged: (v) { setState(() => _a5ShowFooter = v); _pushA5(); },
            onShowFeeChanged: (v) { setState(() => _a5ShowFee = v); _pushA5(); },
          ),
        const SizedBox(height: 20),
        // ── Document ──────────────────────────────────────────────
        _SectionLabel('Document'),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _feeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cover charge',
                  hintText: '0.00',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (_) => _pushDoc(),
              ),
            ),
            const SizedBox(width: 16),
            // Price symbol picker
            _LabeledField(
              label: 'Price symbol',
              child: DropdownMenu<String>(
                initialSelection: _priceSymbol,
                inputDecorationTheme: const InputDecorationTheme(isDense: true),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: '€', label: '€  Euro'),
                  DropdownMenuEntry(value: '\$', label: '\$  Dollar'),
                  DropdownMenuEntry(value: '£', label: '£  Pound'),
                ],
                onSelected: (v) {
                  if (v == null) return;
                  setState(() => _priceSymbol = v);
                  _pushDocSettings();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _footerNoteCtrl,
          decoration: const InputDecoration(
            labelText: 'Footer note',
            hintText: 'Text shown at the bottom of every page',
            isDense: true,
          ),
          maxLines: 2,
          onChanged: (_) => _pushDoc(),
        ),
        const SizedBox(height: 16),
        // ── Format availability ───────────────────────────────────
        _SectionLabel('Available formats'),
        const SizedBox(height: 4),
        Text(
          'Controls which formats appear in print, preview, and export.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Toggle(
              label: 'A4',
              value: _enableA4,
              onChanged: (v) { setState(() => _enableA4 = v); _pushDocSettings(); },
            ),
            const SizedBox(width: 24),
            _Toggle(
              label: 'A5',
              value: _enableA5,
              onChanged: (v) { setState(() => _enableA5 = v); _pushDocSettings(); },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Cloud upload ──────────────────────────────────────────
        _SectionLabel('Cloud upload'),
        const SizedBox(height: 8),
        _Toggle(
          label: 'Enable S3 upload button for this document',
          value: _enableS3Upload,
          onChanged: (v) { setState(() => _enableS3Upload = v); _pushDocSettings(); },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _FormatFields extends StatelessWidget {
  const _FormatFields({
    required this.fontCtrl,
    required this.sectionsCtrl,
    required this.itemFontCtrl,
    required this.descFontCtrl,
    required this.footerFontCtrl,
    required this.logoSizeCtrl,
    required this.titleColor,
    required this.itemColor,
    required this.descColor,
    required this.footerColor,
    required this.bgColor,
    required this.showFooter,
    required this.showFee,
    required this.onChanged,
    required this.onTitleColorChanged,
    required this.onItemColorChanged,
    required this.onDescColorChanged,
    required this.onFooterColorChanged,
    required this.onBgColorChanged,
    required this.onShowFooterChanged,
    required this.onShowFeeChanged,
  });

  final TextEditingController fontCtrl;
  final TextEditingController sectionsCtrl;
  final TextEditingController itemFontCtrl;
  final TextEditingController descFontCtrl;
  final TextEditingController footerFontCtrl;
  final TextEditingController logoSizeCtrl;
  final Color titleColor;
  final Color itemColor;
  final Color descColor;
  final Color footerColor;
  final Color bgColor;
  final bool showFooter;
  final bool showFee;
  final VoidCallback onChanged;
  final ValueChanged<Color> onTitleColorChanged;
  final ValueChanged<Color> onItemColorChanged;
  final ValueChanged<Color> onDescColorChanged;
  final ValueChanged<Color> onFooterColorChanged;
  final ValueChanged<Color> onBgColorChanged;
  final ValueChanged<bool> onShowFooterChanged;
  final ValueChanged<bool> onShowFeeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ─────────────────────────────────────────────────
        _SubsectionLabel('Title'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: fontCtrl,
                decoration: const InputDecoration(
                  labelText: 'Font size',
                  hintText: '40',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextField(
                controller: sectionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sections / page',
                  hintText: '3',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            ColorPickerField(
              color: titleColor,
              label: 'Color',
              onChanged: onTitleColorChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Items ─────────────────────────────────────────────────
        _SubsectionLabel('Items'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: itemFontCtrl,
                decoration: const InputDecoration(
                  labelText: 'Font size',
                  hintText: '10',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            ColorPickerField(
              color: itemColor,
              label: 'Color',
              onChanged: onItemColorChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Descriptions ──────────────────────────────────────────
        _SubsectionLabel('Descriptions'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: descFontCtrl,
                decoration: const InputDecoration(
                  labelText: 'Font size',
                  hintText: '8.5',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            ColorPickerField(
              color: descColor,
              label: 'Color',
              onChanged: onDescColorChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Footer & Logo ─────────────────────────────────────────
        _SubsectionLabel('Footer & Logo'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: footerFontCtrl,
                decoration: const InputDecoration(
                  labelText: 'Font size',
                  hintText: '7.5',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            ColorPickerField(
              color: footerColor,
              label: 'Color',
              onChanged: onFooterColorChanged,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: logoSizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Logo size',
                  hintText: '80',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Toggle(
              label: 'Show footer note',
              value: showFooter,
              onChanged: onShowFooterChanged,
            ),
            const SizedBox(width: 24),
            _Toggle(
              label: 'Show cover charge',
              value: showFee,
              onChanged: onShowFeeChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Page background ───────────────────────────────────────
        _SubsectionLabel('Page background'),
        const SizedBox(height: 6),
        ColorPickerField(
          color: bgColor,
          label: 'Background color',
          onChanged: onBgColorChanged,
        ),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

// ============================================================================
// App tab
// ============================================================================

class _AppTab extends ConsumerStatefulWidget {
  const _AppTab();

  @override
  ConsumerState<_AppTab> createState() => _AppTabState();
}

class _AppTabState extends ConsumerState<_AppTab> {
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _bucketCtrl;
  late final TextEditingController _accessKeyCtrl;
  late final TextEditingController _secretKeyCtrl;
  late double _uiScale;

  late ThemeMode _themeMode;
  bool _secretVisible = false;
  String? _connectionMessage;
  bool _connectionOk = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final s3 = settings.s3Config;
    _endpointCtrl = TextEditingController(text: s3?.endpoint ?? '');
    _bucketCtrl = TextEditingController(text: s3?.bucket ?? '');
    _accessKeyCtrl = TextEditingController(text: s3?.accessKey ?? '');
    _secretKeyCtrl = TextEditingController(text: s3?.secretKey ?? '');
    _uiScale = settings.uiTextScaleFactor;
    _themeMode = settings.themeMode;
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _bucketCtrl.dispose();
    _accessKeyCtrl.dispose();
    _secretKeyCtrl.dispose();
    super.dispose();
  }

  void _push() {
    final endpoint = _endpointCtrl.text.trim();
    final bucket = _bucketCtrl.text.trim();
    final accessKey = _accessKeyCtrl.text.trim();
    final secretKey = _secretKeyCtrl.text.trim();

    final s3 = endpoint.isEmpty && bucket.isEmpty
        ? null
        : S3Config(
            endpoint: endpoint,
            bucket: bucket,
            accessKey: accessKey,
            secretKey: secretKey,
          );

    ref.read(settingsProvider.notifier).update(
      AppSettings(s3Config: s3, uiTextScaleFactor: _uiScale, themeMode: _themeMode),
    );
    setState(() => _connectionMessage = null);
  }

  Future<void> _testConnection() async {
    final s3 = ref.read(settingsProvider).s3Config;
    if (s3 == null) {
      setState(() {
        _connectionMessage = 'Enter endpoint, bucket, and credentials first.';
        _connectionOk = false;
      });
      return;
    }
    setState(() {
      _connectionMessage = 'Testing…';
      _connectionOk = false;
    });
    final result = await S3Service.testConnection(s3);
    setState(() {
      _connectionOk = result.ok;
      _connectionMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // ── UI text scale ─────────────────────────────────────────
        _SectionLabel('Interface'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Text scale'),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _uiScale,
                min: 0.7,
                max: 1.6,
                divisions: 18,
                label: '${(_uiScale * 100).round()}%',
                onChanged: (v) {
                  setState(() => _uiScale = v);
                  _push();
                },
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${(_uiScale * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Theme'),
            const SizedBox(width: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {_themeMode},
              onSelectionChanged: (s) {
                setState(() => _themeMode = s.first);
                _push();
              },
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // ── S3 cloud storage ──────────────────────────────────────
        _SectionLabel('Cloud Storage (S3-compatible)'),
        const SizedBox(height: 12),
        TextField(
          controller: _endpointCtrl,
          decoration: const InputDecoration(
            labelText: 'Endpoint',
            hintText: 'https://…',
            isDense: true,
          ),
          onChanged: (_) => _push(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bucketCtrl,
          decoration: const InputDecoration(
            labelText: 'Bucket',
            isDense: true,
          ),
          onChanged: (_) => _push(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accessKeyCtrl,
          decoration: const InputDecoration(
            labelText: 'Access key',
            isDense: true,
          ),
          onChanged: (_) => _push(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _secretKeyCtrl,
          obscureText: !_secretVisible,
          decoration: InputDecoration(
            labelText: 'Secret key',
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _secretVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _secretVisible = !_secretVisible),
            ),
          ),
          onChanged: (_) => _push(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_tethering_outlined),
              label: const Text('Test connection'),
            ),
            if (_connectionMessage != null) ...[
              const SizedBox(width: 12),
              Icon(
                _connectionOk ? Icons.check_circle_outline : Icons.info_outline,
                size: 16,
                color: _connectionOk
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: SelectableText(
                  _connectionMessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
