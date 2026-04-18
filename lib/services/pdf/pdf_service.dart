import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:imprint/core/pdf_format.dart';
import 'package:imprint/data/models/document.dart';
import 'package:imprint/data/models/format_settings.dart';
import 'package:imprint/data/models/section.dart';
import 'package:imprint/services/pdf/pdf_theme.dart';
import 'package:imprint/services/pdf/renderers/cover_renderer.dart';
import 'package:imprint/services/pdf/renderers/event_renderer.dart';
import 'package:imprint/services/pdf/renderers/regular_renderer.dart';
import 'package:imprint/services/pdf/renderers/special_selection_renderer.dart';
import 'package:imprint/services/pdf/renderers/wine_renderer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class _RenderArgs {
  const _RenderArgs({
    required this.doc,
    required this.format,
    required this.corinthiaBytes,
    required this.sourceSerifBytes,
    required this.logoSvg,
  });
  final Document doc;
  final PdfFormat format;
  final Uint8List corinthiaBytes;
  final Uint8List sourceSerifBytes;
  final String logoSvg;
}

Future<Uint8List> _renderInBackground(_RenderArgs args) async {
  final fonts = PdfFonts(
    corinthia: pw.Font.ttf(args.corinthiaBytes.buffer.asByteData()),
    sourceSerif: pw.Font.ttf(args.sourceSerifBytes.buffer.asByteData()),
  );
  return PdfService._buildPdf(args.doc, args.format, fonts, args.logoSvg);
}

class PdfService {
  PdfService._();

  static Future<Uint8List> render(Document doc, PdfFormat format) async {
    final corinthiaData =
        await rootBundle.load('assets/fonts/Corinthia-Regular.ttf');
    final sourceSerifData =
        await rootBundle.load('assets/fonts/SourceSerif4-Regular.ttf');
    final logoSvg = await rootBundle.loadString('assets/Logo.svg');
    return compute(
      _renderInBackground,
      _RenderArgs(
        doc: doc,
        format: format,
        corinthiaBytes: corinthiaData.buffer.asUint8List(),
        sourceSerifBytes: sourceSerifData.buffer.asUint8List(),
        logoSvg: logoSvg,
      ),
    );
  }

  static Future<Uint8List> _buildPdf(
    Document doc,
    PdfFormat format,
    PdfFonts fonts,
    String logoSvg,
  ) async {

    final pdf = pw.Document(compress: true);
    final pageFormat =
        format == PdfFormat.a4 ? PdfPageFormat.a4 : PdfPageFormat.a5;
    final settings =
        format == PdfFormat.a4 ? doc.settings.a4 : doc.settings.a5;
    final primary = argbToPdfColor(settings.primaryColor);
    final margin =
        format == PdfFormat.a4 ? PdfTheme.marginA4 : PdfTheme.marginA5;
    final isA4 = format == PdfFormat.a4;
    final narrowDivider = !isA4; // 2/3-width divider only for A5

    final ctx = _Ctx(
      doc: doc,
      format: format,
      pageFormat: pageFormat,
      settings: settings,
      primary: primary,
      margin: margin,
      priceSymbol: doc.settings.priceSymbol,
      fonts: fonts,
      logoSvg: logoSvg,
      narrowDivider: narrowDivider,
      titleFontSize: settings.titleFontSize,
      itemColor: argbToPdfColor(settings.itemColor),
      descColor: argbToPdfColor(settings.descColor),
      footerColor: argbToPdfColor(settings.footerColor),
      logoSize: settings.logoSize,
      backgroundColor: argbToPdfColor(settings.backgroundColor),
    );

    final visible = doc.sections.where((s) => !s.hidden).toList();

    bool isFirstPage = true;
    int i = 0;
    while (i < visible.length) {
      final section = visible[i];

      if (section is CoverSection) {
        pdf.addPage(_coverPage(ctx, section));
        isFirstPage = false;
        i++;
        continue;
      }

      switch (section.layout) {
        case SectionLayout.fullPage:
          pdf.addPage(_fullPage(ctx, section, isFirstPage: isFirstPage));
          isFirstPage = false;
          i++;

        case SectionLayout.inline:
          final batch = <Section>[];
          while (i < visible.length &&
              visible[i].layout == SectionLayout.inline &&
              batch.length < settings.sectionsPerPage) {
            batch.add(visible[i]);
            i++;
          }
          pdf.addPage(_inlinePage(ctx, batch, isFirstPage: isFirstPage));
          isFirstPage = false;

        case SectionLayout.flow:
          pdf.addPage(_flowPage(ctx, section, isFirstPage: isFirstPage));
          isFirstPage = false;
          i++;
      }
    }

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Page builders
  // ---------------------------------------------------------------------------

  static pw.PageTheme _pageTheme(_Ctx ctx) => pw.PageTheme(
        pageFormat: ctx.pageFormat,
        margin: pw.EdgeInsets.all(ctx.margin),
        buildBackground: (_) => pw.Container(color: ctx.backgroundColor),
      );

  static pw.Page _coverPage(_Ctx ctx, CoverSection section) => pw.Page(
        pageTheme: _pageTheme(ctx),
        build: (_) =>
            buildCoverContent(section, ctx.primary, ctx.titleFontSize),
      );

  static pw.Page _fullPage(
    _Ctx ctx,
    Section section, {
    bool isFirstPage = false,
  }) =>
      pw.Page(
        pageTheme: _pageTheme(ctx),
        build: (pw.Context _) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (ctx.format == PdfFormat.a4)
              _a4PageHeader(ctx, isFirstPage: isFirstPage),
            pw.Expanded(child: _sectionContent(ctx, section)),
            if (_shouldShowFooter(ctx)) _footer(ctx),
          ],
        ),
      );

  static pw.Page _inlinePage(
    _Ctx ctx,
    List<Section> sections, {
    bool isFirstPage = false,
  }) =>
      pw.Page(
        pageTheme: _pageTheme(ctx),
        build: (pw.Context _) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (ctx.format == PdfFormat.a4)
              _a4PageHeader(ctx, isFirstPage: isFirstPage),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (int idx = 0; idx < sections.length; idx++) ...[
                    if (idx > 0) pw.SizedBox(height: 20),
                    pw.Expanded(
                      child: _sectionContent(ctx, sections[idx]),
                    ),
                  ],
                ],
              ),
            ),
            if (_shouldShowFooter(ctx)) _footer(ctx),
          ],
        ),
      );

  static pw.MultiPage _flowPage(
    _Ctx ctx,
    Section section, {
    bool isFirstPage = false,
  }) =>
      pw.MultiPage(
        pageTheme: _pageTheme(ctx),
        header: ctx.format == PdfFormat.a4
            ? (pw.Context context) => _a4PageHeader(
                  ctx,
                  isFirstPage: isFirstPage && context.pageNumber == 1,
                )
            : null,
        footer: _shouldShowFooter(ctx) ? (_) => _footer(ctx) : null,
        build: (_) => [_sectionContent(ctx, section)],
      );

  // ---------------------------------------------------------------------------
  // A4 page header (logo on every page; MENU text only on first page)
  // ---------------------------------------------------------------------------

  static pw.Widget _a4PageHeader(_Ctx ctx, {bool isFirstPage = false}) {
    final logo = pw.SvgImage(svg: ctx.logoSvg, width: ctx.logoSize, height: ctx.logoSize);

    if (!isFirstPage) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          logo,
          pw.SizedBox(height: 12),
        ],
      );
    }

    // First page: "Menù" (SourceSerif) left + logo right.
    // Text decoration underline follows the text width exactly.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Menù',
              style: pw.TextStyle(
                font: ctx.fonts.sourceSerif,
                fontSize: 48,
                color: ctx.primary,
                decoration: pw.TextDecoration.underline,
                decorationColor: ctx.primary,
                decorationStyle: pw.TextDecorationStyle.solid,
              ),
            ),
            pw.Spacer(),
            logo,
          ],
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section dispatcher
  // ---------------------------------------------------------------------------

  static pw.Widget _sectionContent(_Ctx ctx, Section section) =>
      switch (section) {
        CoverSection s =>
          buildCoverContent(s, ctx.primary, ctx.titleFontSize),
        RegularSection s => buildRegularSection(
            s,
            ctx.primary,
            ctx.fonts,
            titleFontSize: ctx.titleFontSize,
            itemFontSize: ctx.settings.itemFontSize,
            itemColor: ctx.itemColor,
            descFontSize: ctx.settings.descFontSize,
            descColor: ctx.descColor,
            priceSymbol: ctx.priceSymbol,
            narrowDivider: ctx.narrowDivider,
          ),
        SpecialSelection s => buildSpecialSelectionContent(
            s,
            ctx.primary,
            ctx.fonts,
            titleFontSize: ctx.titleFontSize,
            itemFontSize: ctx.settings.itemFontSize,
            itemColor: ctx.itemColor,
            descFontSize: ctx.settings.descFontSize,
            descColor: ctx.descColor,
            priceSymbol: ctx.priceSymbol,
            narrowDivider: ctx.narrowDivider,
          ),
        WineSection s => buildWineSectionContent(
            s,
            ctx.primary,
            ctx.fonts,
            titleFontSize: ctx.titleFontSize,
            itemFontSize: ctx.settings.itemFontSize,
            itemColor: ctx.itemColor,
            priceSymbol: ctx.priceSymbol,
            narrowDivider: ctx.narrowDivider,
          ),
        EventSection s => buildEventSectionContent(
            s,
            ctx.primary,
            ctx.fonts,
            titleFontSize: ctx.titleFontSize,
            itemFontSize: ctx.settings.itemFontSize,
            itemColor: ctx.itemColor,
            priceSymbol: ctx.priceSymbol,
            narrowDivider: ctx.narrowDivider,
          ),
      };

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  /// A5 always shows footer (for the logo). A4 only when fee/note is set.
  static bool _shouldShowFooter(_Ctx ctx) {
    if (ctx.format == PdfFormat.a5) return true;
    final hasFee =
        ctx.settings.showFee && ctx.doc.fee != null && ctx.doc.fee! > 0;
    final hasNote = ctx.settings.showFooter && ctx.doc.footerNote != null;
    return hasFee || hasNote;
  }

  static pw.Widget _footer(_Ctx ctx) {
    final feeText =
        (ctx.settings.showFee && ctx.doc.fee != null && ctx.doc.fee! > 0)
            ? 'Coperto: ${PdfTheme.formatPrice(ctx.doc.fee!, symbol: ctx.priceSymbol)}'
            : null;
    final noteText =
        (ctx.settings.showFooter && ctx.doc.footerNote != null)
            ? ctx.doc.footerNote!
            : null;

    final style = PdfTheme.footerStyle(
      ctx.fonts.sourceSerif,
      fontSize: ctx.settings.footerFontSize,
      color: ctx.footerColor,
    );

    if (ctx.format == PdfFormat.a4) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (feeText != null) pw.Text(feeText, style: style),
          if (noteText != null) pw.Text(noteText, style: style),
        ],
      );
    } else {
      // A5: note left | logo centre | coperto right.
      final logoSize = ctx.logoSize;

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: noteText != null
                  ? pw.Text(noteText, style: style)
                  : pw.SizedBox(),
            ),
          ),
          pw.SvgImage(svg: ctx.logoSvg, width: logoSize, height: logoSize),
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: feeText != null
                  ? pw.Text(feeText, style: style, textAlign: pw.TextAlign.right)
                  : pw.SizedBox(),
            ),
          ),
        ],
      );
    }
  }
}

// ---------------------------------------------------------------------------

class _Ctx {
  const _Ctx({
    required this.doc,
    required this.format,
    required this.pageFormat,
    required this.settings,
    required this.primary,
    required this.margin,
    required this.priceSymbol,
    required this.fonts,
    required this.logoSvg,
    required this.narrowDivider,
    required this.titleFontSize,
    required this.itemColor,
    required this.descColor,
    required this.footerColor,
    required this.logoSize,
    required this.backgroundColor,
  });

  final Document doc;
  final PdfFormat format;
  final PdfPageFormat pageFormat;
  final FormatSettings settings;
  final PdfColor primary;
  final double margin;
  final String priceSymbol;
  final PdfFonts fonts;
  final String logoSvg;
  final bool narrowDivider;
  final double titleFontSize;
  final PdfColor itemColor;
  final PdfColor descColor;
  final PdfColor footerColor;
  final double logoSize;
  final PdfColor backgroundColor;
}
