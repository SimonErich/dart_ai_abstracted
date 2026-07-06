---
title: ai_abstracted
description: "One contract in front of many generative AI providers: a typed request in, bytes plus metadata out, in pure Dart"
---

# ai_abstracted

`ai_abstracted` puts one contract in front of many generative AI providers. You
build a typed request, hand it to a provider client with your credentials, and
get back the raw bytes plus normalized metadata. It is pure Dart with no Flutter
and no `dart:io` in the library, and it never writes files: you decide where the
bytes go.

## The mental model

- Pick a capability: text, image, video, speech, sound effect, or music.
- Hand it a typed request (the prompt and any options) plus your provider
  credentials.
- Get back a `GenerationResult`: the bytes, the MIME type, the media kind, and
  metadata.

Every capability is an interface with a single async method, so the same call
site works against a real provider or an in-memory fake.

## Capabilities and providers

Each row is a medium. The providers listed serve that medium today.

| Medium       | Providers                        |
| ------------ | -------------------------------- |
| Text         | Gemini, Claude, Mistral, Ollama  |
| Image        | Gemini, OpenAI, Flux             |
| Video        | Veo                              |
| Speech       | ElevenLabs                       |
| Sound effect | ElevenLabs                       |
| Music        | Suno                             |

A provider that does not offer a medium throws `AiInvalidRequestException` when
you ask the registry for it, so the gaps are explicit.

## Install

```sh
dart pub add ai_abstracted
```

## First request

This runs offline. `FakeTextGenerator` returns a fixed completion, so you can
wire up the call before you have any API keys.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final generator = FakeTextGenerator();

  final result = await generator.generateText(
    const TextRequest(prompt: 'Write a two-line note about the sea.'),
  );

  print(result.text);            // the completion, decoded from the bytes
  print(result.metadata.model);  // 'fake-text'
}
```

`result.text` decodes the UTF-8 bytes for you. For image, video, or audio
results you read `result.bytes` (a `Uint8List`) and write it yourself, for
example with `File(path).writeAsBytes(result.bytes)` from `dart:io`. The bytes
live in memory until you store them; the package stays free of `dart:io`.

To swap the fake for a live provider, ask the `ProviderRegistry` for the
capability and pass real `ProviderCredentials`. The call site does not change.

## Where to next

- [Installation](getting-started/installation.md)
- [Your first request](getting-started/your-first-request.md)
- [The provider list](providers/index.md)
- [Result types and the rest of the guides](guides/result-types.md)
