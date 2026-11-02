import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:math' as math;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigitalChhanniApp());
}

class DigitalChhanniApp extends StatelessWidget {
  const DigitalChhanniApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Digital Chhanni',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF210D18),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD9A441),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const CameraChhanniScreen(),
      );
}

class CameraChhanniScreen extends StatefulWidget {
  const CameraChhanniScreen({super.key});

  @override
  State<CameraChhanniScreen> createState() => _CameraChhanniScreenState();
}

class _CameraChhanniScreenState extends State<CameraChhanniScreen> {
  CameraController? _controller;
  bool _starting = true;
  bool _saving = false;
  String? _error;
  double _size = 0.72;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera({CameraDescription? preferred}) async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No camera was found on this phone.');
      final camera = preferred ?? cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final next = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      final old = _controller;
      _controller = next;
      await old?.dispose();
      if (mounted) setState(() => _starting = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2 || _controller == null) return;
    final current = _controller!.description;
    final other = cameras.firstWhere(
      (c) => c.lensDirection != current.lensDirection,
      orElse: () => cameras.first,
    );
    await _startCamera(preferred: other);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _saving) return;
    setState(() => _saving = true);
    try {
      final shot = await controller.takePicture();
      await Gal.putImage(shot.path, album: 'Digital Chhanni');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to your gallery ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.nightlight_round, color: Color(0xFFE5BD69)),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text('DIGITAL CHHANNI',
                        style: TextStyle(
                          color: Color(0xFFF5DDA6),
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  IconButton(
                    tooltip: 'Switch camera',
                    onPressed: _starting ? null : _switchCamera,
                    icon: const Icon(Icons.cameraswitch_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (controller != null && controller.value.isInitialized)
                        CameraPreview(controller)
                      else
                        const ColoredBox(color: Color(0xFF100A0F)),
                      if (controller != null && controller.value.isInitialized)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: ChhanniPainter(sizeFactor: _size),
                          ),
                        ),
                      if (_starting)
                        const Center(child: CircularProgressIndicator()),
                      if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 42),
                                const SizedBox(height: 12),
                                Text('Camera unavailable\n$_error',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _startCamera,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.zoom_out_map, size: 17, color: Color(0xFFE5BD69)),
                      SizedBox(width: 8),
                      Text('Adjust chhanni size',
                          style: TextStyle(color: Color(0xFFF5DDA6))),
                    ],
                  ),
                  Slider(
                    value: _size,
                    min: 0.48,
                    max: 0.92,
                    activeColor: const Color(0xFFD9A441),
                    onChanged: (v) => setState(() => _size = v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Point your camera towards the moon',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                      FilledButton.icon(
                        onPressed: _saving || controller == null || !controller.value.isInitialized
                            ? null
                            : _capture,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                        label: Text(_saving ? 'Saving' : 'Capture'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD9A441),
                          foregroundColor: const Color(0xFF28130D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChhanniPainter extends CustomPainter {
  ChhanniPainter({required this.sizeFactor});
  final double sizeFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * sizeFactor / 2;
    final gold = Paint()
      ..color = const Color(0xFFE8C477).withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final fineGold = Paint()
      ..color = const Color(0xFFFFE7B0).withOpacity(0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer decorative rim and inner mesh boundary.
    canvas.drawCircle(center, radius, gold..strokeWidth = 5);
    canvas.drawCircle(center, radius - 7, fineGold);

    // Fine crossed mesh lines: the camera image remains visible between them.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 10)));
    final spacing = (radius / 8).clamp(7.0, 15.0);
    for (double x = center.dx - radius; x <= center.dx + radius; x += spacing) {
      canvas.drawLine(Offset(x, center.dy - radius), Offset(x, center.dy + radius), fineGold);
    }
    for (double y = center.dy - radius; y <= center.dy + radius; y += spacing) {
      canvas.drawLine(Offset(center.dx - radius, y), Offset(center.dx + radius, y), fineGold);
    }
    canvas.restore();

    // Small ornamental dots around the rim.
    final dot = Paint()..color = const Color(0xFFFFE3A1);
    for (int i = 0; i < 24; i++) {
      final a = i * 3.141592653589793 * 2 / 24;
      final p = Offset(center.dx + (radius - 3) * math.cos(a), center.dy + (radius - 3) * math.sin(a));
      canvas.drawCircle(p, 2.1, dot);
    }
  }

  @override
  bool shouldRepaint(covariant ChhanniPainter oldDelegate) =>
      oldDelegate.sizeFactor != sizeFactor;
}

