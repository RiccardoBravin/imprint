import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/widgets/editors/items/menu_item_row.dart';
import 'package:imprint/presentation/widgets/editors/section_header.dart';

class SpecialSelectionEditor extends ConsumerStatefulWidget {
  const SpecialSelectionEditor({super.key, required this.sectionIndex});

  final int sectionIndex;

  @override
  ConsumerState<SpecialSelectionEditor> createState() =>
      _SpecialSelectionEditorState();
}

class _SpecialSelectionEditorState extends ConsumerState<SpecialSelectionEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;
  late final FocusNode _nameFocus;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    final s = _section;
    _nameCtrl = TextEditingController(text: s.name);
    _priceCtrl = TextEditingController(
      text: s.sharedPrice == 0 ? '' : s.sharedPrice.toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: s.note);
    _nameFocus = FocusNode();
    _priceFocus = FocusNode();
  }

  @override
  void didUpdateWidget(SpecialSelectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex) {
      final s = _section;
      _nameCtrl.text = s.name;
      _priceCtrl.text = s.sharedPrice == 0 ? '' : s.sharedPrice.toStringAsFixed(2);
      _noteCtrl.text = s.note;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  SpecialSelection get _section =>
      ref.read(documentProvider).document!.sections[widget.sectionIndex]
          as SpecialSelection;

  void _update(SpecialSelection updated) =>
      ref.read(documentProvider.notifier).updateSection(widget.sectionIndex, updated);

  @override
  Widget build(BuildContext context) {
    final section =
        ref.watch(documentProvider).document!.sections[widget.sectionIndex]
            as SpecialSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          nameController: _nameCtrl,
          nameFocus: _nameFocus,
          typeLabel: '${section.typeKey}  ·  ${section.layout.toYamlValue()}',
          onNameChanged: (String name) => _update(section.copyWith(name: name)),
        ),
        // Shared price + note fields
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _priceCtrl,
                  focusNode: _priceFocus,
                  decoration: const InputDecoration(
                    labelText: 'Shared price',
                    hintText: '0.00',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  onChanged: (_) => _update(
                    section.copyWith(
                      sharedPrice: double.tryParse(
                            _priceCtrl.text.replaceAll(',', '.'),
                          ) ??
                          0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'e.g. served for the whole table',
                    isDense: true,
                  ),
                  onChanged: (String note) => _update(section.copyWith(note: note)),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Items', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            buildDefaultDragHandles: false,
            itemCount: section.items.length,
            onReorderItem: (oldIndex, newIndex) {
              final items = [...section.items];
              items.insert(newIndex, items.removeAt(oldIndex));
              _update(section.copyWith(items: items));
            },
            footer: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => _update(
                  section.copyWith(
                    items: [...section.items, MenuItem(name: '', price: 0)],
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
            ),
            itemBuilder: (_, i) => MenuItemRow(
              key: ValueKey(section.items[i].id),
              itemIndex: i,
              item: section.items[i],
              onChanged: (updated) {
                final items = [...section.items]..[i] = updated;
                _update(section.copyWith(items: items));
              },
              onDelete: () {
                final items = [...section.items]..removeAt(i);
                _update(section.copyWith(items: items));
              },
            ),
          ),
        ),
      ],
    );
  }
}
