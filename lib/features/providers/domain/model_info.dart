/// Media input types a model accepts in addition to text.
enum ModelModality { image, video, audio }

/// Media capabilities we can infer from a model id.
///
/// Used when a provider catalog says nothing about modalities (OpenAI's
/// `/models`, static fallback lists, custom model ids, ...).
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

/// Union of catalog-declared [declared] capabilities and the id-based
/// inference above.
Set<ModelModality> mediaModalitiesFor(
  String modelId, {
  Set<ModelModality> declared = const <ModelModality>{},
}) {
  final out = <ModelModality>{...declared};
  out.addAll(inferMediaModalities(modelId));
  return out;
}

/// Heuristic: does this model id look like a reasoning/thinking model?
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

/// A model as shown on the Models screen.
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

  /// Wire id sent to the provider (`gpt-4o-mini`, `models/gemini-...` without
  /// the prefix, ...). Never translated.
  final String id;

  /// Human-readable name. Falls back to [id] when the provider gives none.
  final String name;

  /// Input context window in tokens when the provider reports it.
  final int? contextWindow;

  /// True when [contextWindow] is a default/approximate value.
  final bool approximateContext;

  /// USD per 1M input tokens, when the provider reports pricing.
  final double? inputPricePerM;

  /// USD per 1M output tokens, when the provider reports pricing.
  final double? outputPricePerM;

  /// Media inputs (image/video/audio) this model accepts.
  final Set<ModelModality> modalities;

  /// Thinking levels the catalog advertises for this model
  /// (e.g. `none, low, medium, high`); empty = not reasoning-based.
  final List<String> reasoningEfforts;

  /// Whether attachments can be sent to this model at all.
  bool get supportsAttachments => modalities.isNotEmpty;

  @override
  bool operator ==(Object other) => other is ModelInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
