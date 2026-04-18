import 'package:flutter/material.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/services/pdf/pdf_service.dart';
import 'package:printing/printing.dart';

/// Shows a full-screen PDF preview dialog with A4/A5 toggle, zoom, and print.
class PdfPreviewDialog extends StatefulWidget {
  const PdfPreviewDialog({super.key, required this.document});

  final Document document;

  static Future<void> show(BuildContext context, Document document) =>
      showDialog<void>(
        context: context,
        builder: (_) => PdfPreviewDialog(document: document),
      );

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  PdfFormat _format = PdfFormat.a4;

  // Zoom: 1.0 = ~800px page width; range 0.5–3.0.
  double _zoom = 1.0;
  static const double _basePageWidth = 800.0;
  static const double _zoomStep = 0.25;
  static const double _zoomMin = 0.5;
  static const double _zoomMax = 3.0;

  double get _maxPageWidth => _basePageWidth * _zoom;

  void _zoomIn() => setState(() => _zoom = (_zoom + _zoomStep).clamp(_zoomMin, _zoomMax));
  void _zoomOut() => setState(() => _zoom = (_zoom - _zoomStep).clamp(_zoomMin, _zoomMax));
  void _zoomReset() => setState(() => _zoom = 1.0);

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Preview'),
          leading: CloseButton(onPressed: () => Navigator.pop(context)),
          actions: [
            // A4 / A5 toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SegmentedButton<PdfFormat>(
                segments: const [
                  ButtonSegment(value: PdfFormat.a4, label: Text('A4')),
                  ButtonSegment(value: PdfFormat.a5, label: Text('A5')),
                ],
                selected: {_format},
                onSelectionChanged: (s) => setState(() => _format = s.first),
                showSelectedIcon: false,
              ),
            ),
            // Zoom controls
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom out',
              onPressed: _zoom > _zoomMin ? _zoomOut : null,
            ),
            InkWell(
              onTap: _zoomReset,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Text(
                  '${(_zoom * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom in',
              onPressed: _zoom < _zoomMax ? _zoomIn : null,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: PdfPreview(
          key: ValueKey((_format, _zoom)),
          build: (_) => PdfService.render(widget.document, _format),
          allowPrinting: true,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          maxPageWidth: _maxPageWidth,
          dpi: 150,
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
