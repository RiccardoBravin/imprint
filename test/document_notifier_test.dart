import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/presentation/providers/document_provider.dart';

void main() {
  group('DocumentNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has no document and is not dirty', () {
      final state = container.read(documentProvider);
      expect(state.isOpen, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.document, isNull);
    });

    test('newDocument produces an empty open document that is not dirty', () {
      container.read(documentProvider.notifier).newDocument();
      final state = container.read(documentProvider);
      expect(state.isOpen, isTrue);
      expect(state.isDirty, isFalse);
      expect(state.document!.sections, isEmpty);
    });

    test('addSection appends section and marks state dirty', () {
      container.read(documentProvider.notifier).newDocument();
      container
          .read(documentProvider.notifier)
          .addSection(RegularSection(name: 'Starters'));
      final state = container.read(documentProvider);
      expect(state.isDirty, isTrue);
      expect(state.document!.sections.length, 1);
      expect(state.document!.sections.first.name, 'Starters');
    });

    test('removeSection removes the correct section by index', () {
      container.read(documentProvider.notifier).newDocument();
      final n = container.read(documentProvider.notifier);
      n.addSection(RegularSection(name: 'A'));
      n.addSection(RegularSection(name: 'B'));
      n.removeSection(0);
      final sections = container.read(documentProvider).document!.sections;
      expect(sections.length, 1);
      expect(sections.first.name, 'B');
    });

    test('updateSection replaces the section at the given index', () {
      container.read(documentProvider.notifier).newDocument();
      final n = container.read(documentProvider.notifier);
      n.addSection(RegularSection(name: 'Old'));
      n.updateSection(0, RegularSection(name: 'New'));
      final sections = container.read(documentProvider).document!.sections;
      expect(sections.first.name, 'New');
    });

    test('updateSection preserves the section id', () {
      container.read(documentProvider.notifier).newDocument();
      final n = container.read(documentProvider.notifier);
      final original = RegularSection(name: 'Original');
      n.addSection(original);
      n.updateSection(0, original.copyWith(name: 'Updated'));
      final updated =
          container.read(documentProvider).document!.sections.first;
      expect(updated.id, original.id);
    });

    test('reorderSections moves item from index 0 to 2', () {
      container.read(documentProvider.notifier).newDocument();
      final n = container.read(documentProvider.notifier);
      n.addSection(RegularSection(name: 'A'));
      n.addSection(RegularSection(name: 'B'));
      n.addSection(RegularSection(name: 'C'));
      n.reorderSections(0, 2);
      final names = container
          .read(documentProvider)
          .document!
          .sections
          .map((s) => s.name)
          .toList();
      expect(names, ['B', 'C', 'A']);
    });

    test('close resets to initial state', () {
      container.read(documentProvider.notifier).newDocument();
      container.read(documentProvider.notifier).close();
      expect(container.read(documentProvider).isOpen, isFalse);
    });

    test('openPath returns (false, null) for a non-existent file', () async {
      final (opened, error) = await container
          .read(documentProvider.notifier)
          .openPath('/tmp/does_not_exist_imprint.imp');
      expect(opened, isFalse);
      expect(error, isNull);
    });

    test('openPath returns (false, errorMessage) for invalid YAML', () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/imprint_test_invalid.imp',
      ).writeAsString(': invalid: yaml: [[[');
      try {
        final (opened, error) = await container
            .read(documentProvider.notifier)
            .openPath(tmp.path);
        expect(opened, isFalse);
        expect(error, isNotNull);
        expect(error, isNotEmpty);
      } finally {
        await tmp.delete();
      }
    });
  });
}
