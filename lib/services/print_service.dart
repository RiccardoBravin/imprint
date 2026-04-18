import 'dart:typed_data';
import 'package:printing/printing.dart';

/// Sends a PDF (as bytes) to the system print dialog.
class PrintService {
  PrintService._();

  static Future<void> printPdf(Uint8List bytes, {String name = 'Document'}) =>
      Printing.layoutPdf(onLayout: (_) => bytes, name: name);
}
