import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'probe_simple.g.dart';

@riverpod
Future<bool> probeSimple(Ref ref) async => true;
