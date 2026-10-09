import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';
import 'package:image/image.dart' as img;

void main() {
  CapturedDocument fixture(String text) => CapturedDocument(
    imageBytes: Uint8List.fromList(
      img.encodePng(img.Image(width: 600, height: 800)),
    ),
    width: 600,
    height: 800,
    lines: [
      DocumentLine(text: text, bounds: const Rect.fromLTWH(30, 40, 180, 20)),
    ],
  );

  test(
    'corrections replace searchable text without changing original',
    () async {
      final original = fixture('Wrong value');
      final corrected = original.withLines([
        original.lines.first.withText('Invoice 12345'),
      ]);
      expect(original.lines.first.text, 'Wrong value');
      final bytes = await exportSearchablePdf(corrected);
      final source = latin1.decode(bytes);
      expect(source, startsWith('%PDF-'));
      expect(source, contains('Invoice 12345'));
      expect(source, isNot(contains('Wrong value')));
      expect(source, contains('3 Tr'));
      Directory('build').createSync();
      File('build/searchable-test.pdf').writeAsBytesSync(bytes);
    },
  );
  test('unsupported text is rejected rather than lost', () {
    expect(() => exportSearchablePdf(fixture('مرحبا')), throwsFormatException);
  });
  test('empty recognition still exports an image PDF', () async {
    expect(await exportSearchablePdf(fixture('').withLines([])), isNotEmpty);
  });
}
