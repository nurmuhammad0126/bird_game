part of 'counter_bloc.dart';

class CounterState {
  double count;

  CounterState({required this.count});

  CounterState copyWith({double? count}) {
    return CounterState(
      count: count ?? this.count,
    );
  }
}