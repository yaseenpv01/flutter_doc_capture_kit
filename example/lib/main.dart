import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'line_review_dialog.dart';
import 'document_store.dart';
import 'saved_documents_screen.dart';
import 'pdf_preview_screen.dart';

void main() => runApp(const CaptureApp());

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Document Capture',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff126b60)),
    ),
    home: const CaptureScreen(),
  );
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final picker = ImagePicker();
  final title = TextEditingController(text: 'Document');
  final editors = <TextEditingController>[];
  CapturedDocument? document;
  DocumentPdfStyle style = DocumentPdfStyle.text;
  bool busy = false, dirty = false;
  String? error, savedId;

  @override
  void initState() {
    super.initState();
    title.addListener(changed);
    recover();
  }

  void changed() {
    if (mounted && document != null) setState(() => dirty = true);
  }

  Future<DocumentStore> store() async {
    final directory = await getApplicationDocumentsDirectory();
    return DocumentStore(Directory('${directory.path}/saved_documents'));
  }

  void load(CapturedDocument value, {SavedDocument? saved}) {
    for (final editor in editors) {
      editor.dispose();
    }
    editors.clear();
    editors.addAll(
      value.lines.map(
        (line) => TextEditingController(text: line.text)..addListener(changed),
      ),
    );
    title.text =
        saved?.title ??
        'Document ${DateTime.now().toLocal().toString().substring(0, 16)}';
    setState(() {
      document = value;
      savedId = saved?.id;
      style = saved?.style ?? DocumentPdfStyle.text;
      dirty = saved == null;
    });
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> canReplace() async {
    if (!dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved changes'),
            content: const Text(
              'Save this document first if you want to keep your changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard changes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> recover() => perform(() async {
    final lost = await picker.retrieveLostData();
    if (lost.exception != null) throw lost.exception!;
    if (lost.files?.isNotEmpty ?? false) await process(lost.files!.first);
  });

  Future<void> process(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final prepared = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (_) => DocumentPreparationScreen(imageBytes: bytes),
      ),
    );
    if (prepared == null || !mounted) return;
    final temp = await getTemporaryDirectory();
    final work = await temp.createTemp('document-capture-');
    try {
      final result = await recognizeDocument(
        Uint8List.fromList(prepared),
        work,
      );
      if (mounted) load(result);
    } finally {
      await work.delete(recursive: true);
    }
  }

  Future<void> pick(ImageSource source) => perform(() async {
    if (!await canReplace()) return;
    final file = await picker.pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file != null) await process(file);
  });

  CapturedDocument corrected() => document!.withLines([
    for (var i = 0; i < editors.length; i++)
      document!.lines[i].withText(editors[i].text),
  ]);

  Future<SavedDocument> saveCurrent() async {
    final current = corrected();
    final name = title.text.trim().isEmpty ? 'Document' : title.text.trim();
    final bytes = style == DocumentPdfStyle.text
        ? await exportTextPdf(
            current.lines.map((line) => line.text).toList(),
            title: name,
          )
        : await exportSearchablePdf(current);
    final saved = SavedDocument(
      id: savedId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: name,
      updated: DateTime.now(),
      style: style,
      document: current,
      pdf: bytes,
    );
    await (await store()).save(saved);
    if (mounted) {
      setState(() {
        savedId = saved.id;
        dirty = false;
      });
    }
    return saved;
  }

  Future<void> save() => perform(() async {
    await saveCurrent();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved in app. Find it in Saved documents.'),
        ),
      );
    }
  });

  Future<void> preview() => perform(() async {
    final saved = await saveCurrent();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            DocumentPdfPreview(bytes: saved.pdf, title: saved.title),
      ),
    );
  });

  Future<void> share() => perform(() async {
    final saved = await saveCurrent();
    await Printing.sharePdf(bytes: saved.pdf, filename: 'document.pdf');
  });

  Future<void> openSaved() => perform(() async {
    if (!await canReplace()) return;
    final storage = await store();
    if (!mounted) return;
    final saved = await Navigator.push<SavedDocument>(
      context,
      MaterialPageRoute(builder: (_) => SavedDocumentsScreen(store: storage)),
    );
    if (saved != null && mounted) load(saved.document, saved: saved);
  });

  void moveLine(int index, int delta) {
    final lines = document!.lines.toList();
    final line = lines.removeAt(index);
    lines.insert(index + delta, line);
    final editor = editors.removeAt(index);
    editors.insert(index + delta, editor);
    setState(() {
      document = document!.withLines(lines);
      dirty = true;
    });
  }

  @override
  void dispose() {
    title.dispose();
    for (final editor in editors) {
      editor.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Document Capture'),
      actions: [
        IconButton(
          onPressed: busy ? null : openSaved,
          icon: const Icon(Icons.folder_outlined),
          tooltip: 'Saved documents',
        ),
        IconButton(
          onPressed: () => showLicensePage(context: context),
          icon: const Icon(Icons.info_outline),
          tooltip: 'Licences',
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Photo to text document',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Extract text, correct it and create a clean PDF. Save your documents on this device.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Import image'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take photo'),
              ),
              TextButton.icon(
                onPressed: busy ? null : openSaved,
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Saved documents'),
              ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (document != null) ...[
            const SizedBox(height: 20),
            TextField(
              controller: title,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Document name',
                border: OutlineInputBorder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(dirty ? 'Unsaved changes' : 'Saved on this device'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<DocumentPdfStyle>(
              segments: const [
                ButtonSegment(
                  value: DocumentPdfStyle.text,
                  label: Text('Text document'),
                  icon: Icon(Icons.notes),
                ),
                ButtonSegment(
                  value: DocumentPdfStyle.scan,
                  label: Text('Original scan'),
                  icon: Icon(Icons.image_outlined),
                ),
              ],
              selected: {style},
              onSelectionChanged: busy
                  ? null
                  : (value) => setState(() {
                      style = value.single;
                      dirty = true;
                    }),
            ),
            const SizedBox(height: 12),
            Text(
              style == DocumentPdfStyle.text
                  ? 'Creates white pages with visible, selectable text. Photos, logos and table layouts are not reproduced.'
                  : 'Keeps the photo and adds invisible searchable text behind it.',
            ),
            ExpansionTile(
              title: const Text('Source image'),
              children: [
                Image.memory(
                  document!.imageBytes,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Extracted text',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Tap a line to locate and correct it. Use the arrows to change its order in the text document.',
            ),
            if (editors.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No text was recognized. Retake a clear, upright photo, or choose Original scan to save the image.',
                ),
              ),
            for (var i = 0; i < editors.length; i++)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: editors[i],
                        builder: (context, value, child) => Text(
                          value.text.isEmpty ? '(Empty line)' : value.text,
                        ),
                      ),
                      subtitle: Text('Line ${i + 1} • Tap to edit'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: busy
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => LineReviewDialog(
                                document: document!,
                                index: i,
                                controller: editors[i],
                              ),
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Move line up',
                          onPressed: busy || i == 0
                              ? null
                              : () => moveLine(i, -1),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Move line down',
                          onPressed: busy || i == editors.length - 1
                              ? null
                              : () => moveLine(i, 1),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save in app'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : preview,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Preview PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : share,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share PDF'),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Preview and sharing also save your latest changes.'),
            ),
          ] else if (!busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 100,
                color: Color(0xff126b60),
              ),
            ),
        ],
      ),
    ),
  );
}
