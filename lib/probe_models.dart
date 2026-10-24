import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'features/providers/domain/model_info.dart';

part 'probe_models.g.dart';

@riverpod
Future<List<ModelInfo>> probeModels(Ref ref) async => const <ModelInfo>[];
