import 'package:anychat/features/chat/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveChatTitle', () {
    test('normalizes whitespace in short titles', () {
      expect(deriveChatTitle('  Hello   world '), 'Hello world');
    });

    test('truncates long titles at a word boundary', () {
      final title = deriveChatTitle(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do',
      );
      expect(title.length, lessThanOrEqualTo(40));
      expect(title, isNot(endsWith(' ')));
      expect(title, startsWith('Lorem ipsum'));
    });

    test('falls back for empty input', () {
      expect(deriveChatTitle(''), 'New chat');
      expect(deriveChatTitle('   '), 'New chat');
    });
  });

  group('ChatAttachment', () {
    test('json round trip', () {
      const attachment = ChatAttachment(
        mimeType: 'image/png',
        name: 'photo.png',
        data: 'QUJD',
      );
      final restored = ChatAttachment.fromJson(attachment.toJson());
      expect(restored.mimeType, attachment.mimeType);
      expect(restored.name, attachment.name);
      expect(restored.data, attachment.data);
      expect(restored.isImage, isTrue);
      expect(restored.kind, 'image');
    });

    test('encode/parse of the storage payload', () {
      const attachment = ChatAttachment(
        mimeType: 'audio/mpeg',
        name: 'a.mp3',
        data: 'AAAA',
      );
      final encoded = Message.encodeAttachments(const <ChatAttachment>[
        attachment,
      ]);
      expect(encoded, isNotNull);
      final parsed = Message.parseAttachments(encoded);
      expect(parsed, hasLength(1));
      expect(parsed.single.name, 'a.mp3');
      expect(parsed.single.isAudio, isTrue);
    });

    test('malformed payloads yield no attachments', () {
      expect(Message.parseAttachments(null), isEmpty);
      expect(Message.parseAttachments(''), isEmpty);
      expect(Message.parseAttachments('not json'), isEmpty);
      expect(Message.parseAttachments('{"nope":1}'), isEmpty);
      expect(Message.encodeAttachments(const <ChatAttachment>[]), isNull);
    });
  });
}
