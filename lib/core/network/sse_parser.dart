import 'dart:convert';

/// A single parsed Server-Sent-Event.
class SseEvent {
  const SseEvent({this.event, required this.data, this.id});

  /// The `event:` field value (defaults to `message` when absent).
  final String? event;

  /// All `data:` lines of the event joined with `\n`.
  final String data;

  /// The `id:` field value, if any.
  final String? id;

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// Incremental, chunk-boundary-safe Server-Sent-Events parser.
///
/// Feed arbitrary text chunks with [addText]; the parser buffers partial
/// lines, so a chunk may end in the middle of a word or a JSON document.
class SseParser {
  String _buffer = '';
  final List<String> _dataLines = <String>[];
  String? _eventName;
  String? _id;

  /// Feeds [chunk] and returns every event completed by it.
  List<SseEvent> addText(String chunk) {
    final events = <SseEvent>[];
    _buffer += chunk;
    var index = _buffer.indexOf('\n');
    while (index != -1) {
      var line = _buffer.substring(0, index);
      _buffer = _buffer.substring(index + 1);
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      _handleLine(line, events);
      index = _buffer.indexOf('\n');
    }
    return events;
  }

  /// Flushes a trailing event that was not terminated by an empty line.
  List<SseEvent> close() {
    final events = <SseEvent>[];
    if (_buffer.isNotEmpty) {
      var line = _buffer;
      _buffer = '';
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      _handleLine(line, events);
    }
    _dispatch(events);
    return events;
  }

  void _handleLine(String line, List<SseEvent> events) {
    if (line.isEmpty) {
      _dispatch(events);
      return;
    }
    if (line.startsWith(':')) {
      return;
    }
    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    switch (field) {
      case 'data':
        _dataLines.add(value);
      case 'event':
        _eventName = value;
      case 'id':
        _id = value;
      default:
        break;
    }
  }

  void _dispatch(List<SseEvent> events) {
    if (_dataLines.isEmpty) {
      _eventName = null;
      return;
    }
    events.add(SseEvent(
      event: _eventName ?? 'message',
      data: _dataLines.join('\n'),
      id: _id,
    ));
    _dataLines.clear();
    _eventName = null;
  }

  /// Convenience helper: decodes a UTF-8 byte stream and parses SSE events.
  static Stream<SseEvent> parseBytes(Stream<List<int>> source) async* {
    final parser = SseParser();
    await for (final chunk in source.transform(utf8.decoder)) {
      for (final event in parser.addText(chunk)) {
        yield event;
      }
    }
    for (final event in parser.close()) {
      yield event;
    }
  }
}
