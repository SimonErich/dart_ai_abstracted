---
title: Suno
description: Generate music with Suno through the sunoapi.org gateway, then download the finished track as bytes
---

# Suno

`SunoMusicClient` generates music from a text prompt. It talks to
`sunoapi.org`, a third-party gateway in front of Suno, not a first-party Suno
API. You get the same `MusicGenerator` contract as every other capability: pass
a `MusicRequest`, get back a `GenerationResult` with the audio bytes.

Music generation is a long job. The client submits the request, polls for the
result, and downloads the finished track once it is ready.

## Credentials

Get a `SUNO_API_KEY` from your sunoapi.org dashboard (not from Suno directly).
The client sends it as an `Authorization: Bearer` header. Requests go to
`https://api.sunoapi.org/api/v1`.

`credentialsFromEnv` reads the key for you and returns `null` when it is absent:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

final credentials = credentialsFromEnv(ProviderId.suno, Platform.environment);
```

## Generate a track

Give a prompt, wait for the track, write the bytes to a file:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.suno, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set SUNO_API_KEY first.');
    return;
  }

  final client = SunoMusicClient(credentials: credentials);

  // This makes a real, paid request to sunoapi.org and can take a minute.
  final result = await client.generateMusic(
    const MusicRequest(prompt: 'upbeat synthwave with a driving bassline'),
  );

  // ai_abstracted never touches the filesystem; you decide where bytes go.
  await File('track.mp3').writeAsBytes(result.bytes);
}
```

The package stays free of `dart:io`. Writing the file is your code, so the
`dart:io` import lives in your app, not in the library.

## How it works

`generateMusic` runs three steps against the gateway:

1. Submit the request to `/generate` and read the task id from the response.
2. Poll `/generate/record-info` until the track reports a finished audio url.
   The default interval is 5 seconds and the default deadline is 5 minutes.
3. Download the first audio url and return its bytes.

`result.metadata.providerJobId` holds the Suno task id, which is useful for
correlating a render with the gateway's own logs.

A single generation takes a while, so pass `onProgress` to drive UI. Suno is a
polling provider, so the stages arrive as `queued`, then `running` on each poll,
then `downloading`, then `done`. See
[the progress guide](../guides/progress.md) for the full stage sequence.

## More control

`MusicRequest` carries the options Suno accepts. Set `instrumental: true` to
skip vocals. `title` and `style` steer the output, and `model` selects a
version on the gateway (the value is passed straight through to sunoapi.org, so
use whatever version strings their docs list):

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.suno, Platform.environment)!;
  final client = SunoMusicClient(credentials: credentials);

  // Real, paid request.
  final result = await client.generateMusic(
    const MusicRequest(
      prompt: 'a slow lo-fi beat for late-night studying',
      instrumental: true,
      title: 'Midnight Desk',
      style: 'lo-fi hip hop',
      model: 'V4', // whatever sunoapi.org accepts
    ),
    onProgress: (progress) => stdout.writeln('stage: ${progress.stage.name}'),
  );

  stdout.writeln('suno task: ${result.metadata.providerJobId}');
  await File('midnight_desk.mp3').writeAsBytes(result.bytes);
}
```

Music jobs can outrun the 5-minute default on busy days. Raise the deadline (and
slow the polling if you like) on the constructor:

```dart
final client = SunoMusicClient(
  credentials: credentials,
  pollInterval: const Duration(seconds: 10),
  pollTimeout: const Duration(minutes: 8),
);
```

`MusicRequest.seconds` and `MusicRequest.format` are not sent to this
gateway; Suno controls track length, and the mime type comes from the
downloaded file. `seed` is not sent either, though it is echoed back on
`result.seedUsed`.

## Errors

- `AiResponseException` when the submit response has no task id, or is otherwise
  malformed.
- `AiTimeoutException` when no finished audio url appears before `pollTimeout`.
  A track that never completes surfaces here, not as a response error.
- Auth, rate-limit, and transient HTTP failures come back as `AiAuthException`,
  `AiRateLimitException`, and `AiTransientException` from the shared transport;
  transient ones are retried per your `RetryPolicy`.

## See also

- [ElevenLabs](elevenlabs.md) for speech and sound effects, the other audio provider.
- [Progress and long jobs](../guides/progress.md) for the polling stage sequence.
