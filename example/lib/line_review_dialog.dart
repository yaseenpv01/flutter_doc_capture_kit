import 'package:flutter/material.dart';
import 'package:flutter_doc_capture_kit/flutter_doc_capture_kit.dart';

/// Zoomable source image and correction field in the same view.
class LineReviewDialog extends StatelessWidget {
  const LineReviewDialog({
    super.key,
    required this.document,
    required this.index,
    required this.controller,
  });
  final CapturedDocument document;
  final int index;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Review line ${index + 1}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Highlighted on the document. Pinch to zoom.'),
          ),
          Flexible(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: AspectRatio(
                aspectRatio: document.width / document.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rect = document.lines[index].bounds;
                    final sx = constraints.maxWidth / document.width;
                    final sy = constraints.maxHeight / document.height;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.memory(
                            document.imageBytes,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned(
                          left: rect.left * sx,
                          top: rect.top * sy,
                          width: rect.width * sx,
                          height: rect.height * sy,
                          child: Container(
                            key: const ValueKey('line-highlight'),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: .3),
                              border: Border.all(
                                color: Colors.deepOrange,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Correct this line',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  );
}
