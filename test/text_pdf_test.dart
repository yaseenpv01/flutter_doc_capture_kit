import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';

void main() {
  test('text export has visible text and no embedded photograph', () async {
    final bytes = await exportTextPdf([
      'Corrected receipt',
      'Notebook 15.00 AED',
      'Pen 5.00 AED',
      'Total 20.00 AED',
    ], title: 'Sample receipt');
    final source = latin1.decode(bytes);
    expect(source, contains('Corrected receipt'));
    expect(RegExp(r'/Subtype\s*/Image').hasMatch(source), isFalse);
    expect(source, isNot(contains('3 Tr')));
    Directory('build').createSync();
    File('build/text-document-test.pdf').writeAsBytesSync(bytes);
  });
  test('long content paginates and preserves final line', () async {
    final bytes = await exportTextPdf([
      'W' * 300,
      ...List.generate(120, (i) => 'Line $i'),
      'FINAL MARKER',
    ], title: 'Long document');
    final source = latin1.decode(bytes);
    expect(source, contains('FINAL MARKER'));
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(source).length,
      greaterThan(1),
    );
    File('build/text-long-test.pdf').writeAsBytesSync(bytes);
  });
  test('empty OCR and unsupported characters are explicit errors', () async {
    await expectLater(exportTextPdf(['  ', '']), throwsFormatException);
    await expectLater(exportTextPdf(['مرحبا']), throwsFormatException);
  });
}
