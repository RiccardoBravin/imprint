import 'dart:io';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/services/pdf/pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [CoverSection] as a full-page cover.
pw.Widget buildCoverContent(
  CoverSection section,
  PdfColor primary,
  double titleFontSize,
) {
  final logoWidget = _loadLogo(section.logoPath);

  return pw.Center(
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoWidget != null) ...[
          logoWidget,
          pw.SizedBox(height: 24),
        ],
        pw.Text(
          section.venueName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: pw.Font.timesBold(),
            fontSize: titleFontSize,
            color: primary,
            letterSpacing: 2,
          ),
        ),
        if (section.tagline.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            section.tagline,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: pw.Font.timesItalic(),
              fontSize: titleFontSize * 0.4,
              color: PdfTheme.midGrey,
              letterSpacing: 1,
            ),
          ),
        ],
        pw.SizedBox(height: 32),
        pw.Container(
          width: 60,
          height: 1.5,
          color: primary,
        ),
      ],
    ),
  );
}

pw.Widget? _loadLogo(String? path) {
  if (path == null || path.isEmpty) return null;
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = file.readAsBytesSync();
    final image = pw.MemoryImage(bytes);
    return pw.Image(image, width: 120, height: 120, fit: pw.BoxFit.contain);
  } catch (_) {
    return null;
  }
}
