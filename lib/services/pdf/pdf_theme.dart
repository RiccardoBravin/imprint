import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Converts an ARGB int (e.g. 0xFF8E6B46) to a [PdfColor].
PdfColor argbToPdfColor(int argb) {
  final r = ((argb >> 16) & 0xFF) / 255.0;
  final g = ((argb >> 8) & 0xFF) / 255.0;
  final b = (argb & 0xFF) / 255.0;
  return PdfColor(r, g, b);
}

/// Loaded custom fonts used across all PDF renderers.
class PdfFonts {
  const PdfFonts({
    required this.corinthia,
    required this.sourceSerif,
  });

  /// Corinthia — used for section titles and the A4 "MENU" heading.
  final pw.Font corinthia;

  /// Source Serif 4 — used for item names, descriptions, prices, footer.
  final pw.Font sourceSerif;

  static Future<PdfFonts> load() async {
    final corinthiaData =
        await rootBundle.load('assets/fonts/Corinthia-Regular.ttf');
    final sourceSerifData =
        await rootBundle.load('assets/fonts/SourceSerif4-Regular.ttf');
    return PdfFonts(
      corinthia: pw.Font.ttf(corinthiaData),
      sourceSerif: pw.Font.ttf(sourceSerifData),
    );
  }
}

/// Shared style constants for PDF generation.
class PdfTheme {
  PdfTheme._();

  static const double marginA4 = 42.0; // ~15 mm
  static const double marginA5 = 30.0; // ~11 mm

  static const double sectionTitleSize = 30.0;
  static const double itemNameSize = 10.0;
  static const double itemDescSize = 8.5;
  static const double itemPriceSize = 10.0;
  static const double smallLabelSize = 7.5;

  static const PdfColor lightGrey = PdfColor(0.75, 0.75, 0.75);
  static const PdfColor midGrey = PdfColor(0.50, 0.50, 0.50);
  static const PdfColor black = PdfColors.black;

  // ---------------------------------------------------------------------------
  // Text styles — all require loaded fonts
  // ---------------------------------------------------------------------------

  static pw.TextStyle sectionTitleStyle(
    PdfColor color,
    double fontSize,
    pw.Font corinthia,
  ) =>
      pw.TextStyle(
        font: corinthia,
        fontSize: fontSize,
        color: color,
      );

  static pw.TextStyle itemNameStyle(
    pw.Font sourceSerif, {
    double fontSize = itemNameSize,
    PdfColor color = black,
  }) =>
      pw.TextStyle(
        font: sourceSerif,
        fontSize: fontSize,
        color: color,
      );

  static pw.TextStyle itemDescStyle(
    pw.Font sourceSerif, {
    double fontSize = itemDescSize,
    PdfColor color = black,
  }) =>
      pw.TextStyle(
        font: sourceSerif,
        fontSize: fontSize,
        color: color,
      );

  static pw.TextStyle priceStyle(
    pw.Font sourceSerif, {
    double fontSize = itemPriceSize,
    PdfColor color = black,
  }) =>
      pw.TextStyle(
        font: sourceSerif,
        fontSize: fontSize,
        color: color,
      );

  static pw.TextStyle allergenStyle(pw.Font sourceSerif) => pw.TextStyle(
        font: sourceSerif,
        fontSize: smallLabelSize,
        color: midGrey,
      );

  static pw.TextStyle footerStyle(
    pw.Font sourceSerif, {
    double fontSize = smallLabelSize,
    PdfColor color = midGrey,
  }) =>
      pw.TextStyle(
        font: sourceSerif,
        fontSize: fontSize,
        color: color,
      );

  /// Formats a price always as "€12.50" (two decimal places).
  static String formatPrice(double price, {String symbol = '€'}) =>
      '$symbol${price.toStringAsFixed(2)}';

}
