import 'package:imprint/data/models/items/event_item.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/services/pdf/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildEventSectionContent(
  EventSection section,
  PdfColor primary,
  PdfFonts fonts, {
  double titleFontSize = PdfTheme.sectionTitleSize,
  double itemFontSize = PdfTheme.itemNameSize,
  PdfColor itemColor = PdfTheme.black,
  String priceSymbol = '€',
  bool narrowDivider = false,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
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
      ...section.items.map(
        (item) => _eventRow(item, fonts,
            itemFontSize: itemFontSize,
            itemColor: itemColor,
            priceSymbol: priceSymbol),
      ),
    ],
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

pw.Widget _eventRow(
  EventItem item,
  PdfFonts fonts, {
  double itemFontSize = PdfTheme.itemNameSize,
  PdfColor itemColor = PdfTheme.black,
  String priceSymbol = '€',
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (item.time != null && item.time!.isNotEmpty) ...[
            pw.SizedBox(
              width: 48,
              child: pw.Text(
                item.time!,
                style: PdfTheme.itemNameStyle(
                  fonts.sourceSerif,
                  fontSize: itemFontSize,
                  color: PdfTheme.midGrey,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            child: pw.Text(
              item.name,
              style: PdfTheme.itemNameStyle(fonts.sourceSerif,
                  fontSize: itemFontSize, color: itemColor),
            ),
          ),
          if (item.price != null)
            pw.Text(
              PdfTheme.formatPrice(item.price!, symbol: priceSymbol),
              style: PdfTheme.priceStyle(fonts.sourceSerif,
                  fontSize: itemFontSize, color: itemColor),
            ),
        ],
      ),
    );
