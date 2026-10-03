import 'package:flutter_bloc/flutter_bloc.dart';

// --- EVENTS ---
abstract class ScheduleEvent {}

class SelectedDateChanged extends ScheduleEvent {
  final DateTime newDate;
  SelectedDateChanged(this.newDate);
}

// --- STATES ---
class ScheduleState {
  final DateTime selectedDate;

  ScheduleState({required this.selectedDate});

  ScheduleState copyWith({DateTime? selectedDate}) {
    return ScheduleState(
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

// --- BLOC ---
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc() : super(ScheduleState(selectedDate: DateTime.now())) {
    on<SelectedDateChanged>((event, emit) {
      emit(state.copyWith(selectedDate: event.newDate));
    });
  }
}