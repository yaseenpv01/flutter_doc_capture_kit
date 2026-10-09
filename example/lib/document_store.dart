import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';

enum DocumentPdfStyle { text, scan }

class SavedDocument {
  const SavedDocument({
    required this.id,
    required this.title,
    required this.updated,
    required this.style,
    required this.document,
    required this.pdf,
  });
  final String id, title;
  final DateTime updated;
  final DocumentPdfStyle style;
  final CapturedDocument document;
  final Uint8List pdf;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'title': title,
    'updated': updated.toIso8601String(),
    'style': style.name,
    'pdf': base64Encode(pdf),
    'image': base64Encode(document.imageBytes),
    'width': document.width,
    'height': document.height,
    'lines': [
      for (final line in document.lines)
        {
          'text': line.text,
          'bounds': [
            line.bounds.left,
            line.bounds.top,
            line.bounds.right,
            line.bounds.bottom,
          ],
        },
    ],
  };
  factory SavedDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported saved document version.');
    }
    return SavedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      updated: DateTime.parse(json['updated'] as String),
      style: DocumentPdfStyle.values.byName(json['style'] as String),
      pdf: base64Decode(json['pdf'] as String),
      document: CapturedDocument(
        imageBytes: base64Decode(json['image'] as String),
        width: json['width'] as int,
        height: json['height'] as int,
        lines: [
          for (final entry in json['lines'] as List)
            DocumentLine(
              text: entry['text'] as String,
              bounds: Rect.fromLTRB(
                (entry['bounds'][0] as num).toDouble(),
                (entry['bounds'][1] as num).toDouble(),
                (entry['bounds'][2] as num).toDouble(),
                (entry['bounds'][3] as num).toDouble(),
              ),
            ),
        ],
      ),
    );
  }
}

class DocumentListing {
  const DocumentListing(this.documents, this.unreadableCount);
  final List<SavedDocument> documents;
  final int unreadableCount;
}

/// One atomic file per saved document includes its source, edits and PDF.
/// Stored in app-private documents, independent of temporary picker/share files.
class DocumentStore {
  DocumentStore(this.directory);
  final Directory directory;
  Future<void> save(SavedDocument document) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(document.id)) {
      throw ArgumentError('Invalid document ID.');
    }
    await directory.create(recursive: true);
    final pending = File('${directory.path}/${document.id}.pending');
    try {
      await pending.writeAsString(jsonEncode(document.toJson()), flush: true);
      await pending.rename('${directory.path}/${document.id}.json');
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<DocumentListing> list() async {
    if (!await directory.exists()) return const DocumentListing([], 0);
    final documents = <SavedDocument>[];
    var unreadable = 0;
    await for (final entry in directory.list()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      try {
        documents.add(
          SavedDocument.fromJson(
            jsonDecode(await entry.readAsString()) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        unreadable++;
      }
    }
    documents.sort((a, b) => b.updated.compareTo(a.updated));
    return DocumentListing(documents, unreadable);
  }
}
