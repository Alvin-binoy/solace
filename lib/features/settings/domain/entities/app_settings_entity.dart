import 'package:equatable/equatable.dart';
import '../../../../core/enums/task_category.dart';

class AppSettingsEntity extends Equatable {
  final String themeMode; // 'system', 'light', 'dark'
  final String accentColorHex;
  final String dateFormat;
  final TaskCategory defaultCategory;
  final int defaultReminderLeadMinutes;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const AppSettingsEntity({
    required this.themeMode,
    required this.accentColorHex,
    required this.dateFormat,
    required this.defaultCategory,
    required this.defaultReminderLeadMinutes,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  AppSettingsEntity copyWith({
    String? themeMode,
    String? accentColorHex,
    String? dateFormat,
    TaskCategory? defaultCategory,
    int? defaultReminderLeadMinutes,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      dateFormat: dateFormat ?? this.dateFormat,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultReminderLeadMinutes: defaultReminderLeadMinutes ?? this.defaultReminderLeadMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  @override
  List<Object> get props => [
    themeMode,
    accentColorHex,
    dateFormat,
    defaultCategory,
    defaultReminderLeadMinutes,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
  ];
}