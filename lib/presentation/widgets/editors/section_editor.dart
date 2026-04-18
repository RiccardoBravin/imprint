import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';
import 'package:imprint/presentation/widgets/editors/cover_section_editor.dart';
import 'package:imprint/presentation/widgets/editors/event_section_editor.dart';
import 'package:imprint/presentation/widgets/editors/regular_section_editor.dart';
import 'package:imprint/presentation/widgets/editors/special_selection_editor.dart';
import 'package:imprint/presentation/widgets/editors/wine_section_editor.dart';

/// Routes to the correct editor widget based on the section type.
class SectionEditor extends ConsumerWidget {
  const SectionEditor({super.key, required this.sectionIndex});

  final int sectionIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(documentProvider).document;
    if (doc == null || sectionIndex >= doc.sections.length) {
      return const SizedBox.shrink();
    }

    return switch (doc.sections[sectionIndex]) {
      RegularSection _ => RegularSectionEditor(sectionIndex: sectionIndex),
      SpecialSelection _ => SpecialSelectionEditor(sectionIndex: sectionIndex),
      WineSection _ => WineSectionEditor(sectionIndex: sectionIndex),
      EventSection _ => EventSectionEditor(sectionIndex: sectionIndex),
      CoverSection _ => CoverSectionEditor(sectionIndex: sectionIndex),
    };
  }
}
