---
title: Google Veo
description: Generate video with Google Veo through a long-running predict job you submit, poll, then download as mp4
---

# Google Veo

`VeoVideoClient` generates video from a text prompt. The default model is
`veo-3.0-generate-001` (Veo 3), which produces a clip with an audio track. Veo
is the only video provider in the package, so `registry.videoGenerator` returns
this client.

Veo runs as a long-running job. You submit the prompt, the client polls Google
until the render finishes, then it downloads the mp4 and hands you the bytes.
That takes minutes, not seconds, so wire up `onProgress` when a person is
waiting.

## Authentication

Veo uses the Gemini API. `credentialsFromEnv(ProviderId.veo, env)` reads
`VEO_API_KEY` and falls back to `GEMINI_API_KEY`, so one Google AI Studio key
covers both Gemini and Veo. The client sends it in the `x-goog-api-key` header.
If neither variable is set, `credentialsFromEnv` returns null.

## Generate a clip

Pass a prompt and a requested length. `result.bytes` is a `Uint8List`. The
package never writes files, so you decide where the mp4 goes. Here it goes to
disk with `dart:io`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.veo, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set VEO_API_KEY or GEMINI_API_KEY.');
    return;
  }

  final client = VeoVideoClient(credentials: credentials);

  // Makes a real, paid request that runs for minutes.
  final result = await client.generateVideo(
    const VideoRequest(
      prompt: 'A paper boat drifting down a rain gutter, close up',
      seconds: 6,
    ),
  );

  await File('boat.mp4').writeAsBytes(result.bytes);
  print('audio track: ${result.metadata.hasAudio}');
}
```

`seconds` is a requested length. Veo treats clip duration as a hint, not a hard
contract, so short prompts can come back a little longer or shorter.

## Aspect ratio, audio, and progress

`aspectRatio` is passed through to Veo (for example `16:9` or `9:16`).
`withAudio` defaults to true and is mirrored into `result.metadata.hasAudio`, so
you can read back whether the clip was requested with sound.

`onProgress` reports four stages as the job moves: `queued` when the operation
is accepted, `running` on each poll while Veo renders, `downloading` once the
render is ready, and `done` after the bytes arrive. The client polls every 10
seconds and gives up after 10 minutes by default. Raise `pollTimeout` for longer
clips.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.veo, Platform.environment);
  if (credentials == null) return;

  final client = VeoVideoClient(
    credentials: credentials,
    pollTimeout: const Duration(minutes: 20),
  );

  // Makes a real, paid request.
  final result = await client.generateVideo(
    const VideoRequest(
      prompt: 'Timelapse of a city skyline from day to night',
      seconds: 8,
      aspectRatio: '16:9',
      withAudio: true,
    ),
    onProgress: (progress) {
      switch (progress.stage) {
        case GenerationStage.queued:
          print('queued');
        case GenerationStage.running:
          print('rendering...');
        case GenerationStage.downloading:
          print('downloading the mp4');
        case GenerationStage.done:
          print('done');
      }
    },
  );

  await File('skyline.mp4').writeAsBytes(result.bytes);
}
```

## Timeouts

If the poll deadline passes before Veo finishes, `generateVideo` throws
`AiTimeoutException`. That usually means the clip is longer or busier than the
default 10 minute window allows. Raise `pollTimeout`, or catch it and report the
stall to the caller.

```dart
try {
  final result = await client.generateVideo(request);
  await File('clip.mp4').writeAsBytes(result.bytes);
} on AiTimeoutException catch (e) {
  stderr.writeln('Veo did not finish before the poll deadline: $e');
}
```

## Tips

- Video takes minutes. Always wire `onProgress` so a waiting user sees the
  `queued`, `running`, `downloading`, `done` steps instead of a frozen screen.
- Veo 3 clips already carry sound. When you use this model you often do not need
  a separate speech or music track from another provider.
- One Google AI Studio key works for both Gemini and Veo. Set `GEMINI_API_KEY`
  once and Veo picks it up.

## See also

- [Gemini](gemini.md) for text and image on the same Google key
- [Progress and long jobs](../guides/progress.md) for the stage callback in
  detail
- [Providers](index.md) for the full capability matrix
