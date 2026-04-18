import 'package:flutter/foundation.dart';
import 'package:imprint/data/models/items/event_item.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/items/wine_item.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum SectionLayout {
  fullPage,
  inline,
  flow;

  String toYamlValue() => switch (this) {
    SectionLayout.fullPage => 'full_page',
    SectionLayout.inline => 'inline',
    SectionLayout.flow => 'flow',
  };

  static SectionLayout fromString(String s) => switch (s) {
    'full_page' => SectionLayout.fullPage,
    'flow' => SectionLayout.flow,
    _ => SectionLayout.inline,
  };
}

sealed class Section {
  Section({
    String? id,
    required this.name,
    this.hidden = false,
    this.layout = SectionLayout.inline,
  }) : id = id ?? _uuid.v4();

  /// Stable in-memory identity key used for widget keying. Not serialized.
  final String id;
  final String name;
  final bool hidden;
  final SectionLayout layout;

  /// YAML discriminator string for this section type.
  String get typeKey;
}

// ---------------------------------------------------------------------------

class RegularSection extends Section {
  RegularSection({
    super.id,
    required super.name,
    super.hidden,
    super.layout,
    this.items = const [],
  });

  final List<MenuItem> items;

  @override
  String get typeKey => 'regular';

  RegularSection copyWith({
    String? name,
    bool? hidden,
    SectionLayout? layout,
    List<MenuItem>? items,
  }) => RegularSection(
    id: id,
    name: name ?? this.name,
    hidden: hidden ?? this.hidden,
    layout: layout ?? this.layout,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegularSection &&
          name == other.name &&
          hidden == other.hidden &&
          layout == other.layout &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(name, hidden, layout, Object.hashAll(items));
}

// ---------------------------------------------------------------------------

class SpecialSelection extends Section {
  SpecialSelection({
    super.id,
    required super.name,
    super.hidden,
    super.layout = SectionLayout.fullPage,
    this.sharedPrice = 0,
    this.note = '',
    this.items = const [],
  });

  final double sharedPrice;
  final String note;
  final List<MenuItem> items;

  @override
  String get typeKey => 'special_selection';

  SpecialSelection copyWith({
    String? name,
    bool? hidden,
    SectionLayout? layout,
    double? sharedPrice,
    String? note,
    List<MenuItem>? items,
  }) => SpecialSelection(
    id: id,
    name: name ?? this.name,
    hidden: hidden ?? this.hidden,
    layout: layout ?? this.layout,
    sharedPrice: sharedPrice ?? this.sharedPrice,
    note: note ?? this.note,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialSelection &&
          name == other.name &&
          hidden == other.hidden &&
          layout == other.layout &&
          sharedPrice == other.sharedPrice &&
          note == other.note &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
    name,
    hidden,
    layout,
    sharedPrice,
    note,
    Object.hashAll(items),
  );
}

// ---------------------------------------------------------------------------

class WineSection extends Section {
  WineSection({
    super.id,
    required super.name,
    super.hidden,
    super.layout = SectionLayout.flow,
    this.items = const [],
  });

  final List<WineItem> items;

  @override
  String get typeKey => 'wine_list';

  WineSection copyWith({
    String? name,
    bool? hidden,
    SectionLayout? layout,
    List<WineItem>? items,
  }) => WineSection(
    id: id,
    name: name ?? this.name,
    hidden: hidden ?? this.hidden,
    layout: layout ?? this.layout,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WineSection &&
          name == other.name &&
          hidden == other.hidden &&
          layout == other.layout &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(name, hidden, layout, Object.hashAll(items));
}

// ---------------------------------------------------------------------------

class EventSection extends Section {
  EventSection({
    super.id,
    required super.name,
    super.hidden,
    super.layout = SectionLayout.fullPage,
    this.items = const [],
  });

  final List<EventItem> items;

  @override
  String get typeKey => 'event_program';

  EventSection copyWith({
    String? name,
    bool? hidden,
    SectionLayout? layout,
    List<EventItem>? items,
  }) => EventSection(
    id: id,
    name: name ?? this.name,
    hidden: hidden ?? this.hidden,
    layout: layout ?? this.layout,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventSection &&
          name == other.name &&
          hidden == other.hidden &&
          layout == other.layout &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(name, hidden, layout, Object.hashAll(items));
}

// ---------------------------------------------------------------------------

class CoverSection extends Section {
  CoverSection({
    super.id,
    super.name = '',
    super.hidden,
    super.layout = SectionLayout.fullPage,
    this.venueName = '',
    this.logoPath,
    this.tagline = '',
  });

  final String venueName;
  final String? logoPath;
  final String tagline;

  @override
  String get typeKey => 'cover';

  static const _absent = Object();

  CoverSection copyWith({
    String? name,
    bool? hidden,
    SectionLayout? layout,
    String? venueName,
    Object? logoPath = _absent,
    String? tagline,
  }) => CoverSection(
    id: id,
    name: name ?? this.name,
    hidden: hidden ?? this.hidden,
    layout: layout ?? this.layout,
    venueName: venueName ?? this.venueName,
    logoPath: logoPath == _absent ? this.logoPath : logoPath as String?,
    tagline: tagline ?? this.tagline,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverSection &&
          name == other.name &&
          hidden == other.hidden &&
          layout == other.layout &&
          venueName == other.venueName &&
          logoPath == other.logoPath &&
          tagline == other.tagline;

  @override
  int get hashCode =>
      Object.hash(name, hidden, layout, venueName, logoPath, tagline);
}
