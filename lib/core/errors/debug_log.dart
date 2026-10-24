import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_error.dart';

part 'debug_log.g.dart';

/// One raw API failure kept for the in-app debug log.
class DebugLogEntry {
  const DebugLogEntry({required this.time, required this.raw});

  final DateTime time;
  final String raw;
}

/// Ring buffer of the last raw API errors (never shown in the UI as-is).
@Riverpod(keepAlive: true)
class DebugLog extends _$DebugLog {
  static const int _maxEntries = 50;

  @override
  List<DebugLogEntry> build() => const <DebugLogEntry>[];

  void add(ApiError error) {
    final raw = error.raw.trim().isEmpty ? error.toString() : error.raw;
    if (kDebugMode) {
      debugPrint('[AnyChat] ${error.type.name}: $raw');
    }
    final next = <DebugLogEntry>[
      ...state,
      DebugLogEntry(time: DateTime.now(), raw: raw),
    ];
    state = next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }

  void clear() => state = const <DebugLogEntry>[];
}
