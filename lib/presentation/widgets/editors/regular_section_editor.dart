import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/widgets/editors/items/menu_item_row.dart';
import 'package:imprint/presentation/widgets/editors/section_header.dart';

class RegularSectionEditor extends ConsumerStatefulWidget {
  const RegularSectionEditor({super.key, required this.sectionIndex});

  final int sectionIndex;

  @override
  ConsumerState<RegularSectionEditor> createState() => _RegularSectionEditorState();
}

class _RegularSectionEditorState extends ConsumerState<RegularSectionEditor> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _section.name);
    _nameFocus = FocusNode();
  }

  @override
  void didUpdateWidget(RegularSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex) {
      _nameCtrl.text = _section.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  RegularSection get _section =>
      ref.read(documentProvider).document!.sections[widget.sectionIndex]
          as RegularSection;

  void _update(RegularSection updated) =>
      ref.read(documentProvider.notifier).updateSection(widget.sectionIndex, updated);

  @override
  Widget build(BuildContext context) {
    final section =
        ref.watch(documentProvider).document!.sections[widget.sectionIndex]
            as RegularSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          nameController: _nameCtrl,
          nameFocus: _nameFocus,
          typeLabel: '${section.typeKey}  ·  ${section.layout.toYamlValue()}',
          onNameChanged: (String name) => _update(section.copyWith(name: name)),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            buildDefaultDragHandles: false,
            itemCount: section.items.length,
            onReorderItem: (oldIndex, newIndex) {
              final items = [...section.items];
              items.insert(newIndex, items.removeAt(oldIndex));
              _update(section.copyWith(items: items));
            },
            footer: _AddItemButton(
              onAdd: () => _update(
                section.copyWith(
                  items: [...section.items, MenuItem(name: '', price: 0)],
                ),
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

class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Item'),
      ),
    );
  }
}
