import 'package:flutter/material.dart';
import 'package:game_bird/views/screen/home_screen.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(onPressed: (){
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) {
            return HomeScreen()
;          },));
        }, child: Text("O'yinga qaytish")),
      ),
    );
  }
}