import 'package:flutter/foundation.dart';
import 'package:imprint/data/models/document_settings.dart';
import 'package:imprint/data/models/section.dart';

class Document {
  const Document({
    this.version = 1,
    this.fee,
    this.footerNote,
    required this.settings,
    required this.sections,
  });

  final int version;
  final double? fee;
  final String? footerNote;
  final DocumentSettings settings;
  final List<Section> sections;

  static Document empty() => const Document(
    settings: DocumentSettings.defaults,
    sections: [],
  );

  static const _clear = Object();

  Document copyWith({
    int? version,
    Object? fee = _clear,
    Object? footerNote = _clear,
    DocumentSettings? settings,
    List<Section>? sections,
  }) => Document(
    version: version ?? this.version,
    fee: fee == _clear ? this.fee : fee as double?,
    footerNote: footerNote == _clear ? this.footerNote : footerNote as String?,
    settings: settings ?? this.settings,
    sections: sections ?? this.sections,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          version == other.version &&
          fee == other.fee &&
          footerNote == other.footerNote &&
          settings == other.settings &&
          listEquals(sections, other.sections);

  @override
  int get hashCode => Object.hash(
    version,
    fee,
    footerNote,
    settings,
    Object.hashAll(sections),
  );
}
