part of 'counter_bloc.dart';

class CounterState {
  double count;

  CounterState(this.count);

  CounterState copyWith({double? count}) {
    return CounterState(
      count ?? this.count,
    );
  }
}