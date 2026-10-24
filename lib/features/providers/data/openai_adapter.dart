import '../../../core/errors/api_error.dart';
import '../../../core/network/api_format.dart';
import '../domain/model_info.dart';
import 'provider_adapter.dart';

/// OpenAI-compatible chat completions (`/chat/completions`, SSE `data:`).
class OpenAIAdapter extends ProviderAdapter {
  @override
  ApiFormat get format => ApiFormat.openai;

  @override
  ChatRequest buildChatRequest(ChatParams params) {
    final turns = ProviderAdapter.mergeTurns(params.turns);
    return ChatRequest(
      url: joinUrl(params.baseUrl, '/chat/completions'),
      headers: <String, String>{'Authorization': 'Bearer ${params.apiKey}'},
      body: <String, dynamic>{
        'model': params.model,
        'messages': <Map<String, String>>[
          for (final turn in turns)
            <String, String>{'role': turn.role, 'content': turn.content},
        ],
        'stream': true,
        if (params.temperature != null) 'temperature': params.temperature,
        if (params.maxTokens != null) 'max_tokens': params.maxTokens,
      },
    );
  }

  @override
  ChatRequest buildModelsRequest({
    required String apiKey,
    required String baseUrl,
  }) {
    return ChatRequest(
      url: joinUrl(baseUrl, '/models'),
      headers: <String, String>{'Authorization': 'Bearer $apiKey'},
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
      if (item['archived'] == true) continue;
      var name = id;
      final rawName = item['name'];
      if (rawName is String && rawName.trim().isNotEmpty) {
        name = rawName.trim();
      }
      int? contextWindow;
      final rawContext = item['context_length'] ?? item['context_window'];
      if (rawContext is num) contextWindow = rawContext.toInt();
      double? inputPrice;
      double? outputPrice;
      final pricing = item['pricing'];
      if (pricing is Map) {
        inputPrice = pricePerMillion(pricing['prompt']);
        outputPrice = pricePerMillion(pricing['completion']);
      }
      result.add(ModelInfo(
        id: id,
        name: name,
        contextWindow: contextWindow,
        approximateContext: contextWindow == null,
        inputPricePerM: inputPrice,
        outputPricePerM: outputPrice,
      ));
    }
    return result;
  }

  @override
  String? parseStreamData(String data) {
    final text = data.trim();
    if (text.isEmpty) return '';
    if (text == '[DONE]') return null;
    final decoded = tryDecodeJson(text);
    if (decoded == null) return '';
    if (decoded is! Map) return '';
    if (decoded['error'] != null) {
      final error = decoded['error'];
      final status =
          error is Map && error['code'] is int ? error['code'] as int : 400;
      throw ApiError.fromResponse(
        statusCode: status,
        body: text,
        format: ApiFormat.openai,
      );
    }
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices[0];
      if (first is Map) {
        final delta = first['delta'];
        if (delta is Map && delta['content'] is String) {
          return delta['content'] as String;
        }
        final legacy = first['text'];
        if (legacy is String) return legacy;
      }
    }
    return '';
  }
}
