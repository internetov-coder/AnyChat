import 'dart:convert';

import 'package:anychat/core/network/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseParser', () {
    test('parses a complete event', () {
      final parser = SseParser();
      final events = parser.addText('data: {"a":1}\n\n');
      expect(events, hasLength(1));
      expect(events.single.data, '{"a":1}');
      expect(events.single.event, 'message');
    });

    test('buffers chunks split in the middle of a word', () {
      final parser = SseParser();
      expect(parser.addText('da'), isEmpty);
      expect(parser.addText('ta: {"a":'), isEmpty);
      final events = parser.addText('1}\n\n');
      expect(events, hasLength(1));
      expect(events.single.data, '{"a":1}');
    });

    test('joins multiple data lines with newline', () {
      final parser = SseParser();
      final events = parser.addText('data: first\ndata: second\n\n');
      expect(events.single.data, 'first\nsecond');
    });

    test('keeps the event name', () {
      final parser = SseParser();
      final events = parser.addText('event: ping\ndata: x\n\n');
      expect(events.single.event, 'ping');
      expect(events.single.data, 'x');
    });

    test('handles CRLF line endings', () {
      final parser = SseParser();
      final events = parser.addText('data: x\r\n\r\n');
      expect(events.single.data, 'x');
    });

    test('ignores comment lines', () {
      final parser = SseParser();
      final events = parser.addText(': keep-alive\ndata: y\n\n');
      expect(events.single.data, 'y');
    });

    test('returns several events from one chunk', () {
      final parser = SseParser();
      final events = parser.addText('data: 1\n\ndata: 2\n\n');
      expect(events, hasLength(2));
      expect(events[0].data, '1');
      expect(events[1].data, '2');
    });

    test('close() flushes a trailing unterminated event', () {
      final parser = SseParser();
      expect(parser.addText('data: end'), isEmpty);
      final events = parser.close();
      expect(events.single.data, 'end');
    });

    test('parseBytes decodes utf-8 and splits chunks arbitrarily', () async {
      final bytes = utf8.encode('data: привет\n\n');
      final stream = Stream<List<int>>.fromIterable(<List<int>>[
        bytes.sublist(0, 9),
        bytes.sublist(9),
      ]);
      final events = await SseParser.parseBytes(stream).toList();
      expect(events.single.data, 'привет');
    });
  });
}
