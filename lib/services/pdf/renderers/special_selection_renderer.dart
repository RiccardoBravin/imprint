import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/services/pdf/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildSpecialSelectionContent(
  SpecialSelection section,
  PdfColor primary,
  PdfFonts fonts, {
  double titleFontSize = PdfTheme.sectionTitleSize,
  double itemFontSize = PdfTheme.itemNameSize,
  PdfColor itemColor = PdfTheme.black,
  double descFontSize = PdfTheme.itemDescSize,
  PdfColor descColor = PdfTheme.black,
  String priceSymbol = '€',
  bool narrowDivider = false,
}) {
  return pw.Center(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Title centered
        pw.Center(
          child: pw.Text(
            section.name,
            style: PdfTheme.sectionTitleStyle(
              primary,
              titleFontSize,
              fonts.corinthia,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        _divider(narrowDivider),
        pw.SizedBox(height: 8),
        // Items
        ...section.items.map(
          (item) => _itemRow(item, fonts,
              itemFontSize: itemFontSize,
              itemColor: itemColor,
              descFontSize: descFontSize,
              descColor: descColor),
        ),
        if (section.sharedPrice > 0) ...[
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              PdfTheme.formatPrice(section.sharedPrice, symbol: priceSymbol),
              style: PdfTheme.priceStyle(
                fonts.sourceSerif,
                fontSize: itemFontSize * 1.4,
                color: primary,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
        ],
        if (section.note.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              section.note,
              textAlign: pw.TextAlign.center,
              style: PdfTheme.itemDescStyle(
                fonts.sourceSerif,
                fontSize: descFontSize,
                color: PdfTheme.midGrey,
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 8),
      ],
    ),
  );
}

pw.Widget _divider(bool narrow) {
  if (!narrow) {
    return pw.Container(height: 0.5, color: PdfTheme.lightGrey);
  }
  return pw.Row(
    children: [
      pw.Expanded(flex: 1, child: pw.SizedBox()),
      pw.Expanded(flex: 4, child: pw.Container(height: 0.5, color: PdfTheme.lightGrey)),
      pw.Expanded(flex: 1, child: pw.SizedBox()),
    ],
  );
}

pw.Widget _itemRow(
  MenuItem item,
  PdfFonts fonts, {
  double itemFontSize = PdfTheme.itemNameSize,
  PdfColor itemColor = PdfTheme.black,
  double descFontSize = PdfTheme.itemDescSize,
  PdfColor descColor = PdfTheme.black,
}) {
  final allergenLabel = item.allergens.isEmpty
      ? ''
      : '(${item.allergens.map((int a) => (a + 1).toString()).join(', ')})';

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          item.name,
          textAlign: pw.TextAlign.center,
          style: PdfTheme.itemNameStyle(fonts.sourceSerif,
              fontSize: itemFontSize, color: itemColor),
        ),
        if (allergenLabel.isNotEmpty)
          pw.Text(
            allergenLabel,
            textAlign: pw.TextAlign.center,
            style: PdfTheme.allergenStyle(fonts.sourceSerif),
          ),
        if (item.description.isNotEmpty)
          pw.Text(
            item.description,
            textAlign: pw.TextAlign.center,
            style: PdfTheme.itemDescStyle(fonts.sourceSerif,
                fontSize: descFontSize, color: descColor),
          ),
      ],
    ),
  );
}
