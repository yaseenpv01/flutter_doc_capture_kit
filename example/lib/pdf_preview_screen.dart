import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class DocumentPdfPreview extends StatelessWidget {
  const DocumentPdfPreview({
    super.key,
    required this.bytes,
    required this.title,
  });
  final Uint8List bytes;
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PdfPreview(
      build: (_) async => bytes,
      canChangePageFormat: false,
      canChangeOrientation: false,
      allowPrinting: false,
      allowSharing: true,
      canDebug: false,
      pdfFileName: 'document.pdf',
    ),
  );
}
