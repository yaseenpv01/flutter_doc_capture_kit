import 'package:flutter/material.dart';
import 'document_store.dart';

class SavedDocumentsScreen extends StatefulWidget {
  const SavedDocumentsScreen({super.key, required this.store});
  final DocumentStore store;
  @override
  State<SavedDocumentsScreen> createState() => _SavedDocumentsState();
}

class _SavedDocumentsState extends State<SavedDocumentsScreen> {
  late final Future<DocumentListing> listing = widget.store.list();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved documents')),
    body: FutureBuilder<DocumentListing>(
      future: listing,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load saved documents. Please try again.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Saved on this device. Open a document to edit, preview or share it. Uninstalling the app removes these files.',
            ),
            if (result.unreadableCount > 0)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${result.unreadableCount} saved file(s) could not be read.',
                ),
              ),
            if (result.documents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No saved documents yet. Capture a document and tap Save in app.',
                ),
              ),
            for (final saved in result.documents)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(saved.title),
                  subtitle: Text(
                    '${saved.style == DocumentPdfStyle.text ? 'Text document' : 'Original scan'} • ${saved.updated.toLocal().toString().substring(0, 16)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, saved),
                ),
              ),
          ],
        );
      },
    ),
  );
}
