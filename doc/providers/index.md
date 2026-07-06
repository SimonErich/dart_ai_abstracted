---
title: Providers
description: The provider directory, a capability matrix, and the constructor shape every client shares
---

# Providers

This package talks to nine providers. Each provider is one client class per capability it serves. Gemini has a text client and an image client. Veo has a video client. This page lists who serves what, shows the constructor shape they all share, and links to a page per provider.

## What each provider serves

A cell is marked when that provider offers that capability in this package. Empty means it does not.

| Provider | Text | Image | Video | Speech | Sound effect | Music |
| --- | :---: | :---: | :---: | :---: | :---: | :---: |
| Gemini | yes | yes | | | | |
| Veo | | | yes | | | |
| OpenAI | | yes | | | | |
| Flux | | yes | | | | |
| ElevenLabs | | | | yes | yes | |
| Suno | | | | | | yes |
| Claude | yes | | | | | |
| Mistral | yes | | | | | |
| Ollama | yes | | | | | |

If a provider does not serve a capability, there is no client for it. Ask the registry for one and you get an `AiInvalidRequestException` instead of a client. See [the registry](../guides/the-registry.md).

## The constructor shape

Every provider client takes the same named parameters. Only `credentials` is required. The rest have defaults, so most code passes only the key.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

final client = OpenAiImageClient(
  credentials: ProviderCredentials(apiKey: 'your-key'),
  // Everything below is optional.
  httpClient: sharedClient,          // reuse one http.Client across clients
  retryPolicy: const RetryPolicy(),  // attempts, backoff, and jitter
  endpoint: Uri.parse('https://api.openai.com/v1/images/generations'),
  sleep: Future.delayed,             // the delay seam, swapped in tests
);
```

What each optional parameter does:

- `httpClient`: the `http.Client` to send requests on. Pass one to share connections and to inject a mock in tests. Omit it and the client makes its own.
- `retryPolicy`: how many attempts and how long to back off on transient failures. See [retries and timeouts](../guides/retries-and-timeouts.md).
- `endpoint`: overrides the default host. Use it to point at a proxy or a compatible gateway.
- `sleep`: the function that waits between retries. The default is `Future.delayed`. Override it in tests so retries do not wait real seconds.

### Polling clients add two parameters

Flux, Veo, and Suno run long jobs. You submit the job, then the client polls until it is ready, then downloads the result. Those three clients take two more parameters on top of the shape above.

```dart
final flux = FluxImageClient(
  credentials: ProviderCredentials(apiKey: 'your-bfl-key'),
  pollInterval: const Duration(seconds: 2), // wait between status checks
  pollTimeout: const Duration(minutes: 3),  // give up after this
);
```

When `pollTimeout` passes before the job finishes, the client throws `AiTimeoutException`. Polling clients also report progress through `onProgress`. See [progress](../guides/progress.md).

## Choosing a provider at runtime

Construct a client directly when you know the provider at compile time. When the provider is a value you decide at runtime (from config, an env var, or user input), go through `ProviderRegistry`. You give it a `ProviderId` and credentials, and it hands back the capability client or throws when that provider does not serve it.

```dart
const registry = ProviderRegistry();
final ImageGenerator generator = registry.imageGenerator(
  ProviderId.openai,
  ProviderCredentials(apiKey: 'your-key'),
);
```

The registry has one method per capability: `textGenerator`, `imageGenerator`, `videoGenerator`, `speechGenerator`, `soundEffectGenerator`, and `musicGenerator`. Full detail is on [the registry](../guides/the-registry.md).

## How to read a provider page

Each provider page follows the same layout, so you can scan straight to what you need:

- **Key**: which env var holds the API key and where to get one. Keyless providers (Ollama) say so.
- **Simple example**: the shortest complete request that returns bytes.
- **Advanced options**: the request fields that matter for that provider, such as size for images or voice for speech.
- **Tips**: the specifics that trip people up, like exact model names or how a value is formatted.
- **Errors**: what that provider raises and when, mapped to this package's exception types.

## Provider pages

- [Gemini](gemini.md): text and image (the "Nano Banana" image model).
- [Veo](veo.md): video, with audio on Veo 3. Uses your Gemini key.
- [OpenAI](openai.md): image via `gpt-image-1`.
- [Flux](flux.md): image via Black Forest Labs, polled.
- [ElevenLabs](elevenlabs.md): speech and sound effects.
- [Suno](suno.md): music, through the sunoapi.org gateway.
- [Claude](claude.md): text, with vision when you attach an image.
- [Mistral](mistral.md): text over an OpenAI-style chat endpoint.
- [Ollama](ollama.md): local text, keyless, or a remote instance you point at.

## See also

- [The registry](../guides/the-registry.md)
- [Credentials](../guides/credentials.md)
- [Result types](../guides/result-types.md)
- [Error handling](../guides/error-handling.md)
