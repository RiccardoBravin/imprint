import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/providers/settings_provider.dart';
import 'package:imprint/services/pdf/pdf_service.dart';
import 'package:imprint/services/s3_service.dart';

/// Dialog that renders a PDF and uploads it to the configured S3 bucket.
class UploadDialog extends ConsumerStatefulWidget {
  const UploadDialog({super.key, required this.document});

  final Document document;

  static Future<void> show(BuildContext context, Document document) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UploadDialog(document: document),
      );

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  late PdfFormat _format;
  late final TextEditingController _nameCtrl;

  _UploadPhase _phase = _UploadPhase.idle;
  String? _resultMessage;
  String? _uploadUrl;
  bool _resultOk = false;

  @override
  void initState() {
    super.initState();
    _format = widget.document.settings.activeFormat;
    final baseName = ref.read(documentProvider).displayName.replaceAll(
      RegExp(r'\.imp$', caseSensitive: false),
      '',
    );
    _nameCtrl = TextEditingController(
      text: '$baseName-${_format.name}.pdf',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onFormatChanged(PdfFormat format) {
    setState(() {
      _format = format;
      // Refresh the filename suffix.
      final current = _nameCtrl.text;
      final updated = current
          .replaceFirst(RegExp(r'-(a4|a5)\.pdf$'), '-${format.name}.pdf');
      _nameCtrl.text = updated == current
          ? current.replaceAll(RegExp(r'\.pdf$'), '-${format.name}.pdf')
          : updated;
    });
  }

  Future<void> _upload() async {
    final s3 = ref.read(settingsProvider).s3Config;
    if (s3 == null) return;

    setState(() {
      _phase = _UploadPhase.rendering;
      _resultMessage = null;
    });

    final bytes = await PdfService.render(widget.document, _format);

    setState(() => _phase = _UploadPhase.uploading);

    final result = await S3Service.upload(s3, bytes, _nameCtrl.text.trim());

    setState(() {
      _phase = _UploadPhase.done;
      _resultOk = result.ok;
      if (result.ok) {
        _resultMessage = 'Uploaded successfully.';
        _uploadUrl = result.message;
      } else {
        _resultMessage = result.message;
        _uploadUrl = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s3 = ref.watch(settingsProvider).s3Config;
    final canUpload =
        s3 != null && _phase == _UploadPhase.idle && _nameCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Upload PDF'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s3 == null) _noConfigBanner(context),
            // Format
            Row(
              children: [
                Text(
                  'Format',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(width: 16),
                SegmentedButton<PdfFormat>(
                  segments: const [
                    ButtonSegment(value: PdfFormat.a4, label: Text('A4')),
                    ButtonSegment(value: PdfFormat.a5, label: Text('A5')),
                  ],
                  selected: {_format},
                  onSelectionChanged: (s) => _onFormatChanged(s.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Object name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Object name',
                hintText: 'menu-a4.pdf',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (s3 != null) ...[
              const SizedBox(height: 6),
              Text(
                'Destination: ${s3.bucket} @ ${s3.endpoint}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Progress / result
            if (_phase != _UploadPhase.idle) ...[
              const SizedBox(height: 16),
              _PhaseWidget(phase: _phase, ok: _resultOk, message: _resultMessage),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_phase == _UploadPhase.done && _resultOk) ...[
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: _uploadUrl!)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy link'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _phase = _UploadPhase.idle;
                _resultMessage = null;
                _uploadUrl = null;
              });
            },
            child: const Text('Upload again'),
          ),
        ],
        FilledButton(
          onPressed: canUpload ? _upload : null,
          child: const Text('Upload'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

Widget _noConfigBanner(BuildContext context) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No S3 configuration found. Set it up in Settings → App.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ],
    ),
  ),
);

// ---------------------------------------------------------------------------

enum _UploadPhase { idle, rendering, uploading, done }

class _PhaseWidget extends StatelessWidget {
  const _PhaseWidget({
    required this.phase,
    required this.ok,
    required this.message,
  });

  final _UploadPhase phase;
  final bool ok;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (phase == _UploadPhase.rendering || phase == _UploadPhase.uploading) {
      final label = phase == _UploadPhase.rendering
          ? 'Rendering PDF…'
          : 'Uploading…';
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }

    // Done
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          size: 16,
          color: ok
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            message ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
