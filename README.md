# ai_abstracted

[![pub package](https://img.shields.io/pub/v/ai_abstracted.svg)](https://pub.dev/packages/ai_abstracted)
[![CI](https://github.com/SimonErich/dart_ai_abstracted/actions/workflows/ci.yaml/badge.svg)](https://github.com/SimonErich/dart_ai_abstracted/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

One set of contracts for generative AI, across many providers and every medium.

You pick a capability (text, image, video, speech, sound effect, or music), hand
a typed request plus credentials to a provider client, and get back bytes with
normalized metadata. The same shape works whether the bytes came from Gemini,
Claude, OpenAI, Flux, Veo, ElevenLabs, or Suno. Switching providers is a
constructor swap, not a rewrite.

It is pure Dart with no Flutter and no `dart:io` in the library, so it runs on
servers, the Dart VM, CLIs, and inside Flutter apps. It never writes files: you
decide how to store or cache what comes back.

## Install

```sh
dart pub add ai_abstracted
```

```dart
import 'package:ai_abstracted/ai_abstracted.dart';
```

## A first look

Every capability has an in-memory fake, so you can see the shape without a key or
a network:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final TextGenerator generator = FakeTextGenerator(text: 'Hello there.');

  final result = await generator.generateText(
    const TextRequest(prompt: 'Say hello.'),
  );

  print(result.text); // Hello there.
}
```

Moving to a real provider is the same call with a real client:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set ANTHROPIC_API_KEY first.');
    return;
  }

  final generator = ClaudeTextClient(credentials: credentials);
  final result = await generator.generateText(
    const TextRequest(
      prompt: 'Write a one-line haiku about Dart.',
      system: 'You reply with a single line.',
    ),
  );

  print(result.text);
}
```

Media comes back as bytes. You write them where you want:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final images = OpenAiImageClient(
    credentials: const ProviderCredentials(apiKey: 'sk-...'),
  );
  final result = await images.generateImage(
    const ImageRequest(prompt: 'a red bicycle on a white wall', width: 1024, height: 1024),
  );

  await File('bicycle.png').writeAsBytes(result.bytes);
}
```

## Capabilities and providers

| Medium        | Providers                          |
| ------------- | ---------------------------------- |
| Text          | Gemini, Claude, Mistral, Ollama    |
| Image         | Gemini, OpenAI, Flux               |
| Video         | Veo (Veo 3 includes audio)         |
| Speech        | ElevenLabs                         |
| Sound effect  | ElevenLabs                         |
| Music         | Suno (via sunoapi.org)             |

Each provider has its own page with setup, examples, and tips. See the
[provider directory](https://simonerich.github.io/dart_ai_abstracted/providers/).

## What you get

- Typed requests and one `GenerationResult` (bytes, MIME type, kind, metadata)
  for every medium.
- A typed error hierarchy that maps HTTP failures to `AiAuthException`,
  `AiRateLimitException`, `AiInvalidRequestException`, and friends.
- Built-in retries with backoff, and polling for the providers that run long
  jobs (Veo, Flux, Suno).
- An in-memory fake per capability, so your code stays testable without a
  network or keys.
- A provider registry for choosing a provider at runtime, and an environment
  credential loader.

## Documentation

The full documentation is at
<https://simonerich.github.io/dart_ai_abstracted/>.

Good places to start:

- [Installation](https://simonerich.github.io/dart_ai_abstracted/getting-started/installation/)
- [Your first request](https://simonerich.github.io/dart_ai_abstracted/getting-started/your-first-request/)
- [Core concepts](https://simonerich.github.io/dart_ai_abstracted/getting-started/core-concepts/)
- [Provider directory](https://simonerich.github.io/dart_ai_abstracted/providers/)
- [Testing with fakes](https://simonerich.github.io/dart_ai_abstracted/guides/testing/)
- [Writing your own provider](https://simonerich.github.io/dart_ai_abstracted/guides/custom-provider/)

## Example

A runnable example lives in [`example/main.dart`](example/main.dart). It uses a
fake, so it runs offline:

```sh
dart run example/main.dart
```

## Contributing

Contributions are welcome, especially new providers. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the setup, the quality checks, and how the
commit messages are formatted. If you add a provider for your own project,
a pull request means everyone else can use it too.

## License

MIT. See [LICENSE](LICENSE).
