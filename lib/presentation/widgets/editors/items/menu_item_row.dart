import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/presentation/widgets/allergen_chips.dart';

class MenuItemRow extends StatefulWidget {
  const MenuItemRow({
    super.key,
    required this.itemIndex,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int itemIndex;
  final MenuItem item;
  final ValueChanged<MenuItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<MenuItemRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _priceCtrl = TextEditingController(text: _formatPrice(widget.item.price));
    _nameFocus = FocusNode();
    _descFocus = FocusNode();
    _priceFocus = FocusNode();
  }

  @override
  void didUpdateWidget(MenuItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_nameFocus.hasFocus && _nameCtrl.text != widget.item.name) {
      _nameCtrl.text = widget.item.name;
    }
    if (!_descFocus.hasFocus && _descCtrl.text != widget.item.description) {
      _descCtrl.text = widget.item.description;
    }
    if (!_priceFocus.hasFocus) {
      final t = _formatPrice(widget.item.price);
      if (_priceCtrl.text != t) _priceCtrl.text = t;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  String _formatPrice(double p) => p == 0 ? '' : p.toStringAsFixed(2);

  double _parsePrice(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  void _push({String? name, String? description, double? price, List<int>? allergens}) {
    widget.onChanged(
      widget.item.copyWith(
        name: name ?? _nameCtrl.text,
        description: description ?? _descCtrl.text,
        price: price ?? _parsePrice(_priceCtrl.text),
        allergens: allergens ?? widget.item.allergens,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: drag handle · name · price · delete ──────────
            Row(
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
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Item name',
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
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            // ── Row 2: description ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 28, right: 8),
              child: TextField(
                controller: _descCtrl,
                focusNode: _descFocus,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onChanged: (_) => _push(),
              ),
            ),
            // ── Row 3: allergens ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2, bottom: 2),
              child: AllergenRow(
                allergens: widget.item.allergens,
                onChanged: (a) => _push(allergens: a),
              ),
            ),
          ],
        ),
    );
  }
}
