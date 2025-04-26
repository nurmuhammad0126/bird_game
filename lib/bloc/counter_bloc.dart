import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(count: 0, textColor: Colors.black)) {
    on<DecrementEvent>((event, emit) {
      int newCount = state.count - 8;
      emit(
        state.copyWith(
          count: newCount,
          textColor: newCount.isEven ? Colors.black : Colors.red,
        ),
      );
    });

    on<IncrementEvent>((event, emit) {
      int newCount = state.count + 2;
      emit(
        state.copyWith(
          count: newCount,
          textColor: newCount.isEven ? Colors.black : Colors.red,
        ),
      );
    });
  }
}
