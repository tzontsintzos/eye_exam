import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const EyeExamScreen(),
    );
  }
}

class EyeExamScreen extends StatefulWidget {
  const EyeExamScreen({super.key});

  @override
  State<EyeExamScreen> createState() => _EyeExamScreenState();
}

class _EyeExamScreenState extends State<EyeExamScreen>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.eye_exam/volume');

  late AnimationController _animationController;

  double _leftOpacity = 1.0;
  double _rightOpacity = 1.0;

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
      duration: const Duration(seconds: 4),
    )..repeat();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<dynamic> _handleVolumeKey(MethodCall call) async {
    if (_showResults) return;
    switch (call.method) {
      case 'volumeUp':
        setState(() {
          _leftOpacity = (_leftOpacity - 0.1).clamp(0.0, 1.0);
          _leftReductions++;
        });
        break;
      case 'volumeDown':
        setState(() {
          _rightOpacity = (_rightOpacity - 0.1).clamp(0.0, 1.0);
          _rightReductions++;
        });
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
      backgroundColor: const Color(0xFF808080),
      body: GestureDetector(
        onTap: _toggleResults,
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final size = MediaQuery.of(context).size.height * 0.8;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left disk (counter-clockwise)
                      Opacity(
                        opacity: _leftOpacity,
                        child: Transform.rotate(
                          angle: -2 * math.pi * _animationController.value,
                          child: Image.asset(
                            'assets/animation_no_bg.png',
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
                            'assets/animation_no_bg.png',
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
        _leftOpacity = 1.0;
        _rightOpacity = 1.0;
        _leftReductions = 0;
        _rightReductions = 0;
      } else {
        // Show results
        _showResults = true;
      }
    });
  }
}