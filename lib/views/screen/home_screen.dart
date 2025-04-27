import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_bird/bloc/counter_bloc.dart';
import 'package:game_bird/model/pipe_model.dart';
import 'package:game_bird/views/screen/game_over_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _moveTimer;
  Timer? _pipeTimer;
  Timer? _pipeMoveTimer;
  bool isPlaying = false;
  bool isGameOver = false; // Buni qo'shing
  int score = 0; // Bu qoshildi
  final List<PipeModel> _pipes = [];

  @override
  void dispose() {
    _moveTimer?.cancel();
    _pipeTimer?.cancel();
    _pipeMoveTimer?.cancel();
    super.dispose();
  }

  void _checkGameOver() {
    // CounterBloc dan hozirgi qush pozitsiyasini olish
    final birdPosition = context.read<CounterBloc>().state.count;

    // Ekran chegaralariga tekshirish
    if (birdPosition >= 1.0 || birdPosition <= -1.0) {
      _endGame();
      return;
    }

    // Trubalar bilan to'qnashuvni tekshirish
    for (var pipe in _pipes) {
      // Truba ekranning chap tomonida (qush pozitsiyasida) bo'lganini tekshiramiz
      if (pipe.right >= MediaQuery.of(context).size.width * 0.6 &&
          pipe.right <= MediaQuery.of(context).size.width * 0.8) {
        // Qush pozitsiyasi Y o'qida
        final birdYPosition =
            (birdPosition + 1) * MediaQuery.of(context).size.height / 2;

        // Qushning trubalarga tegishini tekshiramiz
        if (birdYPosition < pipe.gapTop || birdYPosition > pipe.gapTop + 200) {
          // 180 ni 200 ga o'zgartiring
          _endGame();
          return;
        }
      }
    }
  }

  void _endGame() {
    setState(() {
      isGameOver = true;
      isPlaying = false;
    });

    _moveTimer?.cancel();
    _pipeTimer?.cancel();
    _pipeMoveTimer?.cancel();

    // Game over oynasini ko'rsatish
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
                    MaterialPageRoute(builder: (context) => GameOverScreen()),
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
      score = 0; // Hisobni nolga tushirish
      _pipes.clear();
    });

    // Qushni boshlang'ich pozitsiyaga qaytarish
    context.read<CounterBloc>().add(ResetEvent());

    // O'yinni boshlash
    _togglePlayPause();
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        isGameOver = false;
      }
    });

    if (isPlaying) {
      _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        context.read<CounterBloc>().add(IncrementEvent());
      });

      _pipeTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
        // 3 sekund o'rniga 4 sekund
        setState(() {
          _pipes.add(
            PipeModel(right: 0, gapTop: Random().nextDouble() * 300 + 100),
          );
        });
      });

      _pipeMoveTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        setState(() {
          // Trubalarni harakatlantirish (birinchi for tsiklni olib tashlang)
          for (var pipe in _pipes) {
            pipe.right += 5; // Tezlikni 5 dan 3 ga kamaytirib ko'ring

            // Trubadan o'tganlikni tekshirish (to'g'ri tekshirish)
            if (!pipe.counted &&
                pipe.right > MediaQuery.of(context).size.width * 0.8) {
              pipe.counted = true;
              score++; // Har bir trubadan o'tgandagina ball qo'shish
            }
          }

          // Ekrandan chiqib ketgan trubalarni o'chirish
          _pipes.removeWhere(
            (pipe) => pipe.right > MediaQuery.of(context).size.width + 100,
          );

          // Game over tekshiruvi
          _checkGameOver();
        });
      });
    } else {
      _moveTimer?.cancel();
      _pipeTimer?.cancel();
      _pipeMoveTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        title: Text("Hisob: $score", style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          if (isPlaying) {
            Timer(const Duration(milliseconds: 130), () {
              context.read<CounterBloc>().add(DecrementEvent());
            });
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: BlocBuilder<CounterBloc, CounterState>(
            builder: (context, state) {
              return Stack(
                children: [
                  ..._pipes.map((pipe) {
                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: pipe.right,
                          child: Container(
                            width: 60,
                            height: pipe.gapTop,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Positioned(
                          top: pipe.gapTop + 200,
                          right: pipe.right,
                          child: Container(
                            width: 60,
                            height:
                                MediaQuery.of(context).size.height -
                                (pipe.gapTop + 180),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment(-0.7, state.count),
                    curve: Curves.easeInOut,
                    child: const CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.amber,
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
}
