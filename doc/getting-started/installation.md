---
title: Installation
description: Add ai_abstracted to a Dart or Flutter project and run an offline smoke test with a fake
---

# Installation

`ai_abstracted` is a single package that gives you one set of contracts for text, image, video, speech, sound effect, and music generation. Add it, add one import, and you are ready to call a provider or a fake.

## Add the package

From the root of your project:

```sh
dart pub add ai_abstracted
```

That edits `pubspec.yaml` and resolves the dependency. If you prefer to add it by hand, put this under `dependencies`:

```yaml
dependencies:
  ai_abstracted: ^0.1.0
```

Then run `dart pub get` (or `flutter pub get` in a Flutter app).

## Requirements

The package targets Dart SDK `^3.12.0`. That constraint comes from the package itself:

```yaml
environment:
  sdk: ^3.12.0
```

`ai_abstracted` is pure Dart. It has no Flutter dependency and no `dart:io` in its own code, so it runs the same on a server, in a CLI tool, and inside a Flutter app. Its only runtime dependencies are `http` and `meta`.

Because the package never touches the filesystem, it hands you bytes and lets you decide where they go. A `GenerationResult` carries `result.bytes` as a `Uint8List`. On a server or CLI you write those bytes yourself with `dart:io`:

```dart
// Fragment: on a platform that has dart:io.
import 'dart:io';

await File('out.png').writeAsBytes(result.bytes);
```

In a Flutter app you would use the platform equivalent (for example `path_provider` plus `File`, or your own storage layer). The package stays out of that decision on purpose, so it can run anywhere.

## The one import

Every public type comes from a single barrel. This is the only import you need:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';
```

Do not import anything under `src/`. The barrel exports the requests, results, contracts, provider clients, fakes, registry, and errors.

## Smoke test with a fake

You can confirm the install without a network call or an API key. Every capability ships an in-memory fake. `FakeTextGenerator` returns a fixed completion (`'fake completion'` by default) and records the last request it saw.

Put this in `bin/smoke.dart` and run `dart run bin/smoke.dart`:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final generator = FakeTextGenerator();

  final result = await generator.generateText(
    TextRequest(prompt: 'Say hello'),
  );

  print(result.text); // fake completion
  print(generator.lastRequest?.prompt); // Say hello
}
```

`generateText` returns a `Future<GenerationResult>`. For a text result, `result.text` decodes the bytes as UTF-8. If that prints `fake completion`, the package is installed and importing correctly. Swap `FakeTextGenerator` for a real provider client when you are ready to make live requests.

## Next

- [Your first request](your-first-request.md): make a real call to a provider.
- [Core concepts](core-concepts.md): requests, results, contracts, and how they fit together.
