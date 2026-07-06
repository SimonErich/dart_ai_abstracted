---
title: Mistral
description: Mistral text generation with MistralTextClient over the OpenAI-style chat completions endpoint
---

# Mistral

Mistral gives you text completions through `MistralTextClient`. It posts to
Mistral's `/v1/chat/completions` endpoint, which follows the OpenAI request
shape, so the messages, `temperature`, and JSON-mode fields look like ones you
have seen before. The default model is `mistral-large-latest`.

## Credentials

Mistral uses one API key. Create it in your Mistral console (console.mistral.ai)
under API keys, then put it in the environment as `MISTRAL_API_KEY`. The client
sends it as an `Authorization: Bearer` header.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.mistral, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set MISTRAL_API_KEY first.');
    return;
  }

  // Makes a real, billed request to Mistral.
  final client = MistralTextClient(credentials: credentials);
  final result = await client.generateText(
    const TextRequest(prompt: 'Give me one fact about the Mistral wind.'),
  );

  print(result.text);
}
```

`result.text` is the completion decoded from `result.bytes` (UTF-8). The client
never touches the filesystem. If you want to save the raw bytes, write them
yourself with `dart:io`: `File('out.txt').writeAsBytes(result.bytes)`.

## System prompt, history, and temperature

For the current user turn you set `prompt`. A system prompt frames the model's
behavior, and `history` carries prior turns oldest first. Set `temperature` to
control sampling. This fragment assumes you already built `client` as above.

```dart
final result = await client.generateText(
  TextRequest(
    prompt: 'And a shorter version?',
    system: 'You write terse, factual answers. No preamble.',
    history: [
      TextMessage.user('Explain the Mistral wind in two sentences.'),
      TextMessage.assistant('The Mistral is a strong, cold northwesterly wind '
          'that blows through the Rhone valley toward the Mediterranean.'),
    ],
    temperature: 0.2,
  ),
);
```

The client maps these straight onto the `messages` array: the system prompt
first, then each history turn, then your `prompt` as the final user message.

## JSON mode

Pass a `jsonSchema` to turn on JSON mode. On this client the schema's presence
toggles Mistral's `response_format: {"type": "json_object"}`. The schema keys
themselves are not forwarded, so Mistral returns valid JSON but does not enforce
your exact shape. Decode `result.text` yourself.

```dart
final result = await client.generateText(
  TextRequest(
    prompt: 'List three French wine regions with their main color, as JSON.',
    jsonSchema: {
      'type': 'object',
      'properties': {
        'regions': {'type': 'array'},
      },
    },
  ),
);

// Needs `import 'dart:convert';`.
final data = jsonDecode(result.text) as Map<String, Object?>;
```

For the full picture of structured output across providers, see
[structured output](../guides/structured-output.md).

## Notes and limits

- The OpenAI-style request shape makes this client familiar if you have used
  chat completions before. Messages, `temperature`, and `max_tokens` all line up.
- `TextRequest` has an `image` field, but this client does not send images.
  Passing one has no effect here. For text plus image, use
  [Claude](claude.md), which supports vision.

## Errors

Failures raise the usual `AiException` subtypes, tagged with the provider:

- `AiAuthException` when the key is missing or wrong (HTTP 401/403).
- `AiRateLimitException` on HTTP 429, with an optional `retryAfter`.
- `AiInvalidRequestException` for a rejected request (HTTP 400/422).
- `AiTransientException` for 5xx and network errors; the client retries these
  under its `RetryPolicy` before giving up.
- `AiResponseException` if the body arrives without message content.

See [error handling](../guides/error-handling.md) for catching and reacting to
these.

## See also

- [Ollama](ollama.md) for the same text contract against a local, keyless model.
- [Claude](claude.md) for text with vision support.
- [Structured output](../guides/structured-output.md) for JSON across providers.
- [Conversations and vision](../guides/conversations-and-vision.md) for building
  multi-turn requests.
