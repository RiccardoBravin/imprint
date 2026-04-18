import 'package:imprint/data/models/items/menu_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/services/pdf/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildRegularSection(
  RegularSection section,
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
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionHeader(section.name, primary, fonts,
          titleFontSize: titleFontSize, narrowDivider: narrowDivider),
      pw.SizedBox(height: 8),
      ...section.items.map(
        (item) => _itemRow(
          item,
          fonts,
          itemFontSize: itemFontSize,
          itemColor: itemColor,
          descFontSize: descFontSize,
          descColor: descColor,
          priceSymbol: priceSymbol,
        ),
      ),
    ],
  );
}

pw.Widget _sectionHeader(
  String name,
  PdfColor primary,
  PdfFonts fonts, {
  double titleFontSize = PdfTheme.sectionTitleSize,
  bool narrowDivider = false,
}) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            name,
            style: PdfTheme.sectionTitleStyle(
              primary,
              titleFontSize,
              fonts.corinthia,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        _divider(narrowDivider),
        pw.SizedBox(height: 2),
      ],
    );

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
  String priceSymbol = '€',
}) {
  final allergenLabel = item.allergens.isEmpty
      ? ''
      : '(${item.allergens.map((int a) => (a + 1).toString()).join(', ')})';

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: item.name,
                      style: PdfTheme.itemNameStyle(
                        fonts.sourceSerif,
                        fontSize: itemFontSize,
                        color: itemColor,
                      ),
                    ),
                    if (allergenLabel.isNotEmpty)
                      pw.TextSpan(
                        text: '  $allergenLabel',
                        style: PdfTheme.allergenStyle(fonts.sourceSerif),
                      ),
                  ],
                ),
              ),
              if (item.description.isNotEmpty)
                pw.Text(
                  item.description,
                  style: PdfTheme.itemDescStyle(
                    fonts.sourceSerif,
                    fontSize: descFontSize,
                    color: descColor,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          PdfTheme.formatPrice(item.price, symbol: priceSymbol),
          style: PdfTheme.priceStyle(fonts.sourceSerif,
              fontSize: itemFontSize, color: itemColor),
        ),
      ],
    ),
  );
}
