import 'package:equatable/equatable.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object> get props => [];
}

class InitializeCalendar extends CalendarEvent {}

class SelectDay extends CalendarEvent {
  final DateTime selectedDay;
  const SelectDay(this.selectedDay);

  @override
  List<Object> get props => [selectedDay];
}