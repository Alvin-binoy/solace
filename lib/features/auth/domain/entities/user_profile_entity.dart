import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final int id;
  final String displayName;
  final String? avatarPath;
  final bool biometricsEnabled;
  final DateTime createdAt;

  const UserProfileEntity({
    required this.id,
    required this.displayName,
    this.avatarPath,
    required this.biometricsEnabled,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, displayName, avatarPath, biometricsEnabled, createdAt];
}