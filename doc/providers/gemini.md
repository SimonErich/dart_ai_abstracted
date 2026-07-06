---
title: Google Gemini
description: Text and image generation with Google Gemini in ai_abstracted, using one GEMINI_API_KEY from Google AI Studio
---

# Google Gemini

Gemini gives you two clients. `GeminiTextClient` handles text and defaults to
`gemini-2.5-flash`. `GeminiImageClient` handles images and defaults to
`gemini-2.5-flash-image`, the model Google nicknames "Nano Banana". Both take
the same credentials and both return a `GenerationResult`.

## The key

You need one `GEMINI_API_KEY` from Google AI Studio (aistudio.google.com, under
API keys). The client sends it as a `?key=` query parameter on the
`generateContent` endpoint, so you never set an auth header yourself. Read it
from the environment and hand it to the client through `ProviderCredentials`:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.gemini, Platform.environment);
  if (credentials == null) {
    throw StateError('Set GEMINI_API_KEY in your environment.');
  }

  final client = GeminiTextClient(credentials: credentials);
  // Makes a real request to Gemini.
  final result = await client.generateText(
    const TextRequest(prompt: 'Write a one-line tagline for a coffee shop.'),
  );

  print(result.text);
}
```

`credentialsFromEnv` returns null when the variable is absent, so you decide how
to handle a missing key. `result.text` is a UTF-8 decode of the returned bytes.

## Generating an image

`GeminiImageClient` returns the image inline as base64, which the client decodes
into `result.bytes` (a `Uint8List`). It does not return a URL. ai_abstracted
never touches the filesystem, so you write the bytes yourself with `dart:io`:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.gemini, Platform.environment);
  if (credentials == null) {
    throw StateError('Set GEMINI_API_KEY in your environment.');
  }

  final client = GeminiImageClient(credentials: credentials);
  // Makes a real request to Gemini (gemini-2.5-flash-image).
  final result = await client.generateImage(
    const ImageRequest(prompt: 'A paper boat on a calm lake, soft morning light.'),
  );

  final extension = result.mimeType == 'image/jpeg' ? 'jpg' : 'png';
  await File('boat.$extension').writeAsBytes(result.bytes);
  print('Wrote boat.$extension (${result.bytes.length} bytes)');
}
```

`result.mimeType` tells you the actual format Gemini returned, so key the file
extension off it rather than assuming PNG.

## Temperature and JSON output

`TextRequest` carries the tuning knobs. Set `temperature` to control sampling.
Set `jsonSchema` to ask Gemini for JSON: when a schema is present, the client
sets the response MIME type to `application/json`, and the model replies with a
JSON document instead of prose.

```dart
final request = TextRequest(
  prompt: 'List three coffee origins as JSON.',
  temperature: 0.2,
  jsonSchema: const {
    'type': 'object',
    'properties': {
      'origins': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  },
);
```

You still parse `result.text` yourself with `dart:convert`. See
[structured output](../guides/structured-output.md) for the full pattern and
its limits across providers.

## Vision input

`gemini-2.5-flash` reads images. Attach one to the current turn with `TextImage`
and ask a question about it in `prompt`:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.gemini, Platform.environment);
  if (credentials == null) {
    throw StateError('Set GEMINI_API_KEY in your environment.');
  }

  final photo = await File('receipt.png').readAsBytes();
  final client = GeminiTextClient(credentials: credentials);
  final result = await client.generateText(
    TextRequest(
      prompt: 'What is the total on this receipt?',
      image: TextImage(bytes: photo, mimeType: 'image/png'),
    ),
  );

  print(result.text);
}
```

For multi-turn chats and more on vision, see
[conversations and vision](../guides/conversations-and-vision.md).

## Tips

- One `GEMINI_API_KEY` covers both Gemini clients here and [Veo](veo.md) for
  video. Veo reads `VEO_API_KEY` first, then falls back to `GEMINI_API_KEY`, so
  the same key works across all three.
- The `flash` models are the cheap, fast defaults. To pick another Gemini model,
  set `TextRequest.model` or `ImageRequest.model`.
- Images always come back inline as decoded bytes, never as a URL. Use
  `result.bytes` directly.

## Errors

Every failure raises a subclass of `AiException`, tagged with the provider name:

- `AiAuthException` for a missing or wrong key (HTTP 401/403).
- `AiRateLimitException` for HTTP 429, carrying an optional `retryAfter`.
- `AiInvalidRequestException` for a rejected request (HTTP 400/422).
- `AiTransientException` for 5xx responses, network drops, and timeouts. The
  client retries these on its own before giving up.
- `AiResponseException` when the body parses but carries no usable part, for
  example "Gemini returned no text part" or "Gemini returned no inline image
  data".

See [error handling](../guides/error-handling.md) for catch patterns and
[retries and timeouts](../guides/retries-and-timeouts.md) for the retry policy.

## See also

- [Veo](veo.md) for video generation on the same key
- [Conversations and vision](../guides/conversations-and-vision.md)
- [Structured output](../guides/structured-output.md)
- [The provider list](index.md)
