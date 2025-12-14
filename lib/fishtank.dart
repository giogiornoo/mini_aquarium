import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'firebase_service.dart';

class AppColors {
  static const Color background = Color(0xFFE0F7FA); // Light light cyan
  static const Color canvas = Colors.white;
  static const Color buttonText = Colors.black;
}

class Fish {
  final String name;
  final String description;
  final Uint8List imageBytes;

  Fish({
    required this.name,
    required this.description,
    required this.imageBytes,
  });
}

// Global fish collection
final List<Fish> submittedFish = [];

class FishTankScreen extends StatefulWidget {
  const FishTankScreen({super.key});

  @override
  State<FishTankScreen> createState() => _FishTankScreenState();
}

class _FishTankScreenState extends State<FishTankScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFish();
  }

  Future<void> _loadFish() async {
    final fishList = await _firebaseService.loadAllFish();
    setState(() {
      submittedFish.clear();
      submittedFish.addAll(fishList);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fishie Tank'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : submittedFish.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'The Tank is Empty',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Go draw some fish to release them here!',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text('Back to Drawing'),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final tankSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: submittedFish.map((fish) {
                      return SwimmingFish(
                        key: ObjectKey(fish),
                        fish: fish,
                        tankSize: tankSize,
                      );
                    }).toList(),
                  );
                },
              ),
      ),
      floatingActionButton: submittedFish.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.blue),
            )
          : null,
    );
  }
}

class SwimmingFish extends StatefulWidget {
  final Fish fish;
  final Size tankSize;

  const SwimmingFish({
    super.key,
    required this.fish,
    required this.tankSize,
  });

  @override
  State<SwimmingFish> createState() => _SwimmingFishState();
}

class _SwimmingFishState extends State<SwimmingFish> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  ui.Image? _loadedImage;

  // Physics State
  double x = 0;
  double y = 0;
  double dx = 2.0;
  double dy = 0.5;
  
  // Dimensions
  late double fishWidth;
  double fishHeight = 150.0; // Default until loaded

  // Animation State
  double _swimTime = 0.0;

  @override
  void initState() {
    super.initState();
    _decodeImage();

    final random = math.Random();

    // --- WIDTH LOGIC (MADE BIGGER) ---
    // Random Width between 300px and 550px
    double randomWidth = 300.0 + random.nextDouble() * 250.0;
    
    // Safety: ensure fish fits within the tank
    double maxWidth = math.min(widget.tankSize.width, widget.tankSize.height) - 20;
    // Clamped between 150 and 600
    fishWidth = math.min(randomWidth, maxWidth).clamp(150.0, 600.0);
    // -------------------

    // Random Start Pos (using default height initially)
    x = random.nextDouble() * (widget.tankSize.width - fishWidth).clamp(0, widget.tankSize.width);
    y = random.nextDouble() * (widget.tankSize.height - fishHeight).clamp(0, widget.tankSize.height);

    // Random Velocity
    double speed = 1.5 + random.nextDouble() * 2.5;
    dx = random.nextBool() ? speed : -speed;
    dy = (random.nextDouble() - 0.5) * 1.5;

    _swimTime = random.nextDouble() * 100; // Random start phase

    _ticker = createTicker(_onTick)..start();
  }

  void _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.fish.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _loadedImage = frame.image;
        
        // --- ASPECT RATIO FIX ---
        // Calculate the correct height based on the image's aspect ratio
        double aspectRatio = frame.image.width / frame.image.height;
        fishHeight = fishWidth / aspectRatio;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwimmingFish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tankSize != oldWidget.tankSize) {
      x = x.clamp(0, widget.tankSize.width - fishWidth);
      y = y.clamp(0, widget.tankSize.height - fishHeight);
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _loadedImage == null) return;

    setState(() {
      x += dx;
      y += dy;
      _swimTime += 0.15; // Animation speed

      // Bounce Logic
      // Check X against Width
      if (x + fishWidth >= widget.tankSize.width) dx = -dx.abs();
      if (x <= 0) dx = dx.abs();
      
      // Check Y against Height (Use the new calculated fishHeight)
      if (y + fishHeight >= widget.tankSize.height) dy = -dy.abs();
      if (y <= 0) dy = dy.abs();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedImage == null) return const SizedBox();

    final isMovingRight = dx > 0;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(widget.fish.name),
              content: Text(widget.fish.description),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Transform(
          alignment: Alignment.center,
          // Flip horizontally if swimming left
          transform: Matrix4.identity()..scale(isMovingRight ? 1.0 : -1.0, 1.0),
          child: SizedBox(
            width: fishWidth,
            height: fishHeight, // Uses the correct calculated height
            child: CustomPaint(
              painter: FlagFishPainter(
                image: _loadedImage!,
                time: _swimTime,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// PAINTER: Anchors Right (Head) and Animates Left (Tail)
// ----------------------------------------------------------------------------
class FlagFishPainter extends CustomPainter {
  final ui.Image image;
  final double time;

  FlagFishPainter({required this.image, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.medium;

    const int slices = 40;
    final double srcSliceWidth = image.width / slices;
    final double baseDestSliceWidth = size.width / slices;

    // Draw from Right (Head) to Left (Tail)
    double currentX = size.width;

    for (int i = slices - 1; i >= 0; i--) {
      // 1. Calculate Normalized Position (0.0 = Left/Tail, 1.0 = Right/Head)
      double normalizedPos = i / slices;
      
      // 2. TAIL LOGIC: Animate only the left side (< 0.25)
      double intensity = 0.0;
      
      if (normalizedPos < 0.25) {
        // Map 0.0-0.25 range to 1.0-0.0 intensity
        intensity = 1.0 - (normalizedPos * 4.0);
        intensity = intensity * intensity; 
      } else {
        // The right 75% (Body & Head) is static
        intensity = 0.0; 
      }

      // 3. DEPTH LOGIC: Modulate the WIDTH of the slice
      double stretchFactor = 1.0 + (math.sin(time + (i * 0.3)) * 0.4 * intensity);
      
      double drawnWidth = baseDestSliceWidth * stretchFactor;

      // 4. Draw the strip
      final src = Rect.fromLTWH(
        i * srcSliceWidth, 0, 
        srcSliceWidth, image.height.toDouble()
      );
      
      // Draw backwards from currentX
      final dst = Rect.fromLTWH(
        currentX - drawnWidth, 0, 
        drawnWidth + 1.0, 
        size.height
      );

      canvas.drawImageRect(image, src, dst, paint);

      currentX -= drawnWidth;
    }
  }

  @override
  bool shouldRepaint(covariant FlagFishPainter oldDelegate) {
    return time != oldDelegate.time;
  }
}