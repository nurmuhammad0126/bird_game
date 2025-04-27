import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(count: 0)) {
    on<DecrementEvent>((event, emit) {
      double newCount = state.count - 0.45;
      if (newCount >= -1) {
        emit(state.copyWith(count: newCount));
      } else {
        emit(state.copyWith(count: -1));
      }
    });

    on<IncrementEvent>((event, emit) {
      double newCount = state.count + 0.15;
      if (newCount <= 1) {
        emit(state.copyWith(count: newCount));
      } else {
        emit(state.copyWith(count: 1));
      }
    });

    on<ResetEvent>((event, emit) {
      emit(state.copyWith(count: 0));
    });
  }
}
