enum ModelModality { image, video, audio }

Set<ModelModality> inferMediaModalities(String modelId) {
  final id = modelId.toLowerCase();
  bool has(String needle) => id.contains(needle);
  final out = <ModelModality>{};

  const imageMarkers = <String>[
    'gpt-4o',
    'gpt-4.1',
    'gpt-5',
    'o1-',
    'o3-',
    'o4-',
    'claude',
    'gemini',
    'vision',
    'llava',
    'pixtral',
    'internvl',
    'molmo',
    '/vl',
    '-vl',
    'qwen2-vl',
    'qwen3-vl',
    'multimodal',
  ];
  if (imageMarkers.any(has)) {
    out.add(ModelModality.image);
  }
  if (has('gemini') || has('video')) {
    out.add(ModelModality.video);
  }
  if (has('gemini') ||
      has('audio') ||
      has('whisper') ||
      has('transcribe') ||
      has('-asr')) {
    out.add(ModelModality.audio);
  }
  return out;
}

Set<ModelModality> mediaModalitiesFor(
  String modelId, {
  Set<ModelModality> declared = const <ModelModality>{},
}) {
  final out = <ModelModality>{...declared};
  out.addAll(inferMediaModalities(modelId));
  return out;
}

bool isReasoningModel(String modelId) {
  final id = modelId.toLowerCase();
  const markers = <String>[
    'o1-',
    'o3-',
    'o4-',
    '/o1',
    '/o3',
    '/o4',
    'gpt-5',
    'reasoner',
    'thinking',
    '-r1',
    'qwq',
  ];
  return markers.any(id.contains);
}

class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.name,
    this.contextWindow,
    this.approximateContext = false,
    this.inputPricePerM,
    this.outputPricePerM,
    this.modalities = const <ModelModality>{},
    this.reasoningEfforts = const <String>[],
  });

  final String id;

  final String name;

  final int? contextWindow;

  final bool approximateContext;

  final double? inputPricePerM;

  final double? outputPricePerM;

  final Set<ModelModality> modalities;

  final List<String> reasoningEfforts;

  bool get supportsAttachments => modalities.isNotEmpty;

  @override
  bool operator ==(Object other) => other is ModelInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
