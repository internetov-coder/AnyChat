import 'package:anychat/core/network/api_format.dart';
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

    test('findProvider falls back to openai for unknown ids', () {
      expect(findProvider('does-not-exist').id, 'openai');
      expect(findProvider(null).id, 'openai');
    });
  });
}
