import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'firebase_service.dart';
import 'fishtank.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DrawAFishApp());
}

class DrawAFishApp extends StatelessWidget {
  const DrawAFishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DrawingScreen(),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<_StrokePoint?> _points = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4;
  bool _isErasing = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.keyZ,
          ): const _UndoIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _UndoIntent: CallbackAction<_UndoIntent>(
              onInvoke: (intent) {
                _undoLastStroke();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: SafeArea(
              child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Title
              const Text(
                "Fish Draw",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                "PA KANAN UNG ISDA HA OR SHARK",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              // Color Picker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _colorButton(Colors.black),
                  _colorButton(Colors.red),
                  _colorButton(Colors.blue),
                  _colorButton(Colors.green),
                  _colorButton(Colors.orange),
                  _colorButton(Colors.purple),
                  const SizedBox(width: 12),
                  _eraserButton(),
                ],
              ),

              const SizedBox(height: 12),

              // Brush size slider
              SizedBox(
                width: 320,
                child: Row(
                  children: [
                    const Text(
                      "Brush size",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 2,
                        max: 24,
                        onChanged: (value) {
                          setState(() => _strokeWidth = value);
                        },
                      ),
                    ),
                    Text(_strokeWidth.toStringAsFixed(0)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Drawing Canvas
              Container(
                width: 600,
                height: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onPanStart: (details) {
                      _addPoint(details.globalPosition, startStroke: true);
                    },
                    onPanUpdate: (details) {
                      _addPoint(details.globalPosition);
                    },
                    onPanEnd: (_) => _points.add(null),
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: CustomPaint(
                        painter: DrawingPainter(_points),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Undo / Reset Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _undoLastStroke,
                    child: const Text("Undo"),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      setState(() => _points.clear());
                    },
                    child: const Text("Reset"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _openSubmitDialog,
                    child: const Text("Submit"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FishTankScreen(),
                        ),
                      );
                    },
                    child: const Text("Fish Tank"),
                  ),
                ],
              ),
            ],
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isErasing = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
      ),
    );
  }

  Widget _eraserButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _isErasing = !_isErasing);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isErasing ? Colors.black12 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        child: Row(
          children: const [
            Icon(Icons.remove, size: 16),
            SizedBox(width: 4),
            Text("Eraser"),
          ],
        ),
      ),
    );
  }

  void _addPoint(Offset globalPosition, {bool startStroke = false}) {
    final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final point = box.globalToLocal(globalPosition);
    final color = _isErasing ? Colors.white : _selectedColor;
    setState(() {
      if (startStroke && _points.isNotEmpty && _points.last != null) {
        _points.add(null); // separate from previous stroke after undo
      }
      _points.add(_StrokePoint(point, color, _strokeWidth));
    });
  }

  void _undoLastStroke() {
    if (_points.isEmpty) return;
    setState(() {
      if (_points.isNotEmpty && _points.last == null) {
        _points.removeLast();
      }
      while (_points.isNotEmpty && _points.last != null) {
        _points.removeLast();
      }
      if (_points.isNotEmpty && _points.last == null) {
        _points.removeLast();
      }
    });
  }

  Future<void> _openSubmitDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool saving = false;
    final rootContext = context;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Submit your fish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final desc = descriptionController.text.trim();
                          if (name.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please add both a name and description.'),
                              ),
                            );
                            return;
                          }
                          setLocalState(() => saving = true);
                          final pngBytes = await _exportCroppedPng();
                          if (!mounted) return;
                          setLocalState(() => saving = false);
                          if (pngBytes == null) return;
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            _showPngPreview(rootContext, name, desc, pngBytes);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save & View'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Uint8List?> _exportCroppedPng() async {
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canvas not ready to export.')),
      );
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    try {
      const pixelRatio = 3.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final Rect? bounds = _calculateStrokeBounds(scale: pixelRatio);
      final Rect fullRect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final Rect srcRect = bounds == null
          ? fullRect
          : bounds.intersect(fullRect);

      // Create transparent background for export
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
      
      // Draw only the strokes without white background
      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          final p1 = _points[i]!;
          final p2 = _points[i + 1]!;
          
          // Offset points by the crop bounds
          final offsetX = srcRect.left / pixelRatio;
          final offsetY = srcRect.top / pixelRatio;
          
          final paint = Paint()
            ..color = p1.color
            ..strokeWidth = p1.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true;

          canvas.drawLine(
            Offset(p1.point.dx - offsetX, p1.point.dy - offsetY),
            Offset(p2.point.dx - offsetX, p2.point.dy - offsetY),
            paint,
          );
        }
      }
      
      final croppedImage = await recorder
          .endRecording()
          .toImage(srcRect.width.ceil(), srcRect.height.ceil());
      final byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode PNG');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
      return null;
    }
  }

  Rect? _calculateStrokeBounds({required double scale}) {
    double? minX, minY, maxX, maxY;
    for (final p in _points) {
      if (p == null) continue;
      final half = p.strokeWidth / 2;
      minX = minX == null ? p.point.dx - half : math.min(minX, p.point.dx - half);
      minY = minY == null ? p.point.dy - half : math.min(minY, p.point.dy - half);
      maxX = maxX == null ? p.point.dx + half : math.max(maxX, p.point.dx + half);
      maxY = maxY == null ? p.point.dy + half : math.max(maxY, p.point.dy + half);
    }
    if (minX == null || minY == null || maxX == null || maxY == null) {
      return null;
    }
    const padding = 8.0;
    return Rect.fromLTRB(
      math.max(0, (minX - padding) * scale),
      math.max(0, (minY - padding) * scale),
      (maxX + padding) * scale,
      (maxY + padding) * scale,
    );
  }

  void _showPngPreview(
    BuildContext context,
    String name,
    String description,
    Uint8List pngBytes,
  ) async {
    // Upload to Firebase
    final firebaseService = FirebaseService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await firebaseService.uploadFish(
        name: name,
        description: description,
        imageBytes: pngBytes,
      );

      // Also add to local list for immediate display
      submittedFish.add(Fish(
        name: name,
        description: description,
        imageBytes: pngBytes,
      ));

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Fish added to tank!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Name: $name'),
                Text('Description: $description'),
                const SizedBox(height: 12),
                SizedBox(
                  width: 260,
                  height: 180,
                  child: Image.memory(
                    pngBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FishTankScreen(),
                    ),
                  );
                },
                child: const Text('View Tank'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    }
  }
}

class _StrokePoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  _StrokePoint(this.point, this.color, this.strokeWidth);
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class DrawingPainter extends CustomPainter {
  final List<_StrokePoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background only for display (not for export)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final paint = Paint()
          ..color = points[i]!.color
          ..strokeWidth = points[i]!.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

        canvas.drawLine(
          points[i]!.point,
          points[i + 1]!.point,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
