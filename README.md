# Flutter Doc Capture Kit

[![Flutter checks](https://github.com/yaseenpv01/flutter_doc_capture_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/yaseenpv01/flutter_doc_capture_kit/actions/workflows/ci.yml)

An Android-first Flutter toolkit for turning document photos into reviewed text and PDFs.

**Status: experimental prerelease (0.1.0-dev.1).** The API may change. Local analysis, tests and debug builds are checked; this is not a production-certified scanner.

## What it does

- Camera/gallery import in the example app.
- Manual rectangular crop, 90-degree rotation and preview.
- On-device Latin-script OCR through a community ML Kit adapter.
- Editable recognized lines with source highlighting.
- **Text PDF:** visible text on white pages, with wrapping and pagination.
- **Scan PDF:** original document image with an invisible searchable text layer.
- Example app: save locally, reopen, reorder lines, preview and share PDFs.

Single-image capture is supported. Text output may span several PDF pages. This does not recreate tables, logos, fonts or the original document layout.

## Try the example

Use Flutter **3.41.5 / Dart 3.11.3** or compatible and an Android device running API 24+. The example is Android-only; iOS, web and desktop OCR are not supported by this release.

```sh
git clone https://github.com/yaseenpv01/flutter_doc_capture_kit.git
cd flutter_doc_capture_kit
flutter pub get
cd example
flutter pub get
flutter run
```

Use `example/test_documents/sample_receipt.png` for your first test. It contains synthetic data. Capture/import an image, crop and rotate, preview, then recognize. Tap a line to correct it. Choose Text document or Original scan, then Save in app, Preview PDF or Share PDF.

## Install

Add the prerelease explicitly to your application's pubspec:

```yaml
dependencies:
  flutter_doc_capture_kit: 0.1.0-dev.1
```

Then run `flutter pub get`. To develop against this repository instead, use a local path dependency pointing to your checkout.

Set your Android application's minimum SDK to 24. Follow the camera/gallery setup requirements of the picker you choose; importing images and saving/sharing files are responsibilities of your application, not the core package.

### Capture preparation and OCR

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';

Future<CapturedDocument> readDocument(Uint8List photo) async {
  final work = await Directory.systemTemp.createTemp('document-capture-');
  try {
    return await recognizeDocument(photo, work);
  } finally {
    await work.delete(recursive: true);
  }
}
```

For the optional crop UI, push `DocumentPreparationScreen(imageBytes: photo)` onto your navigator. It returns prepared `Uint8List` bytes or null on cancellation; pass the returned bytes to `recognizeDocument`. The screen normalizes EXIF orientation, keeps the original for reset, and processes image edits in a background isolate.

### Export visible text

```dart
final document = await readDocument(photoBytes);
final pdfBytes = await exportTextPdf(
  document.lines.map((line) => line.text).toList(),
  title: 'My document',
);
```

This produces a text document with **no embedded photo**. Text is currently limited to ASCII; unsupported characters and empty recognition throw `FormatException` rather than silently dropping content.

### Export an image-backed searchable PDF

```dart
final corrected = document.withLines([
  for (final line in document.lines) line.withText(line.text),
]);
final scanPdf = await exportSearchablePdf(corrected);
```

Replace `line.text` with your reviewed value when correcting a line. Keep line bounds paired with their original prepared image. Corrections affect the text layer, not the photographed image. Your app owns the returned PDF bytes and handles saving/sharing.

## Saving in the example

Save in app writes the source image, corrected lines and generated PDF to app-private documents storage. Preview and sharing also save first. Reopen entries from Saved documents; saving again updates the existing entry. Writes use a temporary file followed by rename.

Saved records survive restart. Unsaved edits do not. Clearing app data or uninstalling removes the local library. The example loads records into memory and is intended for small collections. Its document store is example code, not part of the public package API.

## Limits and privacy

- No automatic edge detection, perspective correction, shadow cleanup, table/field extraction or multi-image capture.
- Latin OCR; ASCII PDF export only. Embedded fonts and broader character support are planned.
- OCR reading order and recognition can be wrong; review text before using it. The example allows line reordering.
- Text-layer positioning uses rectangular line bounds, so skewed text or large corrections can select imprecisely.
- OCR normalization and PDF generation still run on the calling isolate. Preparation processing runs in background isolates.
- Package code performs no document uploads or analytics. The resolved Android adapter uses bundled Latin ML Kit recognition; full offline and device-matrix testing remain pending.
- Google's native ML Kit engine is **not open source**. This project's MIT licence covers this project's code, not its dependencies. See [dependency notes](THIRD_PARTY.md).
- Sharing sends your PDF to the selected app. OS caches and third-party SDK behaviour are outside this library's control.

## Development

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
cd example
flutter test
flutter build apk --debug
```

GitHub Actions is configured to run formatting, analysis, tests and an Android debug build. See the linked workflow for the latest results. See [CONTRIBUTING.md](CONTRIBUTING.md), [device checks](doc/DEVICE_CHECKLIST.md) and [release guide](doc/release/RELEASE_CHECKLIST.md).

## Roadmap

1. Complete physical-device and offline tests for the current workflow.
2. Add embedded fonts and wider PDF character coverage.
3. Improve perspective correction and OCR reading order.
4. Add multi-image capture and background processing.
5. Evaluate iOS support.

## Licence

MIT. See [LICENSE](LICENSE). Contributions must be original or appropriately licensed. Use synthetic test documents; don't include private or employer documents.
