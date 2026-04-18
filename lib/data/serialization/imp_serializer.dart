import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/document_settings.dart';
import 'package:imprint/data/models/format_settings.dart';
import 'package:imprint/data/models/items/event_item.dart';
import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/items/wine_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:yaml/yaml.dart';

class ImpSerializerException implements Exception {
  ImpSerializerException(this.message);
  final String message;
  @override
  String toString() => 'ImpSerializerException: $message';
}

class ImpSerializer {
  ImpSerializer._();

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  static Document fromYaml(String content) {
    final YamlMap map;
    try {
      map = loadYaml(content) as YamlMap;
    } catch (e) {
      throw ImpSerializerException('Invalid YAML: $e');
    }

    final version = map['version'] as int? ?? 1;
    if (version > 1) {
      throw ImpSerializerException(
        'Unsupported file version $version. Please update imprint.',
      );
    }

    final fee = _toDouble(map['fee']);
    final footerNote = map['footer_note'] as String?;
    final settings = _parseSettings(map['settings']);
    final rawSections = map['sections'] as YamlList? ?? YamlList();
    final sections = rawSections.map((s) => _parseSection(s as YamlMap)).toList();

    return Document(
      version: version,
      fee: fee,
      footerNote: footerNote,
      settings: settings,
      sections: sections,
    );
  }

  static DocumentSettings _parseSettings(dynamic raw) {
    if (raw == null) return DocumentSettings.defaults;
    final map = raw as YamlMap;
    return DocumentSettings(
      a4: _parseFormatSettings(map['a4'], FormatSettings.a4Defaults),
      a5: _parseFormatSettings(map['a5'], FormatSettings.a5Defaults),
      activeFormat: PdfFormat.fromString(map['active_format'] as String? ?? 'a4'),
      enableA4: map['enable_a4'] as bool? ?? true,
      enableA5: map['enable_a5'] as bool? ?? true,
      enableS3Upload: map['enable_s3_upload'] as bool? ?? true,
      priceSymbol: map['price_symbol'] as String? ?? '€',
    );
  }

  static FormatSettings _parseFormatSettings(dynamic raw, FormatSettings defaults) {
    if (raw == null) return defaults;
    final map = raw as YamlMap;
    return FormatSettings(
      titleFontSize: _toDouble(map['title_font_size']) ?? defaults.titleFontSize,
      primaryColor: _hexToArgb(map['primary_color'] as String?) ?? defaults.primaryColor,
      sectionsPerPage: map['sections_per_page'] as int? ?? defaults.sectionsPerPage,
      showFooter: map['show_footer'] as bool? ?? defaults.showFooter,
      showFee: map['show_fee'] as bool? ?? defaults.showFee,
      itemFontSize: _toDouble(map['item_font_size']) ?? defaults.itemFontSize,
      itemColor: _hexToArgb(map['item_color'] as String?) ?? defaults.itemColor,
      descFontSize: _toDouble(map['desc_font_size']) ?? defaults.descFontSize,
      descColor: _hexToArgb(map['desc_color'] as String?) ?? defaults.descColor,
      footerFontSize: _toDouble(map['footer_font_size']) ?? defaults.footerFontSize,
      footerColor: _hexToArgb(map['footer_color'] as String?) ?? defaults.footerColor,
      logoSize: _toDouble(map['logo_size']) ?? defaults.logoSize,
      backgroundColor: _hexToArgb(map['background_color'] as String?) ?? defaults.backgroundColor,
    );
  }

  static Section _parseSection(YamlMap map) {
    final type = map['type'] as String? ?? 'regular';
    final name = map['name'] as String? ?? '';
    final hidden = map['hidden'] as bool? ?? false;
    final layout = SectionLayout.fromString(map['layout'] as String? ?? 'inline');

    return switch (type) {
      'special_selection' => SpecialSelection(
        name: name,
        hidden: hidden,
        layout: layout,
        sharedPrice: _toDouble(map['shared_price']) ?? 0,
        note: map['note'] as String? ?? '',
        items: _parseMenuItems(map['items']),
      ),
      'wine_list' => WineSection(
        name: name,
        hidden: hidden,
        layout: layout,
        items: _parseWineItems(map['items']),
      ),
      'event_program' => EventSection(
        name: name,
        hidden: hidden,
        layout: layout,
        items: _parseEventItems(map['items']),
      ),
      'cover' => CoverSection(
        name: name,
        hidden: hidden,
        layout: layout,
        venueName: map['venue_name'] as String? ?? '',
        logoPath: map['logo'] as String?,
        tagline: map['tagline'] as String? ?? '',
      ),
      _ => RegularSection(
        name: name,
        hidden: hidden,
        layout: layout,
        items: _parseMenuItems(map['items']),
      ),
    };
  }

  static List<MenuItem> _parseMenuItems(dynamic raw) {
    if (raw == null) return [];
    return (raw as YamlList).map((item) {
      final m = item as YamlMap;
      return MenuItem(
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        price: _toDouble(m['price']) ?? 0,
        allergens: _parseAllergens(m['allergens']),
      );
    }).toList();
  }

  static List<WineItem> _parseWineItems(dynamic raw) {
    if (raw == null) return [];
    return (raw as YamlList).map((item) {
      final m = item as YamlMap;
      return WineItem(
        name: m['name'] as String? ?? '',
        price: _toDouble(m['price']) ?? 0,
      );
    }).toList();
  }

  static List<EventItem> _parseEventItems(dynamic raw) {
    if (raw == null) return [];
    return (raw as YamlList).map((item) {
      final m = item as YamlMap;
      return EventItem(
        name: m['name'] as String? ?? '',
        time: m['time'] as String?,
        price: _toDouble(m['price']),
      );
    }).toList();
  }

  static List<int> _parseAllergens(dynamic raw) {
    if (raw == null) return [];
    return (raw as YamlList).map((e) => e as int).toList();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  static String toYaml(Document doc) {
    final buf = StringBuffer();

    buf.writeln('version: ${doc.version}');
    if (doc.fee != null && doc.fee! > 0) {
      buf.writeln('fee: ${_formatNumber(doc.fee!)}');
    }
    if (doc.footerNote != null && doc.footerNote!.isNotEmpty) {
      buf.writeln('footer_note: ${_quoteString(doc.footerNote!)}');
    }

    buf.writeln();
    buf.writeln('settings:');
    buf.writeln('  active_format: ${doc.settings.activeFormat.toYamlValue()}');
    buf.writeln('  enable_a4: ${doc.settings.enableA4}');
    buf.writeln('  enable_a5: ${doc.settings.enableA5}');
    buf.writeln('  enable_s3_upload: ${doc.settings.enableS3Upload}');
    buf.writeln('  price_symbol: "${doc.settings.priceSymbol}"');
    buf.writeln('  a4:');
    _writeFormatSettings(buf, doc.settings.a4, indent: '    ');
    buf.writeln('  a5:');
    _writeFormatSettings(buf, doc.settings.a5, indent: '    ');

    buf.writeln();
    buf.writeln('sections:');
    for (final section in doc.sections) {
      _writeSection(buf, section);
    }

    return buf.toString();
  }

  static void _writeFormatSettings(StringBuffer buf, FormatSettings s, {required String indent}) {
    buf.writeln('${indent}title_font_size: ${_formatNumber(s.titleFontSize)}');
    buf.writeln('${indent}primary_color: "${_argbToHex(s.primaryColor)}"');
    buf.writeln('${indent}sections_per_page: ${s.sectionsPerPage}');
    buf.writeln('${indent}show_footer: ${s.showFooter}');
    buf.writeln('${indent}show_fee: ${s.showFee}');
    buf.writeln('${indent}item_font_size: ${_formatNumber(s.itemFontSize)}');
    buf.writeln('${indent}item_color: "${_argbToHex(s.itemColor)}"');
    buf.writeln('${indent}desc_font_size: ${_formatNumber(s.descFontSize)}');
    buf.writeln('${indent}desc_color: "${_argbToHex(s.descColor)}"');
    buf.writeln('${indent}footer_font_size: ${_formatNumber(s.footerFontSize)}');
    buf.writeln('${indent}footer_color: "${_argbToHex(s.footerColor)}"');
    buf.writeln('${indent}logo_size: ${_formatNumber(s.logoSize)}');
    buf.writeln('${indent}background_color: "${_argbToHex(s.backgroundColor)}"');
  }

  static void _writeSection(StringBuffer buf, Section section) {
    buf.writeln('  - type: ${section.typeKey}');
    if (section.name.isNotEmpty) buf.writeln('    name: ${_quoteString(section.name)}');
    if (section.hidden) buf.writeln('    hidden: true');
    buf.writeln('    layout: ${section.layout.toYamlValue()}');

    switch (section) {
      case RegularSection s:
        _writeMenuItems(buf, s.items);
      case SpecialSelection s:
        buf.writeln('    shared_price: ${_formatNumber(s.sharedPrice)}');
        if (s.note.isNotEmpty) buf.writeln('    note: ${_quoteString(s.note)}');
        _writeMenuItems(buf, s.items);
      case WineSection s:
        _writeWineItems(buf, s.items);
      case EventSection s:
        _writeEventItems(buf, s.items);
      case CoverSection s:
        if (s.venueName.isNotEmpty) buf.writeln('    venue_name: ${_quoteString(s.venueName)}');
        if (s.logoPath != null) buf.writeln('    logo: ${_quoteString(s.logoPath!)}');
        if (s.tagline.isNotEmpty) buf.writeln('    tagline: ${_quoteString(s.tagline)}');
    }
  }

  static void _writeMenuItems(StringBuffer buf, List<MenuItem> items) {
    if (items.isEmpty) {
      buf.writeln('    items: []');
      return;
    }
    buf.writeln('    items:');
    for (final item in items) {
      buf.writeln('      - name: ${_quoteString(item.name)}');
      if (item.description.isNotEmpty) {
        buf.writeln('        description: ${_quoteString(item.description)}');
      }
      buf.writeln('        price: ${_formatNumber(item.price)}');
      buf.writeln('        allergens: [${item.allergens.join(', ')}]');
    }
  }

  static void _writeWineItems(StringBuffer buf, List<WineItem> items) {
    if (items.isEmpty) {
      buf.writeln('    items: []');
      return;
    }
    buf.writeln('    items:');
    for (final item in items) {
      buf.writeln('      - name: ${_quoteString(item.name)}');
      buf.writeln('        price: ${_formatNumber(item.price)}');
    }
  }

  static void _writeEventItems(StringBuffer buf, List<EventItem> items) {
    if (items.isEmpty) {
      buf.writeln('    items: []');
      return;
    }
    buf.writeln('    items:');
    for (final item in items) {
      buf.writeln('      - name: ${_quoteString(item.name)}');
      if (item.time != null) buf.writeln('        time: ${_quoteString(item.time!)}');
      if (item.price != null) buf.writeln('        price: ${_formatNumber(item.price!)}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return null;
  }

  /// Formats a number: two decimal places for whole numbers, raw toString otherwise.
  static String _formatNumber(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(2) : v.toString();

  /// Wraps a string in double quotes with YAML double-quoted scalar escaping.
  static String _quoteString(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    return '"$escaped"';
  }

  /// Converts a hex color string like "#8E6B46" or "#FF8E6B46" to an ARGB int.
  static int? _hexToArgb(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return int.parse('FF$clean', radix: 16);
    if (clean.length == 8) return int.parse(clean, radix: 16);
    return null;
  }

  /// Converts an ARGB int to a hex string like "#8E6B46" (drops alpha if FF).
  static String _argbToHex(int argb) {
    final alpha = (argb >> 24) & 0xFF;
    final rgb = argb & 0xFFFFFF;
    final hex = rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
    return alpha == 0xFF ? '#$hex' : '#${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}$hex';
  }
}
