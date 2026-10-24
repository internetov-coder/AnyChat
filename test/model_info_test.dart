import 'package:anychat/features/providers/domain/model_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('media modality inference', () {
    test('text-only models get no media modalities', () {
      expect(inferMediaModalities('deepseek-chat'), isEmpty);
      expect(
        inferMediaModalities('meta-llama/llama-3.3-70b-instruct'),
        isEmpty,
      );
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
  });

  group('reasoning model heuristics', () {
    test('detects reasoning models by id', () {
      expect(isReasoningModel('o3-mini'), isTrue);
      expect(isReasoningModel('openai/o1-preview'), isTrue);
      expect(isReasoningModel('deepseek-r1'), isTrue);
      expect(isReasoningModel('some-thinking-model'), isTrue);
    });

    test('keeps plain models out', () {
      expect(isReasoningModel('gpt-4o-mini'), isFalse);
      expect(isReasoningModel('llama-3.3-70b-instruct'), isFalse);
      expect(isReasoningModel('gemini-2.5-flash'), isFalse);
    });
  });
}
