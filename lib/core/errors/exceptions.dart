class DatabaseException implements Exception {
  final String message;
  final Object? originalError;
  const DatabaseException(this.message, [this.originalError]);
}

class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException(this.message);
}