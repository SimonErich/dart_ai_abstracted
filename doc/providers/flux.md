---
title: Black Forest Labs FLUX
description: "Generate images with Black Forest Labs FLUX: submit a prompt, poll until the job is Ready, then download the result"
---

# Black Forest Labs FLUX

`FluxImageClient` generates still images through Black Forest Labs (BFL). The
default model is `flux-pro-1.1`. Unlike the inline-bytes image providers, FLUX
is a job API: you submit a prompt, poll a status URL until the job is `Ready`,
then download the finished image from a URL. `FluxImageClient` does all three
steps for you and hands back the downloaded bytes.

## Credentials

FLUX reads `BFL_API_KEY`. Get the key from your Black Forest Labs dashboard at
bfl.ml. The client sends it as the `x-key` header.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

// Reads BFL_API_KEY from the map, returns null when it is absent.
final credentials = credentialsFromEnv(ProviderId.flux, Platform.environment);
```

## Generate an image

Hand the client an `ImageRequest` and write the returned bytes to a file. The
package never touches the filesystem itself, so you use `dart:io` to save the
result.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final key = Platform.environment['BFL_API_KEY'];
  if (key == null) {
    stderr.writeln('Set BFL_API_KEY first.');
    return;
  }

  final client = FluxImageClient(
    credentials: ProviderCredentials(apiKey: key),
  );

  // Makes a real, billed request to Black Forest Labs.
  final result = await client.generateImage(
    const ImageRequest(
      prompt: 'A red fox asleep in tall grass, soft morning light',
    ),
  );

  await File('fox.png').writeAsBytes(result.bytes);
  stderr.writeln('Saved ${result.bytes.length} bytes as ${result.mimeType}');
}
```

## Control size and watch progress

`ImageRequest` carries `width`, `height`, and `aspectRatio`. FLUX uses all
three when present. Pass an `onProgress` callback to follow the job through its
stages, and read `metadata.providerJobId` afterward to correlate the result with
the BFL job id.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.flux, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set BFL_API_KEY first.');
    return;
  }

  final client = FluxImageClient(
    credentials: credentials,
    // Tune polling for your latency budget.
    pollInterval: const Duration(seconds: 1),
    pollTimeout: const Duration(minutes: 5),
  );

  final result = await client.generateImage(
    const ImageRequest(
      prompt: 'A lighthouse on a cliff at dusk',
      width: 1024,
      height: 768,
      aspectRatio: '4:3',
    ),
    onProgress: (progress) {
      // queued -> running (per poll) -> downloading -> done
      stderr.writeln('stage: ${progress.stage.name}');
    },
  );

  await File('lighthouse.png').writeAsBytes(result.bytes);
  stderr.writeln('BFL job id: ${result.metadata.providerJobId}');
}
```

## How the flow works

One call to `generateImage` runs the whole job:

1. Submit the prompt to `https://api.bfl.ml/v1/<model>`. The response carries a
   `polling_url` and an `id`.
2. Poll `polling_url` on each `pollInterval` (default 2 seconds) until the job
   reports `Ready`. Each poll emits a `running` progress stage.
3. Download `result.sample` (the image URL) and return its bytes.

Progress stages arrive in order: `queued`, then `running` on each poll, then
`downloading`, then `done`. The submitted `id` comes back as
`metadata.providerJobId`.

## Tips

- FLUX returns a URL, not inline bytes. The client downloads it for you, so
  `result.bytes` is the finished image. There is nothing extra to fetch.
- `width` and `height` must be values the model accepts (FLUX works on a size
  grid). If a size is rejected, round to a nearby accepted value, or pass
  `aspectRatio` and let the model choose the pixels.
- `pollTimeout` defaults to 3 minutes. Large images can take longer under load,
  so raise it if you see timeouts.

## Errors

- `AiResponseException` when the submit response has no `polling_url`, or when
  the finished job carries no `result.sample`. Both mean the API returned a body
  the client did not expect.
- `AiTimeoutException` when the job is still not `Ready` after `pollTimeout`.
  Raise `pollTimeout` or retry the request.

```dart
try {
  final result = await client.generateImage(request);
  await File('out.png').writeAsBytes(result.bytes);
} on AiTimeoutException catch (e) {
  stderr.writeln('FLUX did not finish before pollTimeout: $e');
} on AiResponseException catch (e) {
  stderr.writeln('FLUX returned an unexpected body: $e');
}
```

## See also

- [OpenAI images](openai.md) for an inline-bytes image provider.
- [Retries and timeouts](../guides/retries-and-timeouts.md) for tuning
  `retryPolicy`, `pollInterval`, and `pollTimeout`.
- [The provider list](index.md) for every capability and client.
