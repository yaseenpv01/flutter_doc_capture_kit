import 'dart:typed_data';
import 'package:pdf/pdf.dart';

/// Typesets extracted/corrected text on white A4 pages, without a source image.
/// Reflows lines; this does not reconstruct tables, logos or original typography.
Future<Uint8List> exportTextPdf(
  List<String> lines, {
  String title = 'Document',
}) async {
  final body = lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (body.isEmpty) {
    throw const FormatException(
      'No extracted text to export. Retake the image or choose Original scan.',
    );
  }
  final heading = title.trim().isEmpty ? 'Document' : title.trim();
  for (final text in [heading, ...body]) {
    if (text.runes.any(
      (c) => (c < 32 && c != 10 && c != 13 && c != 9) || c > 126,
    )) {
      throw const FormatException(
        'This prototype supports English ASCII text. Replace special characters before exporting.',
      );
    }
  }
  final pdf = PdfDocument(compress: false);
  final regular = PdfFont.helvetica(pdf);
  final bold = PdfFont.helveticaBold(pdf);
  const margin = 48.0, pageWidth = 595.0, pageHeight = 842.0;
  const contentWidth = pageWidth - 2 * margin;
  var number = 0;
  late PdfGraphics canvas;
  var y = 0.0;
  void newPage() {
    number++;
    final page = PdfPage(
      pdf,
      pageFormat: const PdfPageFormat(pageWidth, pageHeight),
    );
    canvas = page.getGraphics();
    canvas.drawString(regular, 9, 'Page $number', margin, 26);
    y = pageHeight - margin;
  }

  void write(String text, PdfFont font, double size, double leading) {
    for (final paragraph in text.replaceAll('\r', '').split('\n')) {
      for (final line in _wrap(
        paragraph.replaceAll('\t', '    '),
        font,
        size,
        contentWidth,
      )) {
        if (y - leading < margin) newPage();
        y -= leading;
        canvas.drawString(font, size, line, margin, y);
      }
    }
  }

  newPage();
  write(heading, bold, 20, 26);
  y -= 18;
  for (final line in body) {
    write(line, regular, 12, 18);
    y -= 5;
  }
  return pdf.save();
}

Iterable<String> _wrap(
  String text,
  PdfFont font,
  double size,
  double width,
) sync* {
  if (text.isEmpty) {
    yield '';
    return;
  }
  var remaining = text;
  while (remaining.isNotEmpty) {
    if (font.stringMetrics(remaining).width * size <= width) {
      yield remaining;
      break;
    }
    var low = 1, high = remaining.length;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (font.stringMetrics(remaining.substring(0, middle)).width * size <=
          width) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    var split = low;
    final space = remaining.lastIndexOf(' ', split);
    if (space > 0) split = space;
    yield remaining.substring(0, split).trimRight();
    remaining = remaining.substring(split).trimLeft();
  }
}
