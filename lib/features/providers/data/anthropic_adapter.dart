import '../../../core/errors/api_error.dart';
import '../../../core/network/api_format.dart';
import '../domain/model_info.dart';
import 'provider_adapter.dart';

/// Anthropic Messages API (`/messages`, `x-api-key`, SSE events).
class AnthropicAdapter extends ProviderAdapter {
  /// Streamed error payloads carry a kind instead of an HTTP status.
  static const Map<String, int> _errorStatus = <String, int>{
    'rate_limit_error': 429,
    'authentication_error': 401,
    'permission_error': 403,
    'not_found_error': 404,
    'overloaded_error': 529,
    'api_error': 500,
    'invalid_request_error': 400,
  };

  @override
  ApiFormat get format => ApiFormat.anthropic;

  @override
  ChatRequest buildChatRequest(ChatParams params) {
    final turns = ProviderAdapter.mergeTurns(params.turns);
    final system = ProviderAdapter.systemPromptOf(turns);
    final messages = turns.where((t) => t.role != 'system').toList();
    final body = <String, dynamic>{
      'model': params.model,
      'max_tokens': params.maxTokens ?? 4096,
      'stream': true,
      'messages': <Map<String, dynamic>>[
        for (final turn in messages) _messageFor(turn),
      ],
    };
    if (system != null) {
      body['system'] = system;
    }
    final temperature = params.temperature;
    if (temperature != null) {
      // The Anthropic API accepts 0..1 only - clamp instead of failing.
      body['temperature'] = temperature.clamp(0.0, 1.0);
    }
    final topP = params.topP;
    if (topP != null) {
      body['top_p'] = topP;
    }
    return ChatRequest(
      url: joinUrl(params.baseUrl, '/messages'),
      headers: <String, String>{
        'x-api-key': params.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );
  }

  /// Anthropic accepts images as base64 content parts; text-only turns keep
  /// the plain string form.
  static Map<String, dynamic> _messageFor(ChatTurn turn) {
    if (turn.attachments.isEmpty) {
      return <String, String>{'role': turn.role, 'content': turn.content};
    }
    final content = <Map<String, dynamic>>[];
    if (turn.content.isNotEmpty) {
      content.add(<String, dynamic>{'type': 'text', 'text': turn.content});
    }
    for (final attachment in turn.attachments) {
      if (!attachment.isImage) continue; // images (and PDFs) only
      content.add(<String, dynamic>{
        'type': 'image',
        'source': <String, dynamic>{
          'type': 'base64',
          'media_type': attachment.mimeType,
          'data': attachment.data,
        },
      });
    }
    if (content.isEmpty) {
      content.add(<String, dynamic>{'type': 'text', 'text': turn.content});
    }
    return <String, dynamic>{'role': turn.role, 'content': content};
  }

  @override
  ChatRequest buildModelsRequest({
    required String apiKey,
    required String baseUrl,
  }) {
    return ChatRequest(
      url: joinUrl(baseUrl, '/models'),
      headers: <String, String>{
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: const <String, dynamic>{},
    );
  }

  @override
  List<ModelInfo> parseModels(String jsonBody) {
    final decoded = tryDecodeJson(jsonBody);
    if (decoded is! Map) return const <ModelInfo>[];
    final data = decoded['data'];
    if (data is! List) return const <ModelInfo>[];
    final result = <ModelInfo>[];
    for (final item in data) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String || id.isEmpty) continue;
      var name = id;
      final rawName = item['display_name'];
      if (rawName is String && rawName.trim().isNotEmpty) {
        name = rawName.trim();
      }
      result.add(
        ModelInfo(
          id: id,
          name: name,
          approximateContext: true,
          modalities: mediaModalitiesFor(id),
        ),
      );
    }
    return result;
  }

  @override
  String? parseStreamData(String data) {
    final text = data.trim();
    if (text.isEmpty) return '';
    final decoded = tryDecodeJson(text);
    if (decoded is! Map) return '';
    final type = decoded['type'];
    if (type == 'error') {
      final error = decoded['error'];
      final errorKind = error is Map ? '${error['type'] ?? ''}' : '';
      throw ApiError.fromResponse(
        statusCode: _errorStatus[errorKind] ?? 400,
        body: text,
        format: ApiFormat.anthropic,
      );
    }
    if (type == 'message_stop') return null;
    if (type == 'content_block_delta') {
      final delta = decoded['delta'];
      if (delta is Map && delta['text'] is String) {
        return delta['text'] as String;
      }
    }
    return '';
  }
}
