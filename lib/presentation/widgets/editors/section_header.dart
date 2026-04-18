import 'package:flutter/material.dart';

/// Shared top-of-editor widget: editable section name + type/layout label.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.nameController,
    required this.nameFocus,
    required this.typeLabel,
    required this.onNameChanged,
  });

  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String typeLabel;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            focusNode: nameFocus,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Section name',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 4),
          Text(
            typeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
