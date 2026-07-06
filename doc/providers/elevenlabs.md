---
title: ElevenLabs
description: ElevenLabs provider clients for text-to-speech and sound effects, returning audio bytes
---

# ElevenLabs

ElevenLabs gives you two capabilities in `ai_abstracted`: speech from text with
`ElevenLabsSpeechClient`, and short sound effects with
`ElevenLabsSoundEffectClient`. Both do a JSON POST and get audio bytes back.

The key is `ELEVENLABS_API_KEY`, sent as the `xi-api-key` header. Get it from
your ElevenLabs dashboard under API keys.

- Speech default model: `eleven_multilingual_v2`.
- Speech default voice: `21m00Tcm4TlvDq8ikWAM` (Rachel).
- Sound effects report the model label `eleven-sound-effects`.

## Speak a sentence

For speech, `prompt` is the text you want spoken, not a description of it. With
no `voice` set you get Rachel; with no `model` set you get
`eleven_multilingual_v2`. The result carries the raw audio in `result.bytes`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(
    ProviderId.elevenLabs,
    Platform.environment,
  );
  if (credentials == null) {
    stderr.writeln('Set ELEVENLABS_API_KEY first.');
    return;
  }

  final client = ElevenLabsSpeechClient(credentials: credentials);

  // This makes a real, paid request to ElevenLabs.
  final result = await client.generateSpeech(
    const SpeechRequest(prompt: 'Hello from ai_abstracted.'),
  );

  // The package never touches the filesystem. You decide where bytes go.
  await File('hello.mp3').writeAsBytes(result.bytes);
  print('Wrote ${result.bytes.length} bytes as ${result.mimeType}.');
}
```

The speech endpoint answers with audio bytes directly, so there is no polling
step and no long-job wait. `result.metadata.extra['voice']` records which voice
id was used.

## Pick a voice and tune it

`voice` takes a voice id from your ElevenLabs voice library. These are long
strings like `21m00Tcm4TlvDq8ikWAM`, not display names. Copy the id from the
voice page in your ElevenLabs account.

`stability` and `similarity` are both in the range `0..1` and are optional. Set
them only when you want to override the provider defaults. `format` selects the
audio container and defaults to `mp3`.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const request = SpeechRequest(
  prompt: 'The parcel arrives on Tuesday.',
  voice: '21m00Tcm4TlvDq8ikWAM', // an id from your voice library
  stability: 0.4,
  similarity: 0.8,
  format: 'mp3',
);
```

Hand that request to `client.generateSpeech(request)` as in the first example.
Only the settings you set are sent, so leaving `stability` and `similarity`
null keeps the ElevenLabs defaults.

## Sound effects

`ElevenLabsSoundEffectClient` synthesizes a short non-musical sound from a text
prompt. `seconds` sets the target length. `promptInfluence` is in the range
`0..1` and controls how strongly the prompt steers the result. Both are
optional.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(
    ProviderId.elevenLabs,
    Platform.environment,
  );
  if (credentials == null) {
    stderr.writeln('Set ELEVENLABS_API_KEY first.');
    return;
  }

  final client = ElevenLabsSoundEffectClient(credentials: credentials);

  // This makes a real, paid request to ElevenLabs.
  final result = await client.generateSoundEffect(
    const SoundEffectRequest(
      prompt: 'A heavy wooden door creaking open.',
      seconds: 4,
      promptInfluence: 0.6,
    ),
  );

  await File('creak.mp3').writeAsBytes(result.bytes);
  print('Sound effect model: ${result.metadata.model}.');
}
```

## Tips

- Voice ids are long strings from your voice library. If you pass a human name,
  the request fails; use the id.
- The speech endpoint returns audio in one response. There is nothing to poll,
  so `onProgress` emits `running` then `done` and no `downloading` stage.
- Both clients keep the package free of `dart:io`. To save the audio, you write
  `result.bytes` (a `Uint8List`) to a file yourself.

## Errors

Both clients raise the standard `AiException` subclasses. A bad or missing key
gives `AiAuthException` (HTTP 401/403). A `429` gives `AiRateLimitException`
with an optional `retryAfter`. A rejected voice id or parameter gives
`AiInvalidRequestException` (400/422). Server errors, timeouts, and network
faults surface as `AiTransientException` after the retry policy gives up, and a
malformed body gives `AiResponseException`. See
[error handling](../guides/error-handling.md) for the full set.

## See also

- [Suno for music](suno.md)
- [Result types](../guides/result-types.md)
- [Error handling](../guides/error-handling.md)
