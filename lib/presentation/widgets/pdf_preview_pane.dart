import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/core/constants.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/services/pdf/pdf_service.dart';
import 'package:printing/printing.dart';

class PdfPreviewPane extends ConsumerStatefulWidget {
  const PdfPreviewPane({super.key});

  @override
  ConsumerState<PdfPreviewPane> createState() => _PdfPreviewPaneState();
}

class _PdfPreviewPaneState extends ConsumerState<PdfPreviewPane> {
  PdfFormat _format = PdfFormat.a4;
  Timer? _debounce;
  Document? _pendingDoc;
  Uint8List? _bytes;
  bool _isRendering = false;

  @override
  void initState() {
    super.initState();
    final doc = ref.read(documentProvider).document;
    if (doc != null) _scheduleRender(doc);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleRender(Document doc) {
    _pendingDoc = doc;
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: kPreviewDebounceMs),
      _doRender,
    );
  }

  Future<void> _doRender() async {
    final doc = _pendingDoc;
    if (doc == null || !mounted) return;
    setState(() => _isRendering = true);
    final bytes = await PdfService.render(doc, _format);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _isRendering = false;
    });
  }

  void _setFormat(PdfFormat format) {
    if (_pendingDoc != null) {
      _debounce?.cancel();
      setState(() {
        _format = format;
        _bytes = null;
      });
      unawaited(_doRender());
    } else {
      setState(() => _format = format);
    }
  }

  List<PdfFormat> _enabledFormats(Document? doc) {
    if (doc == null) return PdfFormat.values;
    final formats = <PdfFormat>[];
    if (doc.settings.enableA4) formats.add(PdfFormat.a4);
    if (doc.settings.enableA5) formats.add(PdfFormat.a5);
    if (formats.isEmpty) formats.addAll(PdfFormat.values);
    return formats;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Document?>(
      documentProvider.select((s) => s.document),
      (_, doc) { if (doc != null && mounted) _scheduleRender(doc); },
    );

    final doc = ref.watch(documentProvider).document;
    final enabled = _enabledFormats(doc);

    if (!enabled.contains(_format)) _format = enabled.first;

    return Column(
      children: [
        _PreviewHeader(
          format: _format,
          isRendering: _isRendering,
          enabledFormats: enabled,
          onFormatChanged: _setFormat,
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PdfPreview(
      build: (_) => Future.value(_bytes!),
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      dpi: 150,
      scrollViewDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.format,
    required this.isRendering,
    required this.enabledFormats,
    required this.onFormatChanged,
  });

  final PdfFormat format;
  final bool isRendering;
  final List<PdfFormat> enabledFormats;
  final ValueChanged<PdfFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          if (isRendering)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const Spacer(),
          if (enabledFormats.length > 1)
            SegmentedButton<PdfFormat>(
              segments: [
                if (enabledFormats.contains(PdfFormat.a4))
                  const ButtonSegment(value: PdfFormat.a4, label: Text('A4')),
                if (enabledFormats.contains(PdfFormat.a5))
                  const ButtonSegment(value: PdfFormat.a5, label: Text('A5')),
              ],
              selected: {format},
              onSelectionChanged: (s) => onFormatChanged(s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else
            Text(
              enabledFormats.first == PdfFormat.a4 ? 'A4' : 'A5',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
