import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/format_settings.dart';

class DocumentSettings {
  const DocumentSettings({
    required this.a4,
    required this.a5,
    this.activeFormat = PdfFormat.a4,
    this.enableA4 = true,
    this.enableA5 = true,
    this.enableS3Upload = true,
    this.priceSymbol = '€',
  });

  final FormatSettings a4;
  final FormatSettings a5;

  /// Which format is currently active for preview and export.
  final PdfFormat activeFormat;

  /// Whether the A4 format is available for print/export/upload.
  final bool enableA4;

  /// Whether the A5 format is available for print/export/upload.
  final bool enableA5;

  /// Whether S3 cloud upload is available for this document.
  final bool enableS3Upload;

  /// Currency symbol shown before prices in PDFs (€, $, £).
  final String priceSymbol;

  FormatSettings get active => activeFormat == PdfFormat.a4 ? a4 : a5;

  static const DocumentSettings defaults = DocumentSettings(
    a4: FormatSettings.a4Defaults,
    a5: FormatSettings.a5Defaults,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentSettings &&
          a4 == other.a4 &&
          a5 == other.a5 &&
          activeFormat == other.activeFormat &&
          enableA4 == other.enableA4 &&
          enableA5 == other.enableA5 &&
          enableS3Upload == other.enableS3Upload &&
          priceSymbol == other.priceSymbol;

  @override
  int get hashCode =>
      Object.hash(a4, a5, activeFormat, enableA4, enableA5, enableS3Upload, priceSymbol);

  DocumentSettings copyWith({
    FormatSettings? a4,
    FormatSettings? a5,
    PdfFormat? activeFormat,
    bool? enableA4,
    bool? enableA5,
    bool? enableS3Upload,
    String? priceSymbol,
  }) => DocumentSettings(
    a4: a4 ?? this.a4,
    a5: a5 ?? this.a5,
    activeFormat: activeFormat ?? this.activeFormat,
    enableA4: enableA4 ?? this.enableA4,
    enableA5: enableA5 ?? this.enableA5,
    enableS3Upload: enableS3Upload ?? this.enableS3Upload,
    priceSymbol: priceSymbol ?? this.priceSymbol,
  );
}
