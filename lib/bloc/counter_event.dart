part of 'counter_bloc.dart';

abstract class CounterEvent {}

class DecrementEvent extends CounterEvent {}

class IncrementEvent extends CounterEvent {}

class ResetEvent extends CounterEvent {}

