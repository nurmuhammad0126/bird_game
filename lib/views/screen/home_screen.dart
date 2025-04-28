import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_bird/bloc/counter_bloc.dart';
import 'package:game_bird/model/pipe_model.dart';
import 'package:game_bird/views/screen/game_over_screen.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Game constants
  static const double birdPosition = 0.6; // Bird's horizontal position ratio
  static const double pipeWidth = 60.0;
  static const double gapSize = 200.0;
  static const double birdSize = 130.0;
  static const double birdHitboxSize = 40.0; // Smaller hitbox than visual size

  // Timer durations
  static const Duration gravityTickDuration = Duration(milliseconds: 100);
  static const Duration pipeGeneratorDuration = Duration(milliseconds: 2500);
  static const Duration gameLoopDuration = Duration(milliseconds: 16); // ~60fps
  static const Duration birdJumpDelay = Duration(milliseconds: 30);

  // Game state
  Timer? _gravityTimer;
  Timer? _pipeGeneratorTimer;
  Timer? _gameLoopTimer;
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  final List<PipeModel> _pipes = [];
  final Random _random = Random();
  double _birdXPosition = 0.0; // Cached bird X position

  @override
  void initState() {
    super.initState();
    // Calculate bird position once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _birdXPosition = MediaQuery.of(context).size.width * birdPosition;
      }
    });
  }

  @override
  void dispose() {
    _stopAllTimers();
    super.dispose();
  }

  void _stopAllTimers() {
    _gravityTimer?.cancel();
    _pipeGeneratorTimer?.cancel();
    _gameLoopTimer?.cancel();
  }

  void _checkCollisions() {
    if (!mounted) return;

    final birdPositionY = context.read<CounterBloc>().state.count;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final birdY = (birdPositionY + 1) * screenHeight / 2;
    _birdXPosition = screenWidth * birdPosition;

    // Qush hitbox
    Rect birdRect = Rect.fromCenter(
      center: Offset(_birdXPosition, birdY),
      width: birdHitboxSize,
      height: birdHitboxSize,
    );

    // Ekran chegarasi (yuqoriga va pastga tegsa)
    if (birdPositionY >= 1.0 || birdPositionY <= -1.0) {
      _endGame();
      return;
    }

    for (var pipe in _pipes) {
      // Truba hitboxlari
      Rect topPipeRect = Rect.fromLTWH(pipe.right, 0, pipeWidth, pipe.gapTop);
      Rect bottomPipeRect = Rect.fromLTWH(
        pipe.right,
        pipe.gapTop + gapSize,
        pipeWidth,
        screenHeight - (pipe.gapTop + gapSize),
      );

      // Agar qush trubaga urilsa
      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        _endGame();
        return;
      }

      // Trubadan o'tib ketganini tekshirish
      bool hasPassed =
          !pipe.counted && pipe.right + pipeWidth < _birdXPosition - 20;

      if (hasPassed) {
        setState(() {
          pipe.counted = true;
          score++;
        });
      }
    }
  }

  void _endGame() {
    if (isGameOver) return; // Prevent multiple calls

    setState(() {
      isGameOver = true;
      isPlaying = false;
    });
    _stopAllTimers();

    // Show game over dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('O\'yin tugadi!'),
            content: Text(
              'Siz $score ta turbadan o\'tdingiz!\nQayta o\'ynashni xohlaysizmi?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetGame();
                },
                child: const Text('Ha'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameOverScreen(),
                    ),
                  );
                },
                child: const Text('Yo\'q'),
              ),
            ],
          ),
    );
  }

  void _resetGame() {
    setState(() {
      isGameOver = false;
      score = 0;
      _pipes.clear();
    });
    context.read<CounterBloc>().add(ResetEvent());
    _startGame();
  }

  void _startGame() {
    if (isPlaying) return;

    setState(() {
      isPlaying = true;
      isGameOver = false;
    });

    // Recalculate bird position to ensure it's correct
    _birdXPosition = MediaQuery.of(context).size.width * birdPosition;

    // Gravity effect timer - makes bird fall
    _gravityTimer = Timer.periodic(gravityTickDuration, (_) {
      if (!mounted || isGameOver) return;
      context.read<CounterBloc>().add(IncrementEvent());
    });

    // Generate new pipes regularly
    _pipeGeneratorTimer = Timer.periodic(pipeGeneratorDuration, (_) {
      if (!mounted || isGameOver) return;
      setState(() {
        // Create pipe with random gap position within reasonable bounds
        // Ensure the gap isn't too high or too low
        final screenHeight = MediaQuery.of(context).size.height;
        final minGapPosition = screenHeight * 0.1; // 10% from top
        final maxGapPosition =
            screenHeight * 0.6; // 60% from top to leave space for gap

        final gapPosition =
            _random.nextDouble() * (maxGapPosition - minGapPosition) +
            minGapPosition;

        _pipes.add(PipeModel(right: 0, gapTop: gapPosition));
      });
    });

    // Main game loop for moving pipes and checking collisions
    _gameLoopTimer = Timer.periodic(gameLoopDuration, (_) {
      if (!mounted || isGameOver) return;
      setState(() {
        // Move all pipes
        for (var pipe in _pipes) {
          pipe.right += 3.0; // Consistent speed
        }

        // Remove pipes that have left the screen (plus margin)
        final screenWidth = MediaQuery.of(context).size.width;
        _pipes.removeWhere((pipe) => pipe.right > screenWidth + 100);

        // Check for collisions
        _checkCollisions();
      });
    });
  }

  void _pauseGame() {
    setState(() {
      isPlaying = false;
    });
    _stopAllTimers();
  }

  void _togglePlayPause() {
    if (isPlaying) {
      _pauseGame();
    } else {
      _startGame();
    }
  }

  void _onTap() {
    if (!isPlaying) {
      _startGame();
      return;
    }

    // Make bird jump with small delay for better feel
    Timer(birdJumpDelay, () {
      if (!mounted || !isPlaying) return;
      context.read<CounterBloc>().add(DecrementEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        title: Text("Hisob: $score", style: const TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.lightBlue.shade200, // Sky background
          child: BlocBuilder<CounterBloc, CounterState>(
            builder: (context, state) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Ground
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 50, color: Colors.brown.shade600),
                  ),

                  // Pipes
                  ..._buildPipes(),

                  // Bird
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 100),
                    alignment: Alignment(-0.3, state.count),
                    curve: Curves.easeInOut,
                    child: Transform.rotate(
                      angle:
                          state.count * 0.3, // Bird rotates based on velocity
                      child: Lottie.asset(
                        "assets/bird.json",
                        width: birdSize,
                        height: birdSize,
                      ),
                    ),
                  ),

                  // Game state overlay
                  if (!isPlaying && !isGameOver)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "O'yinni boshlash uchun ekranga bosing",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.black,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _startGame,
                            child: const Text("Boshlash"),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Optimized method to build pipes
  List<Widget> _buildPipes() {
    final List<Widget> pipeWidgets = [];
    final screenHeight = MediaQuery.of(context).size.height;

    for (var pipe in _pipes) {
      // Top pipe
      pipeWidgets.add(
        Positioned(
          top: 0,
          right: pipe.right,
          child: Container(
            width: pipeWidth,
            height: pipe.gapTop,
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      );

      // Bottom pipe
      pipeWidgets.add(
        Positioned(
          top: pipe.gapTop + gapSize,
          right: pipe.right,
          child: Container(
            width: pipeWidth,
            height:
                screenHeight -
                (pipe.gapTop + gapSize + 50), // Account for ground height
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    return pipeWidgets;
  }
}
