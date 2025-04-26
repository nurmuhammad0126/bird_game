import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_bird/bloc/counter_bloc.dart';
import 'package:game_bird/model/pipe_model.dart';


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
  final List<PipeModel> _pipes = [];

  @override
  void dispose() {
    _moveTimer?.cancel();
    _pipeTimer?.cancel();
    _pipeMoveTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        context.read<CounterBloc>().add(IncrementEvent());
      });

      _pipeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        setState(() {
          _pipes.add(PipeModel(right: 0, gapTop: Random().nextDouble() * 300 + 100));
        });
      });

      _pipeMoveTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        setState(() {
          for (var pipe in _pipes) {
            pipe.right += 5;
          }
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
      ),
      body: GestureDetector(
        onTap: () {
          if (isPlaying) {
            context.read<CounterBloc>().add(DecrementEvent());
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
                          top: pipe.gapTop + 120,
                          right: pipe.right,
                          child: Container(
                            width: 60,
                            height:
                                MediaQuery.of(context).size.height -
                                (pipe.gapTop + 120),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment(
                      -0.7,
                      (state.count / 100).clamp(-1.0, 1.0),
                    ),
                    curve: Curves.easeInOut,
                    child: const CircleAvatar(
                      radius: 10,
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
