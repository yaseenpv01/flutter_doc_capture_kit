import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'image_preparation.dart';

/// Returns the prepared image, or null when cancelled. No OCR runs on this page.
class DocumentPreparationScreen extends StatefulWidget {
  const DocumentPreparationScreen({super.key, required this.imageBytes});
  final Uint8List imageBytes;
  @override
  State<DocumentPreparationScreen> createState() => _PreparationState();
}

class _PreparationState extends State<DocumentPreparationScreen> {
  Uint8List? source;
  Uint8List? preview;
  int width = 1, height = 1, turns = 0;
  Rect crop = const Rect.fromLTRB(0, 0, 1, 1);
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final bytes = await compute(normalizeDocumentImage, widget.imageBytes);
      // Decode dimensions only after normalization; editing uses this same image.
      final decoded = img.decodePng(bytes)!;
      if (!mounted) return;
      setState(() {
        source = bytes;
        width = decoded.width;
        height = decoded.height;
        busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          busy = false;
        });
      }
    }
  }

  Future<void> makePreview() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await compute(
        prepareDocumentImage,
        DocumentImageEdit(
          bytes: source!,
          quarterTurns: turns,
          crop: DocumentCrop(
            left: crop.left,
            top: crop.top,
            right: crop.right,
            bottom: crop.bottom,
          ),
        ),
      );
      if (mounted) setState(() => preview = bytes);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void rotate() => setState(() {
    turns = (turns + 1) % 4;
    crop = const Rect.fromLTRB(0, 0, 1, 1);
  });

  void moveCorner(int corner, Offset delta) {
    const minimum = .08;
    var l = crop.left, t = crop.top, r = crop.right, b = crop.bottom;
    if (corner == 0 || corner == 3) {
      l = (l + delta.dx).clamp(0, r - minimum);
    } else {
      r = (r + delta.dx).clamp(l + minimum, 1);
    }
    if (corner == 0 || corner == 1) {
      t = (t + delta.dy).clamp(0, b - minimum);
    } else {
      b = (b + delta.dy).clamp(t + minimum, 1);
    }
    setState(() => crop = Rect.fromLTRB(l, t, r, b));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(preview == null ? 'Prepare document' : 'Preview document'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              preview == null
                  ? 'Drag the four corners to trim the background. Rotate if needed. Rotating resets the crop.'
                  : 'Check the result before recognizing text. You can go back and adjust it.',
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: source == null
                  ? const Center(child: Icon(Icons.image_outlined, size: 64))
                  : preview != null
                  ? InteractiveViewer(
                      child: Image.memory(preview!, fit: BoxFit.contain),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final aspect = turns.isEven
                            ? width / height
                            : height / width;
                        var w = constraints.maxWidth;
                        var h = w / aspect;
                        if (h > constraints.maxHeight) {
                          h = constraints.maxHeight;
                          w = h * aspect;
                        }
                        final points = [
                          crop.topLeft,
                          crop.topRight,
                          crop.bottomRight,
                          crop.bottomLeft,
                        ];
                        return Center(
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: RotatedBox(
                                    quarterTurns: turns,
                                    child: Image.memory(
                                      source!,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CropPainter(crop),
                                    ),
                                  ),
                                ),
                                for (var i = 0; i < 4; i++)
                                  Positioned(
                                    left: points[i].dx * w - 24,
                                    top: points[i].dy * h - 24,
                                    child: Semantics(
                                      label: 'Crop corner ${i + 1}',
                                      child: GestureDetector(
                                        key: ValueKey('crop-corner-$i'),
                                        behavior: HitTestBehavior.opaque,
                                        onPanUpdate: busy
                                            ? null
                                            : (details) => moveCorner(
                                                i,
                                                Offset(
                                                  details.delta.dx / w,
                                                  details.delta.dy / h,
                                                ),
                                              ),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: Center(
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xff126b60,
                                                  ),
                                                  width: 3,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: preview == null
                  ? [
                      OutlinedButton.icon(
                        onPressed: busy || source == null ? null : rotate,
                        icon: const Icon(Icons.rotate_right),
                        label: const Text('Rotate'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                turns = 0;
                                crop = const Rect.fromLTRB(0, 0, 1, 1);
                              }),
                        child: const Text('Reset'),
                      ),
                      FilledButton(
                        onPressed: busy || source == null ? null : makePreview,
                        child: const Text('Preview crop'),
                      ),
                    ]
                  : [
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => setState(() => preview = null),
                        child: const Text('Adjust crop'),
                      ),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.pop(context, preview),
                        child: const Text('Recognize text'),
                      ),
                    ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.crop);
  final Rect crop;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .5));
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.crop != crop;
}
