import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';
import 'package:image/image.dart' as img;

void main() {
  Uint8List sample() {
    final image = img.Image(width: 100, height: 60);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 49,
      y2: 59,
      color: img.ColorRgb8(255, 0, 0),
    );
    return Uint8List.fromList(img.encodePng(image));
  }

  test('rotation precedes crop in the displayed coordinate system', () {
    final result = img.decodePng(
      prepareDocumentImage(
        DocumentImageEdit(
          bytes: sample(),
          quarterTurns: 1,
          crop: const DocumentCrop(bottom: .5),
        ),
      ),
    )!;
    expect(result.width, 60);
    expect(result.height, 50);
    final pixel = result.getPixel(30, 25);
    expect(pixel.r, 255);
    expect(pixel.g, 0);
  });
  test('EXIF orientation is baked before manual editing', () {
    final photo = img.Image(width: 100, height: 60);
    photo.exif.imageIfd.orientation = 6;
    final bytes = Uint8List.fromList(img.encodeJpg(photo));
    final result = img.decodePng(normalizeDocumentImage(bytes))!;
    expect(result.width, 60);
    expect(result.height, 100);
    final again = img.decodePng(
      prepareDocumentImage(
        DocumentImageEdit(bytes: Uint8List.fromList(img.encodePng(result))),
      ),
    )!;
    expect(again.width, 60);
    expect(again.height, 100);
  });
  test('full rotation preserves dimensions and pixels', () {
    final bytes = sample();
    final result = img.decodePng(
      prepareDocumentImage(DocumentImageEdit(bytes: bytes, quarterTurns: 4)),
    )!;
    expect(result.width, 100);
    expect(result.height, 60);
    expect(result.getPixel(80, 30).g, 255);
    expect(img.decodePng(bytes)!.width, 100);
  });
  test('reject invalid crop bounds and non-images', () {
    expect(
      () => prepareDocumentImage(
        DocumentImageEdit(
          bytes: sample(),
          crop: const DocumentCrop(left: .8, right: .2),
        ),
      ),
      throwsArgumentError,
    );
    expect(() => normalizeDocumentImage(Uint8List(0)), throwsFormatException);
  });
  test('crop includes boundary pixels without exceeding image size', () {
    final result = img.decodePng(
      prepareDocumentImage(
        DocumentImageEdit(
          bytes: sample(),
          crop: const DocumentCrop(left: .999, top: .999),
        ),
      ),
    )!;
    expect(result.width, 1);
    expect(result.height, 1);
  });
}
