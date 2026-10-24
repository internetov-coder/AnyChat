/// A model as shown on the Models screen.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.name,
    this.contextWindow,
    this.approximateContext = false,
    this.inputPricePerM,
    this.outputPricePerM,
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

  bool get hasPricing => inputPricePerM != null || outputPricePerM != null;

  @override
  bool operator ==(Object other) => other is ModelInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
