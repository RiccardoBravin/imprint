import 'package:flutter/material.dart';
import 'package:imprint/data/models/section.dart';

class SectionSettingsPopup extends StatefulWidget {
  const SectionSettingsPopup({super.key, required this.section});

  final Section section;

  static Future<Section?> show(BuildContext context, Section section) {
    return showDialog<Section>(
      context: context,
      builder: (_) => SectionSettingsPopup(section: section),
    );
  }

  @override
  State<SectionSettingsPopup> createState() => _SectionSettingsPopupState();
}

class _SectionSettingsPopupState extends State<SectionSettingsPopup> {
  late SectionLayout _layout;

  @override
  void initState() {
    super.initState();
    _layout = widget.section.layout;
  }

  Section _buildUpdated() => switch (widget.section) {
    RegularSection s => s.copyWith(layout: _layout),
    SpecialSelection s => s.copyWith(layout: _layout),
    WineSection s => s.copyWith(layout: _layout),
    EventSection s => s.copyWith(layout: _layout),
    CoverSection s => s.copyWith(layout: _layout),
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Section settings'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Layout', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            SegmentedButton<SectionLayout>(
              segments: const [
                ButtonSegment(
                  value: SectionLayout.inline,
                  label: Text('Inline'),
                  icon: Icon(Icons.view_column_outlined),
                ),
                ButtonSegment(
                  value: SectionLayout.fullPage,
                  label: Text('Full page'),
                  icon: Icon(Icons.crop_portrait_outlined),
                ),
                ButtonSegment(
                  value: SectionLayout.flow,
                  label: Text('Flow'),
                  icon: Icon(Icons.view_stream_outlined),
                ),
              ],
              selected: {_layout},
              onSelectionChanged: (s) => setState(() => _layout = s.first),
            ),
            const SizedBox(height: 12),
            Text(
              _layoutDescription(_layout),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _buildUpdated()),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _layoutDescription(SectionLayout layout) => switch (layout) {
    SectionLayout.inline =>
      'Groups with adjacent inline sections to fill a page. '
      'The number of sections per page is set in Document settings.',
    SectionLayout.fullPage =>
      'Occupies an entire page alone. '
      'Page breaks are forced before and after this section.',
    SectionLayout.flow =>
      'Continues across as many pages as its content requires. '
      'No grouping with other sections.',
  };
}
