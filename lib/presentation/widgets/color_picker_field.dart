import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// A compact inline color picker: colored swatch + hex text field.
/// Clicking the swatch opens a dialog with preset colors and a full picker.
class ColorPickerField extends StatefulWidget {
  const ColorPickerField({
    super.key,
    required this.color,
    required this.onChanged,
    this.label,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String? label;

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late final TextEditingController _hexCtrl;
  late final FocusNode _hexFocus;

  @override
  void initState() {
    super.initState();
    _hexCtrl = TextEditingController(text: _colorToHex(widget.color));
    _hexFocus = FocusNode();
  }

  @override
  void didUpdateWidget(ColorPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hexFocus.hasFocus && oldWidget.color != widget.color) {
      _hexCtrl.text = _colorToHex(widget.color);
    }
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  static String _colorToHex(Color c) {
    final argb = c.toARGB32();
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color? _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      return val != null ? Color(val) : null;
    }
    return null;
  }

  Future<void> _openPicker() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(current: widget.color),
    );
    if (result != null) {
      _hexCtrl.text = _colorToHex(result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Pick color',
          child: GestureDetector(
            onTap: _openPicker,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _hexCtrl,
            focusNode: _hexFocus,
            decoration: InputDecoration(
              labelText: widget.label ?? 'Color',
              hintText: '#000000',
              isDense: true,
            ),
            onChanged: (v) {
              final c = _hexToColor(v);
              if (c != null) widget.onChanged(c);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.current});
  final Color current;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Color _picked;

  static const _presets = <Color>[
    Color(0xFF000000),
    Color(0xFF212121),
    Color(0xFF424242),
    Color(0xFF757575),
    Color(0xFFBDBDBD),
    Color(0xFFFFFFFF),
    Color(0xFFFFF8E1),
    Color(0xFFF5F0E8),
    Color(0xFF8E6B46),
    Color(0xFF6D4C41),
    Color(0xFF4E342E),
    Color(0xFFBF8C60),
    Color(0xFF4A6741),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
    Color(0xFF558B2F),
    Color(0xFFB71C1C),
    Color(0xFFC62828),
    Color(0xFF700E0E),
    Color(0xFF661A26),
    Color(0xFF880E4F),
    Color(0xFF4A148C),
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
    Color(0xFF004D40),
    Color(0xFF263238),
  ];

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Presets'), Tab(text: 'Custom')],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabs,
                children: [
                  // Presets grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((c) => GestureDetector(
                      onTap: () => setState(() => _picked = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: c.toARGB32() == _picked.toARGB32()
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: c.toARGB32() == _picked.toARGB32() ? 3 : 1,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  // Full HSV picker
                  SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _picked,
                      onColorChanged: (c) => setState(() => _picked = c),
                      enableAlpha: false,
                      labelTypes: const [],
                      pickerAreaHeightPercent: 0.6,
                      portraitOnly: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Preview swatch
            Row(
              children: [
                const Text('Selected: '),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _picked,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ],
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
          onPressed: () => Navigator.pop(context, _picked),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
