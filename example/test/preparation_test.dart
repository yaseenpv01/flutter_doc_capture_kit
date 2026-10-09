import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';
import 'package:image/image.dart' as img;
import 'package:document_capture_example/line_review_dialog.dart';

void main() {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 200, height: 300)),
  );
  testWidgets('crop preview can be adjusted and cancelled', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DocumentPreparationScreen(imageBytes: bytes),
                ),
              ),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Start'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.text('Prepare document'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('crop-corner-0')),
      const Offset(30, 30),
    );
    await tester.tap(find.text('Rotate'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Preview crop'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.text('Recognize text'), findsOneWidget);
    await tester.tap(find.text('Adjust crop'));
    await tester.pumpAndSettle();
    expect(find.text('Preview crop'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });
  testWidgets(
    'line review highlights the source and edits the shared controller',
    (tester) async {
      final controller = TextEditingController(text: 'Original');
      final document = CapturedDocument(
        imageBytes: bytes,
        width: 200,
        height: 300,
        lines: [
          const DocumentLine(
            text: 'Original',
            bounds: Rect.fromLTWH(20, 40, 100, 20),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LineReviewDialog(
              document: document,
              index: 0,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('line-highlight')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Corrected');
      expect(controller.text, 'Corrected');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
