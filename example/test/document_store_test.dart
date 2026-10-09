import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';
import 'package:document_capture_example/document_store.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('capture-store-test-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  SavedDocument fixture(String text) => SavedDocument(
    id: '123',
    title: text,
    updated: DateTime.utc(2026, 10, 6),
    style: DocumentPdfStyle.text,
    pdf: Uint8List.fromList([37, 80, 68, 70]),
    document: CapturedDocument(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      width: 100,
      height: 200,
      lines: [
        DocumentLine(text: text, bounds: const Rect.fromLTWH(10, 20, 30, 40)),
      ],
    ),
  );

  test(
    'fresh store reopens saved PDF, corrected text and source geometry',
    () async {
      await DocumentStore(directory).save(fixture('Corrected'));
      final listing = await DocumentStore(directory).list();
      expect(listing.documents, hasLength(1));
      final saved = listing.documents.single;
      expect(saved.document.lines.single.text, 'Corrected');
      expect(
        saved.document.lines.single.bounds,
        const Rect.fromLTWH(10, 20, 30, 40),
      );
      expect(saved.pdf, [37, 80, 68, 70]);
      expect(saved.document.imageBytes, [1, 2, 3]);
      expect(saved.style, DocumentPdfStyle.text);
    },
  );
  test(
    'updating a document replaces it instead of creating duplicates',
    () async {
      await DocumentStore(directory).save(fixture('First'));
      await DocumentStore(directory).save(fixture('Updated'));
      final result = await DocumentStore(directory).list();
      expect(result.documents, hasLength(1));
      expect(result.documents.single.title, 'Updated');
      expect(
        directory.listSync().where((f) => f.path.endsWith('.pending')),
        isEmpty,
      );
    },
  );
  test('unreadable records do not hide good records', () async {
    await DocumentStore(directory).save(fixture('Good'));
    await File('${directory.path}/broken.json').writeAsString('{bad');
    await File(
      '${directory.path}/interrupted.pending',
    ).writeAsString('partial');
    final result = await DocumentStore(directory).list();
    expect(result.documents, hasLength(1));
    expect(result.unreadableCount, 1);
  });
}
