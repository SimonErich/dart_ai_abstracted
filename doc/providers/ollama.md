---
title: Ollama
description: Local, keyless text generation with OllamaTextClient against a running Ollama daemon (default model llama3.1)
---

# Ollama

Ollama runs text models on your own machine, so there is no API key and no
per-token cost. `OllamaTextClient` talks to a local Ollama daemon over its
`/api/chat` endpoint and returns a text `GenerationResult` like any other
provider.

By default the client posts to `http://localhost:11434/api/chat` and uses the
`llama3.1` model. Pull the model once with `ollama pull llama3.1`, make sure the
daemon is running, and you are ready to generate.

## Simple completion

This makes a real request to a local Ollama. The model must already be pulled
(`ollama pull llama3.1`).

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final client = OllamaTextClient(
    credentials: const ProviderCredentials(apiKey: ''),
  );

  final result = await client.generateText(
    const TextRequest(prompt: 'Write one sentence about local models.'),
  );

  print(result.text);
}
```

The `apiKey` is empty because Ollama does not authenticate. `result.text`
decodes the response bytes as UTF-8 for you.

## System prompt, history, temperature, and JSON

You can frame the model with a `system` prompt, carry prior turns in `history`,
set `temperature`, and ask for JSON output. Passing a `jsonSchema` sets Ollama's
`format` to `json`, so the model returns a parseable JSON string. The daemon
enforces valid JSON, but it does not validate against the schema shape, so treat
the schema as a hint and still parse defensively.

```dart
import 'dart:convert';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  // Point at a remote Ollama host with baseUrl; drop it to use localhost.
  final client = OllamaTextClient(
    credentials: ProviderCredentials(
      apiKey: '',
      baseUrl: Uri.parse('http://host:11434'),
    ),
  );

  final result = await client.generateText(
    TextRequest(
      prompt: 'Give me the capital as JSON.',
      model: 'llama3.1',
      system: 'You answer with strict JSON only.',
      temperature: 0.2,
      history: const [
        TextMessage.user('We are talking about France.'),
        TextMessage.assistant('Understood, France it is.'),
      ],
      jsonSchema: const {
        'type': 'object',
        'properties': {
          'capital': {'type': 'string'},
        },
      },
    ),
  );

  final data = jsonDecode(result.text) as Map<String, Object?>;
  print(data['capital']);
}
```

The `baseUrl` override keeps the `/api/chat` path and swaps the host, so you can
run the daemon on another machine on your network and point every request there.

## Tips

- No key, no cost. Everything runs on your machine, which makes Ollama a good
  fit for offline development and for tests that want a real model instead of a
  fake.
- The model has to exist locally. `ollama pull <model>` first, then pass that
  name as `TextRequest.model`. The default is `llama3.1`.
- Start the daemon before you generate. `OllamaTextClient` does not launch
  Ollama for you.

## Errors

When the daemon is not running or the host is unreachable, the client raises
`AiTransientException`. That is the retryable error class, so a short delay and
a retry is reasonable once you confirm the daemon is up. See
[error handling](../guides/error-handling.md) for the full exception set.

## See also

- [Mistral](mistral.md) for a hosted text provider with the same request shape
- [Credentials](../guides/credentials.md) for the keyless and `baseUrl` setup
