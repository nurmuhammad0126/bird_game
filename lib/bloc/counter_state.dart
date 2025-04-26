part of 'counter_bloc.dart';

class CounterState {
  int count;
  Color textColor;

  CounterState({required this.count, required this.textColor});

  CounterState copyWith({int? count, Color? textColor}) {
    return CounterState(
      count: count ?? this.count,
      textColor: textColor ?? this.textColor,
    );
  }
}
