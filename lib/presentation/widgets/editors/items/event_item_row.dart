import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imprint/data/models/items/event_item.dart';

class EventItemRow extends StatefulWidget {
  const EventItemRow({
    super.key,
    required this.itemIndex,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int itemIndex;
  final EventItem item;
  final ValueChanged<EventItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<EventItemRow> createState() => _EventItemRowState();
}

class _EventItemRowState extends State<EventItemRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _priceCtrl;
  late final FocusNode _nameFocus;
  late final FocusNode _timeFocus;
  late final FocusNode _priceFocus;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _timeCtrl = TextEditingController(text: widget.item.time ?? '');
    _priceCtrl = TextEditingController(text: _formatPrice(widget.item.price));
    _nameFocus = FocusNode();
    _timeFocus = FocusNode();
    _priceFocus = FocusNode();
  }

  @override
  void didUpdateWidget(EventItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_nameFocus.hasFocus && _nameCtrl.text != widget.item.name) {
      _nameCtrl.text = widget.item.name;
    }
    if (!_timeFocus.hasFocus) {
      final t = widget.item.time ?? '';
      if (_timeCtrl.text != t) _timeCtrl.text = t;
    }
    if (!_priceFocus.hasFocus) {
      final t = _formatPrice(widget.item.price);
      if (_priceCtrl.text != t) _priceCtrl.text = t;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocus.dispose();
    _timeFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  String _formatPrice(double? p) => (p == null || p == 0) ? '' : p.toStringAsFixed(2);

  double? _parsePrice(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  void _push() {
    widget.onChanged(
      widget.item.copyWith(
        name: _nameCtrl.text,
        time: _timeCtrl.text.isEmpty ? null : _timeCtrl.text,
        price: _parsePrice(_priceCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: widget.itemIndex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_handle,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  hintText: 'Event name',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
                onChanged: (_) => _push(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _timeCtrl,
                focusNode: _timeFocus,
                decoration: const InputDecoration(
                  hintText: '19:00',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
                onChanged: (_) => _push(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _priceCtrl,
                focusNode: _priceFocus,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: (_) => _push(),
              ),
            ),
            AnimatedOpacity(
              opacity: _isHovered ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove item',
                visualDensity: VisualDensity.compact,
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
