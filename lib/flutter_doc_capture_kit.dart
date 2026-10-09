/// On-device OCR and searchable PDF export for document images.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';

export 'src/text_pdf.dart';
export 'src/image_preparation.dart';
export 'src/document_preparation_screen.dart';

/// One recognized line in normalized image pixel coordinates.
class DocumentLine {
  const DocumentLine({required this.text, required this.bounds});
  final String text;
  final Rect bounds;
  DocumentLine withText(String value) =>
      DocumentLine(text: value, bounds: bounds);
}

/// An upright image and its recognized lines. Keep image and bounds together.
class CapturedDocument {
  CapturedDocument({
    required this.imageBytes,
    required this.width,
    required this.height,
    required List<DocumentLine> lines,
  }) : lines = List.unmodifiable(lines);
  final Uint8List imageBytes;
  final int width;
  final int height;
  final List<DocumentLine> lines;
  CapturedDocument withLines(List<DocumentLine> value) => CapturedDocument(
    imageBytes: imageBytes,
    width: width,
    height: height,
    lines: value,
  );
}

/// Bakes EXIF orientation before OCR, so image and text share coordinates.
/// Caller owns [workingDirectory] and must delete it when finished.
Future<CapturedDocument> recognizeDocument(
  Uint8List bytes,
  Directory workingDirectory,
) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image format.');
  var upright = img.bakeOrientation(decoded);
  if (upright.width > 2400 || upright.height > 2400) {
    upright = img.copyResize(
      upright,
      width: upright.width >= upright.height ? 2400 : null,
      height: upright.height > upright.width ? 2400 : null,
    );
  }
  final normalized = Uint8List.fromList(img.encodeJpg(upright, quality: 92));
  await workingDirectory.create(recursive: true);
  final file = File(
    '${workingDirectory.path}/ocr-${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    await file.writeAsBytes(normalized);
    final result = await recognizer.processImage(
      InputImage.fromFilePath(file.path),
    );
    return CapturedDocument(
      imageBytes: normalized,
      width: upright.width,
      height: upright.height,
      lines: [
        for (final block in result.blocks)
          for (final line in block.lines)
            DocumentLine(text: line.text, bounds: line.boundingBox),
      ],
    );
  } finally {
    await recognizer.close();
    if (await file.exists()) await file.delete();
  }
}

/// Exports the image with an invisible, searchable text layer.
/// Prototype supports printable ASCII. Unsupported characters produce an
/// explicit error instead of silently losing searchable text.
Future<Uint8List> exportSearchablePdf(CapturedDocument document) async {
  if (document.width <= 0 || document.height <= 0) {
    throw ArgumentError('Image dimensions must be positive.');
  }
  final pdf = PdfDocument(compress: false);
  final scale = 595.0 / document.width;
  final height = document.height * scale;
  final page = PdfPage(
    pdf,
    pageFormat: PdfPageFormat(595, height, marginAll: 0),
  );
  final canvas = page.getGraphics();
  canvas.drawImage(
    PdfImage.file(pdf, bytes: document.imageBytes),
    0,
    0,
    595,
    height,
  );
  final font = PdfFont.helvetica(pdf);
  for (final line in document.lines) {
    final text = line.text.trim();
    if (text.isEmpty) continue;
    if (text.runes.any((c) => c < 32 || c > 126)) {
      throw const FormatException(
        'PDF prototype supports English ASCII text only. Replace special characters before export.',
      );
    }
    final rect = line.bounds;
    if (rect.width <= 0 || rect.height <= 0) continue;
    final size = rect.height * scale / (font.ascent - font.descent);
    final naturalWidth = font.stringMetrics(text).width * size;
    canvas.drawString(
      font,
      size,
      text,
      rect.left * scale,
      height - rect.bottom * scale - font.descent * size,
      scale: rect.width * scale / naturalWidth,
      mode: PdfTextRenderingMode.invisible,
    );
  }
  return pdf.save();
}
