/// Wire format used by a provider's HTTP API.
enum ApiFormat {
  /// OpenAI-compatible `POST {base}/chat/completions` with `stream: true`.
  openai,

  /// Anthropic `POST {base}/messages` with `x-api-key` header.
  anthropic,

  /// Google Gemini `POST {base}/models/{model}:streamGenerateContent?alt=sse`.
  gemini,
}
