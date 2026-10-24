import 'package:anychat/core/network/api_error.dart';
import 'package:anychat/core/network/api_format.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiError.fromResponse (openai)', () {
    test('401 -> authError', () {
      final error = ApiError.fromResponse(
        statusCode: 401,
        body:
            '{"error":{"message":"Incorrect API key provided","type":"invalid_request_error","code":"invalid_api_key"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.authError);
      expect(error.statusCode, 401);
    });

    test('403 -> authError', () {
      final error = ApiError.fromResponse(
        statusCode: 403,
        body: '{"error":{"message":"Forbidden"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.authError);
    });

    test('429 -> rateLimit with default retry_after', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body:
            '{"error":{"message":"Rate limit reached for gpt-4o-mini","type":"requests"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.rateLimit);
      expect(error.retryAfter, 30);
    });

    test('429 honors the retry-after header', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body: '{"error":{"message":"Slow down"}}',
        format: ApiFormat.openai,
        headers: <String, List<String>>{'retry-after': <String>['7']},
      );
      expect(error.type, ApiErrorType.rateLimit);
      expect(error.retryAfter, 7);
    });

    test('429 insufficient_quota -> quotaExceeded', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body:
            '{"error":{"message":"You exceeded your current quota, please check your plan and billing details.","code":"insufficient_quota"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.quotaExceeded);
    });

    test('400 context_length_exceeded -> contextLengthExceeded', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body:
            '{"error":{"message":"This model maximum context length is 8192 tokens","code":"context_length_exceeded"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.contextLengthExceeded);
    });

    test('404 model_not_found -> modelNotFound', () {
      final error = ApiError.fromResponse(
        statusCode: 404,
        body:
            '{"error":{"message":"The model foo does not exist","code":"model_not_found"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.modelNotFound);
    });

    test('400 -> invalidRequest keeps provider details', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body:
            '{"error":{"message":"messages must be non-empty","type":"invalid_request_error"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.invalidRequest);
      expect(error.details, 'messages must be non-empty');
    });

    test('500 -> serverError', () {
      final error = ApiError.fromResponse(
        statusCode: 500,
        body: '{"error":{"message":"The server had an error"}}',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.serverError);
    });

    test('408 -> timeout', () {
      final error = ApiError.fromResponse(
        statusCode: 408,
        body: '',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.timeout);
    });

    test('plain-text 400 body -> invalidRequest with raw details', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body: 'plain text failure',
        format: ApiFormat.openai,
      );
      expect(error.type, ApiErrorType.invalidRequest);
      expect(error.details, 'plain text failure');
    });
  });

  group('ApiError.fromResponse (anthropic)', () {
    test('429 rate_limit_error -> rateLimit', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body:
            '{"type":"error","error":{"type":"rate_limit_error","message":"Rate limit exceeded"}}',
        format: ApiFormat.anthropic,
      );
      expect(error.type, ApiErrorType.rateLimit);
    });

    test('400 prompt is too long -> contextLengthExceeded', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body:
            '{"type":"error","error":{"type":"invalid_request_error","message":"prompt is too long: 5000 tokens > 1000 maximum"}}',
        format: ApiFormat.anthropic,
      );
      expect(error.type, ApiErrorType.contextLengthExceeded);
    });

    test('401 -> authError', () {
      final error = ApiError.fromResponse(
        statusCode: 401,
        body:
            '{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}',
        format: ApiFormat.anthropic,
      );
      expect(error.type, ApiErrorType.authError);
    });

    test('529 overloaded -> serverError', () {
      final error = ApiError.fromResponse(
        statusCode: 529,
        body:
            '{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}',
        format: ApiFormat.anthropic,
      );
      expect(error.type, ApiErrorType.serverError);
    });

    test('404 not_found_error -> modelNotFound', () {
      final error = ApiError.fromResponse(
        statusCode: 404,
        body:
            '{"type":"error","error":{"type":"not_found_error","message":"model: unknown-model"}}',
        format: ApiFormat.anthropic,
      );
      expect(error.type, ApiErrorType.modelNotFound);
    });
  });

  group('ApiError.fromResponse (gemini)', () {
    test('429 billing quota -> quotaExceeded', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body:
            '{"error":{"code":429,"message":"You exceeded your current quota, please check your plan and billing details.","status":"RESOURCE_EXHAUSTED"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.quotaExceeded);
    });

    test('429 rate exhaustion -> rateLimit', () {
      final error = ApiError.fromResponse(
        statusCode: 429,
        body:
            '{"error":{"code":429,"message":"Resource has been exhausted (e.g. check quota).","status":"RESOURCE_EXHAUSTED"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.rateLimit);
    });

    test('400 input token count -> contextLengthExceeded', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body:
            '{"error":{"code":400,"message":"The input token count exceeds the maximum number of tokens allowed","status":"INVALID_ARGUMENT"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.contextLengthExceeded);
    });

    test('404 -> modelNotFound', () {
      final error = ApiError.fromResponse(
        statusCode: 404,
        body:
            '{"error":{"code":404,"message":"models/foo is not found or your API key does not have access","status":"NOT_FOUND"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.modelNotFound);
    });

    test('503 overloaded -> serverError', () {
      final error = ApiError.fromResponse(
        statusCode: 503,
        body:
            '{"error":{"code":503,"message":"The model is overloaded.","status":"UNAVAILABLE"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.serverError);
    });

    test('400 invalid payload -> invalidRequest', () {
      final error = ApiError.fromResponse(
        statusCode: 400,
        body:
            '{"error":{"code":400,"message":"Invalid JSON payload received.","status":"INVALID_ARGUMENT"}}',
        format: ApiFormat.gemini,
      );
      expect(error.type, ApiErrorType.invalidRequest);
      expect(error.details, 'Invalid JSON payload received.');
    });
  });

  group('ApiError.fromDio', () {
    DioException build(DioExceptionType type) => DioException(
          requestOptions: RequestOptions(path: '/chat'),
          type: type,
        );

    test('connection timeout -> timeout', () {
      final error =
          ApiError.fromDio(build(DioExceptionType.connectionTimeout), ApiFormat.openai);
      expect(error.type, ApiErrorType.timeout);
    });

    test('receive timeout -> timeout', () {
      final error =
          ApiError.fromDio(build(DioExceptionType.receiveTimeout), ApiFormat.openai);
      expect(error.type, ApiErrorType.timeout);
    });

    test('connection error -> networkError', () {
      final error =
          ApiError.fromDio(build(DioExceptionType.connectionError), ApiFormat.openai);
      expect(error.type, ApiErrorType.networkError);
    });
  });
}
