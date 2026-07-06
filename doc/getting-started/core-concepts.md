---
title: Core concepts
description: "The four ideas the rest of ai_abstracted builds on: capability contracts, typed requests, generation results, and credentials"
---

# Core concepts

`ai_abstracted` rests on four ideas. Once you know them, every provider and every
capability reads the same way. This page covers all four, then points you at
progress reporting and error handling.

## 1. Capability contracts

Each capability is one interface with one async method. `TextGenerator` turns a
`TextRequest` into a result. `ImageGenerator` turns an `ImageRequest` into a
result. The other four (`VideoGenerator`, `SpeechGenerator`,
`SoundEffectGenerator`, `MusicGenerator`) follow the same shape.

The type exists so you can inject it. Your code depends on the contract, not on a
specific provider:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<String> summarize(TextGenerator generator, String article) async {
  final result = await generator.generateText(
    TextRequest(prompt: 'Summarize this article:\n$article'),
  );
  return result.text;
}
```

`summarize` does not know which provider it talks to. In production you pass a
real client. In a test you pass a fake:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

void main() async {
  final fake = FakeTextGenerator(text: 'A short summary.');
  final summary = await summarize(fake, 'Long article text...');
  print(summary); // A short summary.
}
```

Every capability ships an in-memory fake (`FakeTextGenerator`,
`FakeImageGenerator`, and so on), so you never hit a paid API in a unit test.

## 2. Typed requests

Every request extends `GenerationRequest`. The base carries three shared fields:
`prompt` (required), `seed`, and `model`. Each subclass adds the fields that make
sense for its medium and reports its `kind`.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const text = TextRequest(
  prompt: 'Write a haiku about rain.',
  maxTokens: 256,
);

const image = ImageRequest(
  prompt: 'a red bicycle leaning on a white wall',
  width: 1024,
  height: 1024,
  seed: '42',
);
```

Requests are `const` constructible and immutable, so you can define them once and
reuse them. `seed` is a `String?` and only takes effect when the provider
supports reproducible output. `model` overrides the client default when set, and
stays null to use the default.

## 3. GenerationResult

Every capability returns the same type: `GenerationResult`. It holds `bytes`, the
`mimeType` of those bytes, the `kind` of medium, and a `GenerationMetadata`
object. For text results, `result.text` decodes the bytes as UTF-8 so you do not
handle bytes by hand.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveImage(ImageGenerator generator) async {
  final result = await generator.generateImage(
    const ImageRequest(prompt: 'a red bicycle'),
  );

  // The package never writes files. You decide where the bytes go.
  await File('bicycle.png').writeAsBytes(result.bytes);

  print(result.mimeType); // for example image/png
  print('${result.metadata.width}x${result.metadata.height}');
}
```

`result.bytes` is a `Uint8List`. Writing it to disk uses `dart:io`, which lives in
your code, not in the package. `ai_abstracted` itself stays free of `dart:io` so
it runs anywhere Dart runs.

The `metadata` field describes what came back: the `model` that produced it,
optional `width` and `height`, `hasAudio` for video, `durationMs` (also exposed
as `metadata.duration`), and any provider-specific `extra` fields.

## 4. Credentials

`ProviderCredentials` carries the API key and any connection settings a provider
needs. You can build one directly:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const credentials = ProviderCredentials(apiKey: 'your-api-key');
```

More often you read it from the environment. `credentialsFromEnv` takes a
`ProviderId` and an environment map, and returns the credentials for that
provider, or null when the key is absent:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

void main() {
  final credentials = credentialsFromEnv(
    ProviderId.gemini,
    Platform.environment,
  );
  if (credentials == null) {
    stderr.writeln('Set GEMINI_API_KEY in your environment.');
    return;
  }
  // Hand credentials to a provider client or the registry.
}
```

Each provider reads a known variable (Gemini reads `GEMINI_API_KEY`, OpenAI reads
`OPENAI_API_KEY`, and so on). Ollama is keyless, so it returns an empty key rather
than null. To load every provider you have keys for at once, use
`allCredentialsFromEnv`.

## Progress

Every capability method takes an optional `onProgress` callback. It receives a
`GenerationProgress` with a `stage` from `GenerationStage`. Immediate providers
emit `running` then `done`. Providers that poll a long job (Flux, Veo, Suno) also
emit `queued` and `downloading`. Use it to drive a status line. See
[progress reporting](../guides/progress.md).

## Errors

When a call fails, it throws an `AiException` subclass that tells you what went
wrong: `AiAuthException` for bad keys, `AiRateLimitException` for 429s,
`AiInvalidRequestException` for a malformed request, and `AiTransientException`
for retryable network and server errors. Catch `AiException` to handle any of
them. See [error handling](../guides/error-handling.md).

## Next

- [Your first request](your-first-request.md)
- [The result types](../guides/result-types.md)
- [Credentials](../guides/credentials.md)
- [The provider registry](../guides/the-registry.md)
