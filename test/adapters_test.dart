import 'dart:convert';
import 'dart:typed_data';

import 'package:anychat/core/errors/api_error.dart';
import 'package:anychat/core/network/api_format.dart';
import 'package:anychat/features/providers/data/anthropic_adapter.dart';
import 'package:anychat/features/providers/data/gemini_adapter.dart';
import 'package:anychat/features/providers/data/openai_adapter.dart';
import 'package:anychat/features/providers/data/provider_adapter.dart';
import 'package:anychat/features/providers/domain/model_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A dio transport stub: captures the outgoing request and replays a canned
/// response without touching the network.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  RequestOptions? lastRequest;
  String? lastRequestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      lastRequestBody = await utf8.decoder.bind(requestStream).join();
    }
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

ChatParams _params({
  String baseUrl = 'https://api.openai.com/v1',
  String model = 'gpt-4o-mini',
  int? maxTokens = 100,
  List<ChatTurn>? turns,
}) {
  return ChatParams(
    apiKey: 'sk-test-key',
    baseUrl: baseUrl,
    model: model,
    maxTokens: maxTokens,
    temperature: 0.5,
    turns: turns ??
        const <ChatTurn>[
          ChatTurn(role: 'system', content: 'Be brief.'),
          ChatTurn(role: 'user', content: 'Hi'),
          ChatTurn(role: 'assistant', content: 'Hello'),
          ChatTurn(role: 'user', content: 'How are you?'),
        ],
  );
}

void main() {
  group('adapterFor', () {
    test('maps every wire format to its adapter', () {
      expect(adapterFor(ApiFormat.openai), isA<OpenAIAdapter>());
      expect(adapterFor(ApiFormat.anthropic), isA<AnthropicAdapter>());
      expect(adapterFor(ApiFormat.gemini), isA<GeminiAdapter>());
    });
  });

  group('OpenAIAdapter request building', () {
    final adapter = OpenAIAdapter();

    test('chat request url, headers and body', () {
      final request = adapter.buildChatRequest(_params());
      expect(request.url, 'https://api.openai.com/v1/chat/completions');
      expect(request.headers['Authorization'], 'Bearer sk-test-key');
      expect(request.body['model'], 'gpt-4o-mini');
      expect(request.body['stream'], isTrue);
      expect(request.body['temperature'], 0.5);
      expect(request.body['max_tokens'], 100);
      final messages = request.body['messages'] as List<dynamic>;
      expect(messages, hasLength(4));
      expect((messages.first as Map<String, dynamic>)['role'], 'system');
    });

    test('trailing slash in base url is trimmed', () {
      final request = adapter.buildChatRequest(
        _params(baseUrl: 'https://api.openai.com/v1/'),
      );
      expect(request.url, 'https://api.openai.com/v1/chat/completions');
    });

    test('models request uses GET with bearer auth', () {
      final request = adapter.buildModelsRequest(
        apiKey: 'sk-test-key',
        baseUrl: 'https://api.openai.com/v1',
      );
      expect(request.url, 'https://api.openai.com/v1/models');
      expect(request.headers['Authorization'], 'Bearer sk-test-key');
    });

    test('parses the models payload including pricing', () {
      final models = adapter.parseModels(
        '{"data":[{"id":"gpt-4o"},'
        '{"id":"gpt-4o-mini","context_length":128000,'
        '"pricing":{"prompt":"0.00000015","completion":"0.0000006"}},'
        '{"id":"archived-model","archived":true}]}',
      );
      expect(models, hasLength(2));
      expect(models.first.id, 'gpt-4o');
      expect(models.first.approximateContext, isTrue);
      expect(models[1].contextWindow, 128000);
      expect(models[1].approximateContext, isFalse);
      expect(models[1].inputPricePerM, closeTo(0.15, 1e-9));
      expect(models[1].outputPricePerM, closeTo(0.6, 1e-9));
    });
  });

  group('AnthropicAdapter request building', () {
    final adapter = AnthropicAdapter();

    test('chat request url, headers and body', () {
      final request = adapter.buildChatRequest(
        _params(baseUrl: 'https://api.anthropic.com/v1', model: 'claude-3-7-sonnet'),
      );
      expect(request.url, 'https://api.anthropic.com/v1/messages');
      expect(request.headers['x-api-key'], 'sk-test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
      expect(request.body['model'], 'claude-3-7-sonnet');
      expect(request.body['stream'], isTrue);
      expect(request.body['max_tokens'], 100);
      expect(request.body['system'], 'Be brief.');
      final messages = request.body['messages'] as List<dynamic>;
      expect(messages, hasLength(3));
      expect((messages.first as Map<String, dynamic>)['role'], 'user');
    });

    test('max_tokens defaults to 4096 when unset', () {
      final request = adapter.buildChatRequest(
        _params(
          baseUrl: 'https://api.anthropic.com/v1',
          model: 'claude-3-7-sonnet',
          maxTokens: null,
        ),
      );
      expect(request.body['max_tokens'], 4096);
    });

    test('models request carries anthropic headers', () {
      final request = adapter.buildModelsRequest(
        apiKey: 'sk-test-key',
        baseUrl: 'https://api.anthropic.com/v1',
      );
      expect(request.url, 'https://api.anthropic.com/v1/models');
      expect(request.headers['x-api-key'], 'sk-test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
    });

    test('parses the models payload', () {
      final models = adapter.parseModels(
        '{"data":[{"id":"claude-3-7-sonnet-latest","display_name":"Claude 3.7 Sonnet"}]}',
      );
      expect(models.single.id, 'claude-3-7-sonnet-latest');
      expect(models.single.name, 'Claude 3.7 Sonnet');
    });
  });

  group('GeminiAdapter request building', () {
    final adapter = GeminiAdapter();
    const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    test('chat request url contains streaming and key', () {
      final request = adapter.buildChatRequest(
        _params(baseUrl: baseUrl, model: 'gemini-2.0-flash'),
      );
      expect(
        request.url,
        startsWith(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent',
        ),
      );
      expect(request.url, contains('alt=sse'));
      expect(request.url, contains('key=sk-test-key'));
    });

    test('maps roles and system prompt into the gemini body', () {
      final request = adapter.buildChatRequest(
        _params(baseUrl: baseUrl, model: 'gemini-2.0-flash'),
      );
      expect(
        (request.body['systemInstruction'] as Map<String, dynamic>)['parts'],
        isNotEmpty,
      );
      final contents = request.body['contents'] as List<dynamic>;
      expect(contents, hasLength(3));
      expect((contents[0] as Map<String, dynamic>)['role'], 'user');
      expect((contents[1] as Map<String, dynamic>)['role'], 'model');
      final config = request.body['generationConfig'] as Map<String, dynamic>;
      expect(config['temperature'], 0.5);
      expect(config['maxOutputTokens'], 100);
    });

    test('models request puts the key in the query', () {
      final request = adapter.buildModelsRequest(
        apiKey: 'AIza-Test_Key',
        baseUrl: baseUrl,
      );
      expect(request.url, '$baseUrl/models?key=AIza-Test_Key');
    });

    test('parses models and drops non-generative ones', () {
      final models = adapter.parseModels(
        '{"models":['
        '{"name":"models/gemini-2.0-flash","displayName":"Gemini 2.0 Flash",'
        '"supportedGenerationMethods":["generateContent","countTokens"],'
        '"inputTokenLimit":1048576},'
        '{"name":"models/text-embedding-004","displayName":"Embedding",'
        '"supportedGenerationMethods":["embedContent"]}]}',
      );
      expect(models, hasLength(1));
      expect(models.single.id, 'gemini-2.0-flash');
      expect(models.single.name, 'Gemini 2.0 Flash');
      expect(models.single.contextWindow, 1048576);
      expect(models.single.approximateContext, isFalse);
    });
  });

  group('parseStreamData', () {
    test('openai deltas and [DONE]', () {
      final adapter = OpenAIAdapter();
      expect(
        adapter.parseStreamData('{"choices":[{"delta":{"content":"Hi"}}]}'),
        'Hi',
      );
      expect(adapter.parseStreamData('[DONE]'), isNull);
      expect(adapter.parseStreamData(''), '');
    });

    test('openai in-stream error becomes ApiError', () {
      final adapter = OpenAIAdapter();
      expect(
        () => adapter.parseStreamData('{"error":{"code":429,"message":"slow"}}'),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.rateLimit),
        ),
      );
    });

    test('anthropic deltas and stop event', () {
      final adapter = AnthropicAdapter();
      expect(
        adapter.parseStreamData(
          '{"type":"content_block_delta","delta":{"type":"text_delta","text":"ok"}}',
        ),
        'ok',
      );
      expect(adapter.parseStreamData('{"type":"message_stop"}'), isNull);
      expect(adapter.parseStreamData('{"type":"ping"}'), '');
    });

    test('anthropic error event maps kinds to statuses', () {
      final adapter = AnthropicAdapter();
      expect(
        () => adapter.parseStreamData(
          '{"type":"error","error":{"type":"rate_limit_error","message":"nope"}}',
        ),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.rateLimit),
        ),
      );
      expect(
        () => adapter.parseStreamData(
          '{"type":"error","error":{"type":"overloaded_error","message":"busy"}}',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.type, 'type', ApiErrorType.serverError),
        ),
      );
    });

    test('gemini concatenates text parts', () {
      final adapter = GeminiAdapter();
      expect(
        adapter.parseStreamData(
          '{"candidates":[{"content":{"parts":[{"text":"He"},{"text":"llo"}]}}]}',
        ),
        'Hello',
      );
      expect(
        () => adapter.parseStreamData('{"promptFeedback":{"blockReason":"SAFETY"}}'),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('streamChat through dio', () {
    test('yields deltas from an SSE response', () async {
      final adapter = OpenAIAdapter();
      final fake = _FakeHttpAdapter(
        statusCode: 200,
        body: 'data: {"choices":[{"delta":{"content":"Hel"}}]}\n\n'
            'data: {"choices":[{"delta":{"content":"lo"}}]}\n\n'
            'data: [DONE]\n\n',
      );
      final dio = _dioWith(fake);

      final deltas =
          await adapter.streamChat(_params(), dio: dio).toList();

      expect(deltas, <String>['Hel', 'lo']);
      expect(
        fake.lastRequest!.uri.toString(),
        'https://api.openai.com/v1/chat/completions',
      );
      expect(fake.lastRequest!.headers['Authorization'], 'Bearer sk-test-key');
      final sent = jsonDecode(fake.lastRequestBody!) as Map<String, dynamic>;
      expect(sent['model'], 'gpt-4o-mini');
      expect(sent['stream'], isTrue);
      expect((sent['messages'] as List).length, 4);
    });

    test('non-2xx response throws a normalized ApiError', () async {
      final adapter = OpenAIAdapter();
      final fake = _FakeHttpAdapter(
        statusCode: 401,
        body: '{"error":{"message":"bad key","code":"invalid_api_key"}}',
      );
      expect(
        () => adapter.streamChat(_params(), dio: _dioWith(fake)).toList(),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.authError),
        ),
      );
    });
  });

  group('fetchModels through dio', () {
    test('parses a successful response', () async {
      final adapter = OpenAIAdapter();
      final fake = _FakeHttpAdapter(
        statusCode: 200,
        body: '{"data":[{"id":"gpt-4o-mini","context_length":128000}]}',
      );
      final models = await adapter.fetchModels(
        apiKey: 'sk-test-key',
        baseUrl: 'https://api.openai.com/v1',
        dio: _dioWith(fake),
      );
      expect(models.single.id, 'gpt-4o-mini');
      expect(
        fake.lastRequest!.uri.toString(),
        'https://api.openai.com/v1/models',
      );
      expect(fake.lastRequest!.headers['Authorization'], 'Bearer sk-test-key');
    });

    test('error status throws mapped ApiError', () async {
      final adapter = OpenAIAdapter();
      final fake = _FakeHttpAdapter(
        statusCode: 401,
        body: '{"error":{"message":"bad key"}}',
      );
      expect(
        () => adapter.fetchModels(
          apiKey: 'sk-test-key',
          baseUrl: 'https://api.openai.com/v1',
          dio: _dioWith(fake),
        ),
        throwsA(
          isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.authError),
        ),
      );
    });
  });

  group('ProviderAdapter helpers', () {
    test('mergeTurns joins adjacent same-role turns and drops empties', () {
      final merged = ProviderAdapter.mergeTurns(const <ChatTurn>[
        ChatTurn(role: 'system', content: 'a'),
        ChatTurn(role: 'system', content: 'b'),
        ChatTurn(role: 'user', content: ''),
        ChatTurn(role: 'user', content: 'hi'),
        ChatTurn(role: 'assistant', content: 'yo'),
      ]);
      expect(merged, hasLength(3));
      expect(merged[0].content, 'a\n\nb');
      expect(merged[1].content, 'hi');
      expect(merged[2].role, 'assistant');
    });

    test('systemPromptOf concatenates system turns', () {
      final system = ProviderAdapter.systemPromptOf(const <ChatTurn>[
        ChatTurn(role: 'system', content: 'one'),
        ChatTurn(role: 'user', content: 'x'),
        ChatTurn(role: 'system', content: 'two'),
      ]);
      expect(system, 'one\n\ntwo');
      expect(
        ProviderAdapter.systemPromptOf(const <ChatTurn>[
          ChatTurn(role: 'user', content: 'x'),
        ]),
        isNull,
      );
    });
  });
}
