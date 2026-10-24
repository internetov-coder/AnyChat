import 'package:anychat/core/network/api_format.dart';
import 'package:anychat/features/providers/domain/model_info.dart';
import 'package:anychat/features/providers/domain/provider_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('provider registry', () {
    test('contains 21 providers with unique ids', () {
      expect(kProviders, hasLength(21));
      expect(kProviders.map((p) => p.id).toSet(), hasLength(21));
    });

    test('every provider has a usable configuration', () {
      for (final provider in kProviders) {
        expect(provider.baseUrl, startsWith('http'),
            reason: provider.id);
        expect(provider.defaultModel, isNotEmpty, reason: provider.id);
        expect(provider.fallbackModels, isNotEmpty, reason: provider.id);
        expect(provider.format, isA<ApiFormat>(), reason: provider.id);
      }
    });

    test('vercel ai gateway is openai-compatible with a models endpoint', () {
      final vercel = findProvider('vercel');
      expect(vercel.baseUrl, 'https://ai-gateway.vercel.sh/v1');
      expect(vercel.format, ApiFormat.openai);
      expect(vercel.modelsEndpoint, '/models');
      expect(vercel.defaultModel, 'openai/gpt-4o-mini');
      expect(
        vercel.fallbackModels.map((m) => m.id),
        containsAll(<String>[
          'openai/gpt-4o-mini',
          'openai/gpt-4.1-mini',
          'google/gemini-2.5-flash',
        ]),
      );
    });

    test('text-only models get no media modalities', () {
      expect(inferMediaModalities('deepseek-chat'), isEmpty);
      expect(inferMediaModalities('meta-llama/llama-3.3-70b-instruct'), isEmpty);
    });

    test('vision and gemini models get media modalities', () {
      expect(
        inferMediaModalities('gpt-4o-mini'),
        contains(ModelModality.image),
      );
      expect(
        inferMediaModalities('gpt-4o-mini'),
        isNot(contains(ModelModality.video)),
      );
      expect(
        inferMediaModalities('google/gemini-2.5-flash'),
        containsAll(<ModelModality>[
          ModelModality.image,
          ModelModality.video,
          ModelModality.audio,
        ]),
      );
      expect(
        inferMediaModalities('claude-sonnet-4-20250514'),
        contains(ModelModality.image),
      );
    });

    test('declared catalog capabilities are unioned with inference', () {
      final merged = mediaModalitiesFor(
        'some-plain-model',
        declared: <ModelModality>{ModelModality.image},
      );
      expect(merged, contains(ModelModality.image));
      expect(inferMediaModalities('some-plain-model'), isEmpty);
    });

    test('ollama fallback models are text-only', () {
      expect(
        findProvider('ollama').fallbackModels.first.modalities,
        isEmpty,
      );
    });

    test('findProvider falls back to openai for unknown ids', () {
      expect(findProvider('does-not-exist').id, 'openai');
      expect(findProvider(null).id, 'openai');
    });
  });
}
