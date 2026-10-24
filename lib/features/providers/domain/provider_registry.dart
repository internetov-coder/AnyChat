import '../../../core/network/api_format.dart';
import 'model_info.dart';

/// Static description of an LLM provider. API keys are never stored here.
class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.displayName,
    required this.format,
    required this.baseUrl,
    required this.defaultModel,
    this.modelsEndpoint,
    this.fallbackModels = const <ModelInfo>[],
  });

  /// Stable machine id, used for storage keys. Never translated.
  final String id;

  /// Display name. Technical, never translated.
  final String displayName;

  final ApiFormat format;

  /// Default base URL. Overridable in settings (self-hosting, Ollama, ...).
  final String baseUrl;

  final String defaultModel;

  /// Path appended to [baseUrl] to list models, `null` when the provider has
  /// no `/models` endpoint (a static list is used instead).
  final String? modelsEndpoint;

  /// Used when [modelsEndpoint] is absent or the request fails.
  final List<ModelInfo> fallbackModels;
}

/// All 20 supported providers, in UI order.
const List<ProviderInfo> kProviders = <ProviderInfo>[
  ProviderInfo(
    id: 'openai',
    displayName: 'OpenAI',
    format: ApiFormat.openai,
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'gpt-4o-mini',
        name: 'GPT-4o mini',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'gpt-4o',
        name: 'GPT-4o',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'gpt-4.1',
        name: 'GPT-4.1',
        contextWindow: 1047576,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'gpt-4.1-mini',
        name: 'GPT-4.1 mini',
        contextWindow: 1047576,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'openrouter',
    displayName: 'OpenRouter',
    format: ApiFormat.openai,
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'openai/gpt-4o-mini',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'openai/gpt-4o-mini',
        name: 'openai/gpt-4o-mini',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'anthropic/claude-3.5-sonnet',
        name: 'anthropic/claude-3.5-sonnet',
        contextWindow: 200000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'meta-llama/llama-3.3-70b-instruct',
        name: 'meta-llama/llama-3.3-70b-instruct',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'deepseek',
    displayName: 'DeepSeek',
    format: ApiFormat.openai,
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'deepseek-chat',
        name: 'DeepSeek Chat',
        contextWindow: 65536,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'deepseek-reasoner',
        name: 'DeepSeek Reasoner',
        contextWindow: 65536,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'xiaomi',
    displayName: 'Xiaomi MiMo',
    format: ApiFormat.openai,
    // TODO: confirm the public MiMo endpoint; adjust if Xiaomi publishes a
    // different host or path for its OpenAI-compatible API.
    baseUrl: 'https://api.xiaomimimo.com/v1',
    defaultModel: 'mimo-7b-rl',
    modelsEndpoint: null,
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'mimo-7b-rl',
        name: 'MiMo 7B RL',
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'together',
    displayName: 'Together AI',
    format: ApiFormat.openai,
    baseUrl: 'https://api.together.xyz/v1',
    defaultModel: 'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo',
        name: 'Llama 3.1 8B Turbo',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'Qwen/Qwen2.5-72B-Instruct-Turbo',
        name: 'Qwen 2.5 72B Turbo',
        contextWindow: 32768,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'groq',
    displayName: 'Groq',
    format: ApiFormat.openai,
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'llama-3.3-70b-versatile',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'llama-3.1-8b-instant',
        name: 'Llama 3.1 8B Instant',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'fireworks',
    displayName: 'Fireworks',
    format: ApiFormat.openai,
    baseUrl: 'https://api.fireworks.ai/inference/v1',
    defaultModel: 'accounts/fireworks/models/llama-v3p3-70b-instruct',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'accounts/fireworks/models/llama-v3p3-70b-instruct',
        name: 'Llama 3.3 70B Instruct',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'accounts/fireworks/models/qwen2p5-72b-instruct',
        name: 'Qwen 2.5 72B Instruct',
        contextWindow: 32768,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'novita',
    displayName: 'Novita AI',
    format: ApiFormat.openai,
    baseUrl: 'https://api.novita.ai/v3/openai',
    defaultModel: 'meta-llama/llama-3.3-70b-instruct',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'meta-llama/llama-3.3-70b-instruct',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'deepseek/deepseek-v3',
        name: 'DeepSeek V3',
        contextWindow: 65536,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'deepinfra',
    displayName: 'DeepInfra',
    format: ApiFormat.openai,
    baseUrl: 'https://api.deepinfra.com/v1/openai',
    defaultModel: 'meta-llama/Llama-3.3-70B-Instruct',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'meta-llama/Llama-3.3-70B-Instruct',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'Qwen/Qwen2.5-72B-Instruct',
        name: 'Qwen 2.5 72B',
        contextWindow: 32768,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'mistral',
    displayName: 'Mistral',
    format: ApiFormat.openai,
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModel: 'mistral-large-latest',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'mistral-large-latest',
        name: 'Mistral Large',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'open-mistral-nemo',
        name: 'Mistral Nemo',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'xai',
    displayName: 'xAI',
    format: ApiFormat.openai,
    baseUrl: 'https://api.x.ai/v1',
    defaultModel: 'grok-2-latest',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'grok-2-latest',
        name: 'Grok-2',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'grok-3-mini',
        name: 'Grok-3 mini',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'perplexity',
    displayName: 'Perplexity',
    format: ApiFormat.openai,
    baseUrl: 'https://api.perplexity.ai',
    defaultModel: 'sonar',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'sonar',
        name: 'Sonar',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'sonar-pro',
        name: 'Sonar Pro',
        contextWindow: 200000,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'hyperbolic',
    displayName: 'Hyperbolic',
    format: ApiFormat.openai,
    baseUrl: 'https://api.hyperbolic.xyz/v1',
    defaultModel: 'meta-llama/Llama-3.3-70B-Instruct',
    modelsEndpoint: null,
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'meta-llama/Llama-3.3-70B-Instruct',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'deepseek-ai/DeepSeek-V3',
        name: 'DeepSeek V3',
        contextWindow: 65536,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'cerebras',
    displayName: 'Cerebras',
    format: ApiFormat.openai,
    baseUrl: 'https://api.cerebras.ai/v1',
    defaultModel: 'llama-3.3-70b',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'llama-3.3-70b',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'llama-3.1-8b',
        name: 'Llama 3.1 8B',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'sambanova',
    displayName: 'SambaNova',
    format: ApiFormat.openai,
    baseUrl: 'https://api.sambanova.ai/v1',
    defaultModel: 'Meta-Llama-3.3-70B-Instruct',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'Meta-Llama-3.3-70B-Instruct',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'DeepSeek-V3-0324',
        name: 'DeepSeek V3',
        contextWindow: 65536,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'lambda',
    displayName: 'Lambda',
    format: ApiFormat.openai,
    baseUrl: 'https://api.lambdalabs.com/v1',
    defaultModel: 'qwen-2.5-72b-instruct',
    modelsEndpoint: null,
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'qwen-2.5-72b-instruct',
        name: 'Qwen 2.5 72B',
        contextWindow: 32768,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'llama-3.3-70b-instruct',
        name: 'Llama 3.3 70B',
        contextWindow: 131072,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'cohere',
    displayName: 'Cohere',
    format: ApiFormat.openai,
    baseUrl: 'https://api.cohere.com/compatibility/v1',
    defaultModel: 'command-r-plus',
    modelsEndpoint: null,
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'command-r-plus',
        name: 'Command R+',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'command-r',
        name: 'Command R',
        contextWindow: 128000,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'ollama',
    displayName: 'Ollama (local)',
    format: ApiFormat.openai,
    // 10.0.2.2 is the host loopback address as seen from the Android emulator.
    baseUrl: 'http://10.0.2.2:11434/v1',
    defaultModel: 'llama3.2',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'llama3.2',
        name: 'llama3.2',
        approximateContext: true,
      ),
      ModelInfo(
        id: 'qwen2.5',
        name: 'qwen2.5',
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'vercel',
    displayName: 'Vercel AI Gateway',
    format: ApiFormat.openai,
    // OpenAI-compatible surface of the Vercel AI Gateway: GET /models is
    // public, POST /chat/completions requires a Bearer key.
    baseUrl: 'https://ai-gateway.vercel.sh/v1',
    defaultModel: 'openai/gpt-4o-mini',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'openai/gpt-4o-mini',
        name: 'GPT-4o mini',
        contextWindow: 128000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'openai/gpt-4.1-mini',
        name: 'GPT-4.1 mini',
        contextWindow: 1047576,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'google/gemini-2.5-flash',
        name: 'Gemini 2.5 Flash',
        contextWindow: 1000000,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    format: ApiFormat.anthropic,
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-sonnet-4-20250514',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'claude-sonnet-4-20250514',
        name: 'Claude Sonnet 4',
        contextWindow: 200000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'claude-opus-4-20250514',
        name: 'Claude Opus 4',
        contextWindow: 200000,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'claude-3-7-sonnet-20250219',
        name: 'Claude 3.7 Sonnet',
        contextWindow: 200000,
        approximateContext: true,
      ),
    ],
  ),
  ProviderInfo(
    id: 'gemini',
    displayName: 'Google Gemini',
    format: ApiFormat.gemini,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    defaultModel: 'gemini-2.0-flash',
    modelsEndpoint: '/models',
    fallbackModels: <ModelInfo>[
      ModelInfo(
        id: 'gemini-2.0-flash',
        name: 'Gemini 2.0 Flash',
        contextWindow: 1048576,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'gemini-2.5-flash',
        name: 'Gemini 2.5 Flash',
        contextWindow: 1048576,
        approximateContext: true,
      ),
      ModelInfo(
        id: 'gemini-2.5-pro',
        name: 'Gemini 2.5 Pro',
        contextWindow: 1048576,
        approximateContext: true,
      ),
    ],
  ),
];

/// Looks up a provider by [id]; falls back to OpenAI-compatible defaults.
ProviderInfo findProvider(String? id) {
  for (final provider in kProviders) {
    if (provider.id == id) return provider;
  }
  return kProviders.first;
}
