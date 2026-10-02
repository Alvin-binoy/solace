import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ExternalModule {
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
    // This tells Android to automatically wipe the corrupted keys
    // and start fresh instead of crashing the app!
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
}