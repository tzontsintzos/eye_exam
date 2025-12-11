import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DiskType {
  d1('assets/d1_no_bg.png', 'Disk 1'),
  d2('assets/d2_no_bg.png', 'Disk 2');

  final String assetPath;
  final String displayName;
  const DiskType(this.assetPath, this.displayName);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const EyeExamApp());
  });
}

class EyeExamApp extends StatelessWidget {
  const EyeExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Exam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const DiskSelectionScreen(),
    );
  }
}

class DiskSelectionScreen extends StatelessWidget {
  const DiskSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Disk Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: DiskType.values.map((diskType) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EyeExamScreen(diskType: diskType),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            diskType.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        diskType.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class EyeExamScreen extends StatefulWidget {
  final DiskType diskType;

  const EyeExamScreen({super.key, required this.diskType});

  @override
  State<EyeExamScreen> createState() => _EyeExamScreenState();
}

class _EyeExamScreenState extends State<EyeExamScreen>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.eye_exam/volume');

  late AnimationController _animationController;

  double _leftOpacity = 0.0;
  double _rightOpacity = 0.0;

  int _leftReductions = 0;
  int _rightReductions = 0;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();

    // Set up method channel listener for volume buttons
    _channel.setMethodCallHandler(_handleVolumeKey);

    // Single animation controller for smooth continuous rotation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<dynamic> _handleVolumeKey(MethodCall call) async {
    if (_showResults) return;
    switch (call.method) {
      case 'volumeUp':
        if (_leftReductions < 100) {
          setState(() {
            _leftOpacity = (_leftOpacity + 0.025).clamp(0.0, 1.0);
            _leftReductions++;
          });
        }
        break;
      case 'volumeDown':
        if (_rightReductions < 100) {
          setState(() {
            _rightOpacity = (_rightOpacity + 0.025).clamp(0.0, 1.0);
            _rightReductions++;
          });
        }
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleResults,
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  const size = 300.0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left disk (counter-clockwise)
                      Opacity(
                        opacity: _leftOpacity,
                        child: Transform.rotate(
                          angle: -2 * math.pi * _animationController.value,
                          child: Image.asset(
                            widget.diskType.assetPath,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Right disk (clockwise)
                      Opacity(
                        opacity: _rightOpacity,
                        child: Transform.rotate(
                          angle: 2 * math.pi * _animationController.value,
                          child: Image.asset(
                            widget.diskType.assetPath,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_showResults)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Left: $_leftReductions reductions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Right: $_rightReductions reductions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Tap to continue',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleResults() {
    setState(() {
      if (_showResults) {
        // Reset everything
        _showResults = false;
        _leftOpacity = 0.0;
        _rightOpacity = 0.0;
        _leftReductions = 0;
        _rightReductions = 0;
      } else {
        // Show results
        _showResults = true;
      }
    });
  }
}