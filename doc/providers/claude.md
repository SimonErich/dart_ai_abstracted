---
title: Anthropic Claude
description: Generate text with Anthropic Claude in ai_abstracted, with a system prompt, multi-turn history, and inline-image vision
---

# Anthropic Claude

Claude is the Anthropic text provider in ai_abstracted. `ClaudeTextClient` implements `TextGenerator` and defaults to the `claude-opus-4-8` model. You hand it a `TextRequest` and get back a `GenerationResult` whose `text` getter holds the reply.

## Get a key

Create an API key in the Anthropic console (console.anthropic.com) and expose it as `ANTHROPIC_API_KEY`. The credential loader reads that variable for you:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

void main() {
  final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set ANTHROPIC_API_KEY first.');
    return;
  }
  // credentials.apiKey is now ready to hand to a client.
}
```

`credentialsFromEnv` returns `null` when the variable is absent, so you can fail early with a clear message instead of getting a 401 later.

## How it connects

The client posts to `https://api.anthropic.com/v1/messages`. It sends two headers: `x-api-key` with your key, and `anthropic-version: 2023-06-01`. You do not build any of that by hand. If you route through a proxy or a compatible gateway, pass `endpoint:` to point at a different `Uri`.

## Simple example

A single completion with a system prompt. The system prompt frames how Claude answers; the `prompt` is the user turn.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
  if (credentials == null) return;

  final claude = ClaudeTextClient(credentials: credentials);

  // Makes a real, billed request to /v1/messages.
  final result = await claude.generateText(
    const TextRequest(
      prompt: 'Give me three names for a corner coffee shop.',
      system: 'You are a concise branding assistant. No preamble, just the list.',
      maxTokens: 200,
    ),
  );

  print(result.text);
}
```

You can also let the registry build the client for you, which keeps provider selection in one place:

```dart
final claude = const ProviderRegistry().textGenerator(ProviderId.claude, credentials);
```

## Multi-turn history and vision

Pass prior turns as `history`, oldest first, built with `TextMessage.user` and `TextMessage.assistant`. The current user turn stays in `prompt`. Attach an image with `TextImage`; Claude accepts it inline as base64, and the client encodes the bytes for you.

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
  if (credentials == null) return;

  final claude = ClaudeTextClient(credentials: credentials);
  final Uint8List photo = await File('harbor.jpg').readAsBytes();

  final result = await claude.generateText(
    TextRequest(
      prompt: 'Describe this photo in one sentence.',
      system: 'You are a careful image reviewer.',
      history: const [
        TextMessage.user('I will send a photo to caption.'),
        TextMessage.assistant('Ready when you are.'),
      ],
      image: TextImage(bytes: photo, mimeType: 'image/jpeg'),
      maxTokens: 300,
      temperature: 0.2, // this client does not send temperature to Claude
    ),
  );

  print(result.text);
}
```

Set `mimeType` to match the file (`image/jpeg`, `image/png`, and so on). A `TextImage` defaults to `image/png`.

The client sends the model, `max_tokens`, your `system` prompt, and the message list. `maxTokens` maps to `max_tokens` and caps the reply. `temperature` is a field on `TextRequest` for providers that read it, but this client does not forward it to Claude, so setting it does not change sampling here.

## Getting JSON back

`TextRequest` has a `jsonSchema` field, but Claude has no JSON-schema switch and this client does not send one. To get JSON, ask for it in the prompt (and in the system prompt), then parse the text yourself. See [Structured output](../guides/structured-output.md) for the pattern.

## Tips

- Set a `system` prompt to steer tone and format. It is the most direct control you have over how Claude replies.
- Size `maxTokens` to the answer you expect. Claude bills output tokens, and a smaller ceiling caps the cost of a long reply.

## Errors

When Claude declines a request, it returns a refusal stop reason. The client turns that into an `AiResponseException` instead of handing back an empty result. The same exception fires if the response carries no text block.

```dart
try {
  final result = await claude.generateText(request);
  print(result.text);
} on AiResponseException catch (e) {
  stderr.writeln('Claude did not answer: $e');
}
```

## See also

- [Mistral](mistral.md)
- [Conversations and vision](../guides/conversations-and-vision.md)
- [Structured output](../guides/structured-output.md)
