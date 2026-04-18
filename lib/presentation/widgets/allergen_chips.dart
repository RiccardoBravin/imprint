import 'package:flutter/material.dart';
import 'package:imprint/core/allergens.dart';

/// Inline allergen editor: all 14 EU allergen numbers shown as small toggle
/// buttons. Active allergens are highlighted; inactive ones are outlined.
/// Each button has a tooltip with the full allergen name.
/// No dialog — everything is toggled directly inline.
class AllergenRow extends StatelessWidget {
  const AllergenRow({
    super.key,
    required this.allergens,
    required this.onChanged,
  });

  final List<int> allergens;
  final ValueChanged<List<int>> onChanged;

  void _toggle(int index) {
    final updated = allergens.contains(index)
        ? allergens.where((a) => a != index).toList()
        : ([...allergens, index]..sort());
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: List.generate(euAllergens.length, (i) {
        final active = allergens.contains(i);
        return Tooltip(
          message: '${i + 1}. ${euAllergens[i].name}',
          waitDuration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () => _toggle(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? cs.secondary : Colors.transparent,
                border: Border.all(
                  color: active
                      ? cs.secondary
                      : cs.outline.withValues(alpha: 0.45),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? cs.onSecondary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
