import 'package:flutter_test/flutter_test.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/document_settings.dart';
import 'package:imprint/data/models/items/event_item.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/items/wine_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/data/serialization/imp_serializer.dart';

void main() {
  group('ImpSerializer round-trip', () {
    test('empty document survives round-trip', () {
      final doc = Document.empty();
      final yaml = ImpSerializer.toYaml(doc);
      final parsed = ImpSerializer.fromYaml(yaml);

      expect(parsed.version, doc.version);
      expect(parsed.sections, isEmpty);
    });

    test('regular section with items survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          RegularSection(
            name: 'Starters',
            items: [
              MenuItem(name: 'Soup', description: 'Tomato', price: 6.5, allergens: [1, 7]),
              MenuItem(name: 'Salad', price: 8.0),
            ],
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as RegularSection;

      expect(s.name, 'Starters');
      expect(s.items.length, 2);
      expect(s.items[0].name, 'Soup');
      expect(s.items[0].description, 'Tomato');
      expect(s.items[0].price, 6.5);
      expect(s.items[0].allergens, [1, 7]);
      expect(s.items[1].name, 'Salad');
      expect(s.items[1].price, 8.0);
    });

    test('wine section survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          WineSection(
            name: 'Reds',
            items: [WineItem(name: 'Barolo', price: 45.0)],
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as WineSection;

      expect(s.name, 'Reds');
      expect(s.items.first.name, 'Barolo');
      expect(s.items.first.price, 45.0);
    });

    test('event section with optional fields survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          EventSection(
            name: 'Programme',
            items: [
              EventItem(name: 'Keynote', time: '19:00', price: 10.0),
              EventItem(name: 'Dinner'),
            ],
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as EventSection;

      expect(s.items[0].time, '19:00');
      expect(s.items[0].price, 10.0);
      expect(s.items[1].time, isNull);
      expect(s.items[1].price, isNull);
    });

    test('cover section survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          CoverSection(
            venueName: 'Ristorante da Marco',
            tagline: 'Fine dining since 1982',
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as CoverSection;

      expect(s.venueName, 'Ristorante da Marco');
      expect(s.tagline, 'Fine dining since 1982');
      expect(s.logoPath, isNull);
    });

    test('special selection survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          SpecialSelection(
            name: 'Chef\'s Menu',
            sharedPrice: 55.0,
            note: 'For the whole table',
            items: [MenuItem(name: 'Amuse-bouche', price: 0)],
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as SpecialSelection;

      expect(s.sharedPrice, 55.0);
      expect(s.note, 'For the whole table');
      expect(s.items.first.name, 'Amuse-bouche');
    });

    test('document fee and footer note survive round-trip', () {
      final doc = Document(
        fee: 3.5,
        footerNote: 'Service not included',
        settings: DocumentSettings.defaults,
        sections: [],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));

      expect(parsed.fee, 3.5);
      expect(parsed.footerNote, 'Service not included');
    });

    test('strings with special characters are escaped and recovered', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          RegularSection(
            name: 'Special "chars"',
            items: [
              MenuItem(
                name: 'Item with "quotes" and \\backslash',
                description: 'Line1\nLine2',
                price: 0,
              ),
            ],
          ),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      final s = parsed.sections.first as RegularSection;

      expect(s.name, 'Special "chars"');
      expect(s.items.first.name, 'Item with "quotes" and \\backslash');
      expect(s.items.first.description, 'Line1\nLine2');
    });

    test('hidden section flag survives round-trip', () {
      final doc = Document(
        settings: DocumentSettings.defaults,
        sections: [
          RegularSection(name: 'Hidden', hidden: true),
        ],
      );

      final parsed = ImpSerializer.fromYaml(ImpSerializer.toYaml(doc));
      expect(parsed.sections.first.hidden, isTrue);
    });

    test('throws ImpSerializerException on invalid YAML', () {
      expect(
        () => ImpSerializer.fromYaml(': invalid: yaml: [[['),
        throwsA(isA<ImpSerializerException>()),
      );
    });

    test('throws ImpSerializerException on unsupported version', () {
      expect(
        () => ImpSerializer.fromYaml('version: 99\nsections: []'),
        throwsA(isA<ImpSerializerException>()),
      );
    });
  });

  group('MenuItem equality and identity', () {
    test('copyWith preserves id', () {
      final item = MenuItem(name: 'Pasta', price: 12.0);
      final updated = item.copyWith(name: 'Risotto');
      expect(updated.id, item.id);
    });

    test('two independently constructed items have different ids', () {
      final a = MenuItem(name: 'X', price: 0);
      final b = MenuItem(name: 'X', price: 0);
      expect(a.id, isNot(b.id));
      expect(a, isNot(b));
    });

    test('item equals itself after copyWith with no changes', () {
      final item = MenuItem(name: 'Pasta', price: 12.0, allergens: [1, 2]);
      expect(item.copyWith(), equals(item));
    });
  });

  group('CoverSection nullable logoPath', () {
    test('copyWith can null-out logoPath via sentinel', () {
      final section = CoverSection(venueName: 'Test', logoPath: '/logo.png');
      final cleared = section.copyWith(logoPath: null);
      expect(cleared.logoPath, isNull);
      expect(cleared.venueName, 'Test');
    });

    test('copyWith without logoPath argument preserves existing path', () {
      final section = CoverSection(logoPath: '/logo.png');
      final copy = section.copyWith(venueName: 'New Name');
      expect(copy.logoPath, '/logo.png');
    });
  });
}
