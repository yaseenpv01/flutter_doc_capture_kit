import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Normalized crop coordinates in the rotated, upright image.
class DocumentCrop {
  const DocumentCrop({
    this.left = 0,
    this.top = 0,
    this.right = 1,
    this.bottom = 1,
  });
  final double left, top, right, bottom;
}

/// Normalizes EXIF and bounds image size before displaying the editing canvas.
/// Suitable for use with Flutter's compute() helper.
Uint8List normalizeDocumentImage(Uint8List bytes) {
  final decoded = _decode(bytes);
  if (decoded == null) throw const FormatException('Unsupported image format.');
  var image = img.bakeOrientation(decoded);
  if (image.width > 2400 || image.height > 2400) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 2400 : null,
      height: image.height > image.width ? 2400 : null,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

class DocumentImageEdit {
  const DocumentImageEdit({
    required this.bytes,
    this.quarterTurns = 0,
    this.crop = const DocumentCrop(),
  });
  final Uint8List bytes;
  final int quarterTurns;
  final DocumentCrop crop;
}

/// Rotates clockwise, then crops in rotated coordinates. Never edits the source.
/// Suitable for compute(). Crop must be a nonempty rectangle within [0, 1].
Uint8List prepareDocumentImage(DocumentImageEdit edit) {
  final c = edit.crop;
  if (![c.left, c.top, c.right, c.bottom].every((n) => n.isFinite) ||
      c.left < 0 ||
      c.top < 0 ||
      c.right > 1 ||
      c.bottom > 1 ||
      c.right <= c.left ||
      c.bottom <= c.top) {
    throw ArgumentError('Crop must be a nonempty rectangle inside the image.');
  }
  final decoded = _decode(edit.bytes);
  if (decoded == null) throw const FormatException('Unsupported image format.');
  var image = img.bakeOrientation(decoded);
  final turns = edit.quarterTurns % 4;
  if (turns != 0) image = img.copyRotate(image, angle: turns * 90);
  final left = (c.left * image.width).floor();
  final top = (c.top * image.height).floor();
  final right = (c.right * image.width).ceil().clamp(left + 1, image.width);
  final bottom = (c.bottom * image.height).ceil().clamp(top + 1, image.height);
  image = img.copyCrop(
    image,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
  return Uint8List.fromList(img.encodePng(image));
}

img.Image? _decode(Uint8List bytes) {
  if (bytes.length < 16) {
    throw const FormatException('Image is empty or incomplete.');
  }
  try {
    return img.decodeImage(bytes);
  } on RangeError {
    throw const FormatException('Image is incomplete or damaged.');
  }
}
