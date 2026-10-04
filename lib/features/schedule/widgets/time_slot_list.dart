import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_bloc.dart';
import '../../tasks/presentation/bloc/task_bloc.dart';
import '../../tasks/presentation/bloc/task_state.dart';
import '../../tasks/domain/entities/task_entity.dart';

class TimeSlotList extends StatefulWidget {
  const TimeSlotList({super.key});

  final double hourHeight = 60.0;
  final double timeColumnWidth = 70.0;

  @override
  State<TimeSlotList> createState() => _TimeSlotListState();
}

class _TimeSlotListState extends State<TimeSlotList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll when the page first loads if today is the active date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ScheduleBloc>().state;
      if (_isToday(state.selectedDate)) {
        _scrollToCurrentTime();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    // Scroll to the current hour, minus one hour of padding so it isn't glued to the top of the screen
    final double targetOffset = (now.hour * widget.hourHeight) - widget.hourHeight;

    // Clamp ensures we don't scroll past the top (0.0) or bottom boundaries
    final double safeOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuint,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. We use BlocConsumer for the ScheduleBloc so we can actively LISTEN for date changes
    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listenWhen: (previous, current) => previous.selectedDate != current.selectedDate,
      listener: (context, state) {
        // If the user taps on "Today's" date, animate the scroll to the current time
        if (_isToday(state.selectedDate)) {
          // Brief delay allows the new date's tasks to render before scrolling
          Future.delayed(const Duration(milliseconds: 50), () {
            _scrollToCurrentTime();
          });
        }
      },
      builder: (context, scheduleState) {
        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            List<TaskEntity> daysTasks = [];
            if (taskState is TaskLoaded) {
              daysTasks = taskState.tasks.where((task) {
                if (task.startTime == null) return false;
                return task.startTime!.year == scheduleState.selectedDate.year &&
                    task.startTime!.month == scheduleState.selectedDate.month &&
                    task.startTime!.day == scheduleState.selectedDate.day;
              }).toList();

              daysTasks.sort((a, b) => a.startTime!.compareTo(b.startTime!));
            }

            return SingleChildScrollView(
              controller: _scrollController, // 2. Attach the scroll controller here
              padding: const EdgeInsets.only(bottom: 120),
              child: SizedBox(
                height: 25 * widget.hourHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int hour = 0; hour < 24; hour++)
                      Positioned(
                        top: hour * widget.hourHeight,
                        left: 0,
                        right: 0,
                        height: widget.hourHeight,
                        child: _buildTimeSlotBackground(context, scheduleState.selectedDate, hour),
                      ),

                    for (final task in daysTasks)
                      _buildTaskBlock(context, task, daysTasks),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSlotBackground(BuildContext context, DateTime selectedDate, int hour) {
    final isCurrentHour = _isCurrentHour(selectedDate, hour);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: widget.timeColumnWidth,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              _formatHour(hour),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isCurrentHour ? Theme.of(context).primaryColor : Colors.grey.shade600,
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(width: 2, color: Colors.grey.shade300),
            if (isCurrentHour)
              Positioned(
                top: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildTaskBlock(BuildContext context, TaskEntity task, List<TaskEntity> allTasks) {
    final startHour = task.startTime!.hour;
    final startMinute = task.startTime!.minute;

    int durationMinutes = 60;
    if (task.endTime != null) {
      durationMinutes = task.endTime!.difference(task.startTime!).inMinutes;
      if (durationMinutes < 15) durationMinutes = 15;
    }

    final double topOffset = (startHour * widget.hourHeight) + startMinute.toDouble();
    final double height = durationMinutes.toDouble();

    List<TaskEntity> overlaps = allTasks.where((other) {
      final otherStart = other.startTime!;
      final otherEnd = other.endTime ?? otherStart.add(const Duration(minutes: 60));

      final thisStart = task.startTime!;
      final thisEnd = task.endTime ?? thisStart.add(const Duration(minutes: 60));

      return thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart);
    }).toList();

    int colIndex = overlaps.indexWhere((t) => t.id == task.id);
    int totalCols = overlaps.length;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - widget.timeColumnWidth - 32;
    final double taskWidth = availableWidth / totalCols;

    final double leftOffset = widget.timeColumnWidth + 16 + (colIndex * taskWidth);
    final double rightOffset = 16 + ((totalCols - 1 - colIndex) * taskWidth);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    return Positioned(
      top: topOffset,
      left: leftOffset,
      right: rightOffset,
      height: height,
      child: GestureDetector(
        onTap: () {
          print("Tapped task: ${task.title}");
        },
        child: Container(
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height >= 40)
                Text(
                  _formatTimeRange(task.startTime!, task.endTime),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrentHour(DateTime selectedDate, int hour) {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day &&
        now.hour == hour;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  String _formatTimeRange(DateTime start, DateTime? end) {
    String format(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    }
    if (end == null) return format(start);
    return '${format(start)} - ${format(end)}';
  }
}