import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:document_capture_example/main.dart';

void main() {
  testWidgets('shows capture entry points', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.image_picker_android.ImagePickerApi.retrieveLostResults',
            StandardMessageCodec(),
          ),
          (message) async => <Object?>[null],
        );
    await tester.pumpWidget(const CaptureApp());
    await tester.pumpAndSettle();
    expect(find.text('Import image'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Share PDF'), findsNothing);
  });
}
