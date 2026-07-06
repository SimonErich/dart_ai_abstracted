---
title: Progress and long jobs
description: Watch a generation job with the onProgress callback and the GenerationStage lifecycle
---

# Progress and long jobs

Every generate method takes an optional `onProgress` callback. You pass a
function, and the client calls it with a `GenerationProgress` each time the job
moves to a new stage. Use it to keep a UI or a CLI alive while a slow job runs.

## The callback

The parameter is the same on all six capabilities:

```dart
void Function(GenerationProgress)? onProgress
```

So `generateImage`, `generateVideo`, `generateMusic`, and the rest all accept it.
A `GenerationProgress` carries three fields:

```dart
GenerationProgress({
  required GenerationStage stage,
  double? fraction,
  String? message,
});
```

`stage` is the field you act on. `fraction` and `message` are optional and, on
most providers today, come through as `null`. Read [Fraction and message](#fraction-and-message)
below before you build UI around them.

## The stages

`GenerationStage` has four values, in lifecycle order:

- `queued` : the provider accepted the job but has not started it.
- `running` : the provider is generating the result.
- `downloading` : the result is ready and the bytes are being fetched.
- `done` : the job finished and `bytes` are available.

Not every job passes through all four. Which ones you see depends on whether the
provider answers in one request or makes you poll.

## Immediate versus polling providers

Providers that return the result in a single request emit two updates:
`running`, then `done`.

Polling providers (Flux, Veo, Suno) submit a job and then poll a status URL
until the result is ready. They emit more:

- `queued` before the first poll.
- `running` before each poll after the first, so this repeats once per poll for
  as long as the job runs.
- `downloading` once, before the result bytes are fetched.
- `done` once the bytes are in hand.

A job that finishes on its very first poll skips `running` and goes
`queued` then `downloading` then `done`. So do not treat `running` as
guaranteed. Treat `done` as the terminal signal.

If a polling provider never finishes within its poll timeout, the generate call
throws `AiTimeoutException` instead of returning. See
[Retries and timeouts](retries-and-timeouts.md) for the timeout knobs.

## Wiring it to a CLI status line

This example runs a real Flux image job and rewrites one terminal line as the
stage changes. It makes a real request and spends credits, so it needs
`BFL_API_KEY` in the environment.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.flux, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set BFL_API_KEY first.');
    exit(1);
  }

  final flux = FluxImageClient(credentials: credentials);
  final result = await flux.generateImage(
    const ImageRequest(prompt: 'a red bicycle against a white wall'),
    onProgress: (progress) => stdout.write('\r${_label(progress.stage)}   '),
  );
  stdout.writeln();

  await File('bicycle.png').writeAsBytes(result.bytes);
}

String _label(GenerationStage stage) => switch (stage) {
  GenerationStage.queued => 'queued...',
  GenerationStage.running => 'generating...',
  GenerationStage.downloading => 'downloading...',
  GenerationStage.done => 'done',
};
```

The `\r` returns the cursor to the start of the line, so each update overwrites
the last one instead of stacking. `ai_abstracted` itself uses no `dart:io`; the
file writing, `stdout`, and `Platform.environment` above are the caller's
choice, kept out of the package.

## Fraction and message

`fraction` (a 0..1 estimate) and `message` (a status string) exist on
`GenerationProgress`, but the current provider clients do not populate them, so
they read as `null`. Do not gate a progress bar on `fraction` yet: check for
null and fall back to the stage.

```dart
onProgress: (progress) {
  final percent = progress.fraction;
  if (percent != null) {
    stdout.write('\r${(percent * 100).round()}%   ');
  } else {
    stdout.write('\r${progress.stage.name}   ');
  }
}
```

`GenerationProgress` has value equality, so you can skip a redundant redraw by
holding the last value and comparing before you write.

## See also

- [Retries and timeouts](retries-and-timeouts.md)
- [Result types](result-types.md)
