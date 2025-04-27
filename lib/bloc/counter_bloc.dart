import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_event.dart';
part 'counter_state.dart';


class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(0)) {
    on<IncrementEvent>((event, emit) {
      emit(CounterState(state.count + 0.05));
    });
    on<DecrementEvent>((event, emit) {
      emit(CounterState(state.count - 0.2));
    });
    on<ResetEvent>((event, emit) {
      emit(CounterState(0));
    });
  }
}
