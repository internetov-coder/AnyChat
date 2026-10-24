import 'package:dio/dio.dart';

/// Shared HTTP client. Every request carries an absolute URL, so [BaseOptions]
/// only holds transport-level defaults.
class DioClient {
  DioClient._();

  static final Dio instance = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );
}
