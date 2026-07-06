---
title: Result types
description: One GenerationResult shape carries text, image, video, speech, sound effect, and music, with normalized metadata per medium
---

# Result types

Every capability returns the same type: `GenerationResult`. It does not matter
whether you asked for text, an image, a video, speech, a sound effect, or music.
The bytes and the metadata are always in the same place, so one code path can
handle all six mediums.

## The common shape

A `GenerationResult` has five fields:

- `bytes` (`Uint8List`): the raw output, whatever the medium is.
- `mimeType` (`String`): the IANA MIME type of `bytes`, for example `image/png`
  or `audio/mpeg`.
- `kind` (`MediaKind`): which medium the bytes represent.
- `metadata` (`GenerationMetadata`): normalized fields the provider reported.
- `seedUsed` (`String?`): the seed the provider actually used, when it reports
  one back.

For text there is one extra getter. `result.text` decodes `bytes` as UTF-8, so
you do not have to decode by hand:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

// `result` is a GenerationResult you got back from a generator.
void inspect(GenerationResult result) {
  print(result.kind);        // e.g. MediaKind.image
  print(result.mimeType);    // e.g. image/png
  print(result.metadata.model);
  if (result.kind == MediaKind.text) {
    print(result.text);      // UTF-8 decode of result.bytes
  }
}
```

The package never writes files. You persist `bytes` yourself, usually with
`dart:io`. That import lives in your app, not in this package, which stays free
of `dart:io`:

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> save(GenerationResult result, String path) async {
  await File(path).writeAsBytes(result.bytes);
}
```

`GenerationMetadata` has one required field, `model`. Every other field is
optional, so the same shape fits all six mediums. Providers fill in what they
report and leave the rest null. The sections below say which fields carry
meaning per medium.

## Text

`bytes` is UTF-8 encoded text. The `mimeType` is usually `text/plain`. Read the
string with `result.text` rather than decoding `bytes` yourself.

Meaningful metadata: `model` is the provider model id that produced the
completion (for example `claude-opus-4-8` or `gemini-2.5-flash`). Size and
duration fields do not apply.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveText(GenerationResult result) async {
  // result.text is the UTF-8 string; result.bytes is the same content raw.
  await File('completion.txt').writeAsBytes(result.bytes);
}
```

## Image

`bytes` is an encoded image. The `mimeType` is typically `image/png`.

Meaningful metadata: `width` and `height` in pixels, when the provider reports
them. `durationMs` and `hasAudio` do not apply to a still image.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveImage(GenerationResult result) async {
  final w = result.metadata.width;
  final h = result.metadata.height;
  print('image is ${w}x$h');
  await File('image.png').writeAsBytes(result.bytes);
}
```

## Video

`bytes` is an encoded video clip. The `mimeType` is typically `video/mp4`.

Meaningful metadata: `durationMs` (with `metadata.duration` as a `Duration`),
`hasAudio` for whether the clip carries an audio track, and `width` and
`height`. Veo 3 carries audio, and `hasAudio` reflects the `withAudio` flag you
set on the request.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveVideo(GenerationResult result) async {
  print('duration: ${result.metadata.duration}');
  print('has audio: ${result.metadata.hasAudio}');
  await File('clip.mp4').writeAsBytes(result.bytes);
}
```

## Speech

`bytes` is synthesized audio. `SpeechRequest.format` defaults to `mp3`, so the
`mimeType` is usually `audio/mpeg`.

Meaningful metadata: `durationMs` when the provider reports it (ElevenLabs does
not always report a duration). The voice id lands in `metadata.extra` under the
`voice` key. ElevenLabs voice ids are long strings from your voice library, not
names.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveSpeech(GenerationResult result) async {
  final voice = result.metadata.extra['voice'];
  print('spoken with voice: $voice');
  await File('speech.mp3').writeAsBytes(result.bytes);
}
```

## Sound effect

`bytes` is a short non-musical audio clip. `SoundEffectRequest.format` defaults
to `mp3`, so the `mimeType` is usually `audio/mpeg`.

Meaningful metadata: `durationMs` when reported. Provider-specific fields, if
any, come through `metadata.extra`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveSoundEffect(GenerationResult result) async {
  await File('sfx.mp3').writeAsBytes(result.bytes);
}
```

## Music

`bytes` is a musical track. `MusicRequest.format` defaults to `mp3`, so the
`mimeType` is usually `audio/mpeg`.

Meaningful metadata: `durationMs` when reported, and `providerJobId` for the
long-running job that produced the track. Extra provider fields (for example a
returned title or style) come through `metadata.extra`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> saveMusic(GenerationResult result) async {
  print('job: ${result.metadata.providerJobId}');
  await File('track.mp3').writeAsBytes(result.bytes);
}
```

## Branch on the medium

`MediaKind` has two getters when you want to route by category instead of
checking each value. `isAudio` is true for `speech`, `soundEffect`, and `music`.
`isVisual` is true for `image` and `video`. Use them to pick a file extension or
a preview widget:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

String extensionFor(GenerationResult result) {
  if (result.kind == MediaKind.text) return 'txt';
  if (result.kind.isVisual) return result.kind == MediaKind.image ? 'png' : 'mp4';
  if (result.kind.isAudio) return 'mp3';
  return 'bin';
}
```

## See also

- [The provider list](../providers/index.md)
- [Progress and long jobs](progress.md)
