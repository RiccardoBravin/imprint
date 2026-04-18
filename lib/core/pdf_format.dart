/// The page format a document targets.
enum PdfFormat {
  a4,
  a5;

  String toYamlValue() => name; // 'a4' or 'a5'

  static PdfFormat fromString(String s) =>
      s == 'a5' ? PdfFormat.a5 : PdfFormat.a4;
}
