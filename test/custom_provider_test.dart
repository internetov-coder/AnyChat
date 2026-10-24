import 'package:anychat/core/network/api_format.dart';
import 'package:anychat/core/storage/db.dart' as db;
import 'package:anychat/features/providers/domain/custom_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomProvider.fromRow', () {
    test('maps a full row', () {
      final provider = CustomProvider.fromRow(
        db.ProviderConfig(
          id: 1,
          providerId: 'abc',
          baseUrl: 'https://x.example/v1',
          name: 'My X',
          format: 'openai',
        ),
      );
      expect(provider.id, 'abc');
      expect(provider.name, 'My X');
      expect(provider.baseUrl, 'https://x.example/v1');
      expect(provider.format, ApiFormat.openai);
    });

    test('falls back to the id when the name is empty', () {
      final provider = CustomProvider.fromRow(
        db.ProviderConfig(
          id: 2,
          providerId: 'legacy-vercel',
          baseUrl: 'https://ai-gateway.vercel.sh/v1',
        ),
      );
      expect(provider.name, 'legacy-vercel');
      expect(provider.baseUrl, 'https://ai-gateway.vercel.sh/v1');
      expect(provider.format, ApiFormat.openai);
    });

    test('parses unknown format strings as openai', () {
      final provider = CustomProvider.fromRow(
        db.ProviderConfig(
          id: 3,
          providerId: 'weird',
          baseUrl: 'https://y.example',
          format: 'nonsense',
        ),
      );
      expect(provider.format, ApiFormat.openai);
    });

    test('round-trips every ApiFormat', () {
      for (final format in ApiFormat.values) {
        final provider = CustomProvider.fromRow(
          db.ProviderConfig(
            id: 4,
            providerId: 'p-${format.name}',
            baseUrl: 'https://z.example',
            format: format.name,
          ),
        );
        expect(provider.format, format);
      }
    });
  });

  group('normalizeEndpoint', () {
    test('trims spaces and trailing slashes', () {
      expect(
        normalizeEndpoint(' https://api.example.com/v1/ '),
        'https://api.example.com/v1',
      );
      expect(
        normalizeEndpoint('https://api.example.com'),
        'https://api.example.com',
      );
      expect(normalizeEndpoint('http://10.0.2.2:11434/v1/'), 'http://10.0.2.2:11434/v1');
    });
  });
}
