# Flutter Doc Capture Kit 0.1.0-dev.1

First public prerelease candidate for an Android-first document capture toolkit.

## Included

- Manual crop, 90-degree rotation and preview before recognition.
- On-device Latin OCR with editable lines and source highlighting.
- Text-only PDFs with wrapping/pagination and optional image-backed searchable PDFs.
- Android demo with persistent documents, preview, reopening, line ordering and sharing.

## Known limits

Single-image input; ASCII PDF text; no perspective correction, table reconstruction, structured field extraction or iOS support. The API is experimental. Native OCR uses Google's separately licensed ML Kit SDK. Review recognized text before exporting.

## Testing

Local analysis, automated tests and Android debug build are part of the release checks. Physical-device coverage and remote CI status must be recorded before publication. Do not describe this candidate as production-ready.
