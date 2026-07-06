---
title: OpenAI
description: Generate images with OpenAI's gpt-image-1 model through OpenAiImageClient
---

# OpenAI

OpenAI provides image generation through `OpenAiImageClient`. The default model
is `gpt-image-1`. You hand it a `ProviderCredentials` and an `ImageRequest`, and
you get back `GenerationResult` bytes you can write to disk.

## The key

Set `OPENAI_API_KEY` from the OpenAI platform (platform.openai.com, under API
keys). The client sends it as an `Authorization: Bearer` header. If your account
scopes usage by organization, put the org id in `credentials.organization` and
the client adds an `openai-organization` header.

Load the key from the environment with `credentialsFromEnv`:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

// Returns null when OPENAI_API_KEY is absent.
final credentials = credentialsFromEnv(ProviderId.openai, Platform.environment);
```

## Generate an image

This makes a real, billed request to OpenAI, then writes the bytes to a file.
The package never touches the filesystem itself, so the `dart:io` write lives in
your code, not in `ai_abstracted`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.openai, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set OPENAI_API_KEY first.');
    return;
  }

  final client = OpenAiImageClient(credentials: credentials);

  final result = await client.generateImage(
    const ImageRequest(prompt: 'A paper boat on a calm lake, soft morning light'),
  );

  // result.bytes is a Uint8List. You decide where it goes.
  await File('boat.png').writeAsBytes(result.bytes);
  stdout.writeln('Wrote ${result.bytes.length} bytes as ${result.mimeType}');
}
```

OpenAI can return the image two ways. If the response carries an inline
`b64_json` field, the client decodes it directly. If it carries a `url` instead,
the client downloads that URL and returns the downloaded bytes. Either way you
get the same `GenerationResult`, so you do not have to branch on the shape.

## Size, organization, and tuning

Pass `width` and `height` to request a specific output size. The client sends
them to OpenAI as a `size` string, for example `1024x1024`. Set both together:
if you set only one, the client omits `size` and OpenAI picks a default.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> generate(ProviderCredentials base) async {
  final client = OpenAiImageClient(
    credentials: ProviderCredentials(
      apiKey: base.apiKey,
      organization: 'org-abc123', // sent as the openai-organization header
    ),
    // Point at a proxy or a compatible host. Defaults to the public OpenAI endpoint.
    endpoint: Uri.parse('https://your-proxy.example.com/v1/images/generations'),
    // More attempts and a longer base delay for a flaky network.
    retryPolicy: const RetryPolicy(maxAttempts: 6, baseDelay: Duration(seconds: 1)),
  );

  final result = await client.generateImage(
    const ImageRequest(
      prompt: 'A city skyline at dusk',
      width: 1024,
      height: 1024,
    ),
  );

  stdout.writeln('${result.metadata.width}x${result.metadata.height}');
}
```

The returned `metadata.width` and `metadata.height` echo the values you
requested. `metadata.model` is `gpt-image-1` unless you set `ImageRequest.model`
to something else.

## Tips

- Image generation needs a verified organization on some accounts. If requests
  fail with an auth error even though your key works for text, verify your org in
  the OpenAI dashboard.
- Set `width` and `height` as a pair. A lone dimension is dropped.

## Errors

- A missing or invalid key raises `AiAuthException` (HTTP 401 or 403).
- If OpenAI returns a response with no usable image data (no `b64_json` and no
  `url`), the client raises `AiResponseException`.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> run(OpenAiImageClient client) async {
  try {
    final result = await client.generateImage(
      const ImageRequest(prompt: 'A red bicycle against a white wall'),
    );
    stdout.writeln('Got ${result.bytes.length} bytes');
  } on AiAuthException catch (e) {
    stderr.writeln('Check OPENAI_API_KEY (and org verification): $e');
  } on AiResponseException catch (e) {
    stderr.writeln('No image came back: $e');
  }
}
```

## See also

- [Flux images](flux.md)
- [Gemini images](gemini.md)
