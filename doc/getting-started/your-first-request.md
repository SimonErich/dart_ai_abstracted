---
title: Your first request
description: Go from an offline fake completion to a real Claude or Gemini response with the same generateText call
---

# Your first request

This page walks from nothing to a real text completion in four steps. You start
offline with a fake, then read a key from the environment, then swap the fake
for a real provider client. The `generateText` call stays the same the whole
way.

## Step 1: run it offline with the fake

`FakeTextGenerator` returns a fixed completion and never touches the network. Use
it to check the shape of the call before you have a key. It implements the same
`TextGenerator` contract as every real client.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final generator = FakeTextGenerator(text: 'Hello from the fake.');
  final result = await generator.generateText(
    const TextRequest(prompt: 'Write a one-line greeting.'),
  );
  print(result.text); // Hello from the fake.
}
```

`result.text` decodes the result bytes as UTF-8. Every text result carries its
bytes plus normalized metadata; see [result types](../guides/result-types.md).

## Step 2: get a key and read it from the environment

For Claude, create an `ANTHROPIC_API_KEY` in your Anthropic console, then export
it in your shell. For Gemini, use `GEMINI_API_KEY` from Google AI Studio.

`credentialsFromEnv` reads that variable and returns `ProviderCredentials?`. It
returns `null` when the key is absent, so guard the result. `Platform.environment`
comes from `dart:io` in your own program; the package itself stays free of
`dart:io`.

```dart
// Fragment inside main().
final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
if (credentials == null) {
  stderr.writeln('Set ANTHROPIC_API_KEY and try again.');
  return;
}
```

## Step 3: swap the fake for a real client

`ClaudeTextClient` takes those credentials and exposes the same `generateText`
method. Nothing else about the call changes. This step sends a real request and
bills your account.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = credentialsFromEnv(ProviderId.claude, Platform.environment);
  if (credentials == null) {
    stderr.writeln('Set ANTHROPIC_API_KEY and try again.');
    return;
  }

  final generator = ClaudeTextClient(credentials: credentials);
  final result = await generator.generateText(
    const TextRequest(prompt: 'Write a one-line greeting.'),
  );
  print(result.text);
}
```

To use Gemini instead, read `ProviderId.gemini` in step 2 and construct
`GeminiTextClient(credentials: credentials)` here. The rest is identical.

## Step 4: handle a non-text result

Image, video, speech, sound effect, and music results come back as raw bytes in
`result.bytes` (a `Uint8List`). The package never writes files, so you decide
where they go. Write them yourself with `dart:io`.

```dart
// Fragment: persisting bytes from any media result.
await File('out.png').writeAsBytes(result.bytes);
```

Each capability has its own request and metadata fields. See
[result types](../guides/result-types.md) for the six shapes and what their
metadata reports.

## Next

- [Core concepts](core-concepts.md)
- [Result types](../guides/result-types.md)
- [The provider list](../providers/index.md)
