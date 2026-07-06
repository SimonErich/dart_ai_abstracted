---
title: Testing
description: Test generation code without network calls, using the in-memory fakes and a MockClient for the real provider clients
---

# Testing

You test generation code two ways. Use a fake when you want to test your own logic without touching a provider. Use a `MockClient` when you want to test a real provider client's request and decoding against a canned HTTP response. Neither one makes a network call.

## Fakes for your own code

Every capability ships an in-memory fake: `FakeTextGenerator`, `FakeImageGenerator`, `FakeVideoGenerator`, `FakeSpeechGenerator`, `FakeSoundEffectGenerator`, and `FakeMusicGenerator`. Each one returns fixed bytes, emits the normal `queued`/`running`/`done` progress stages, and records the last request it received in `lastRequest`.

The fakes work because your code depends on the contract type, not on a concrete client. Write functions that accept a `TextGenerator`, `ImageGenerator`, and so on. In production you pass a real client. In tests you pass the fake.

Here is a function that depends on the contract:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<String> summarize(TextGenerator generator, String article) async {
  final result = await generator.generateText(
    TextRequest(prompt: 'Summarize this article:\n$article'),
  );
  return result.text;
}
```

The test passes a `FakeTextGenerator`, checks what the function sent through `lastRequest`, and checks what it returned:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:test/test.dart';

void main() {
  test('summarize forwards the article and returns the completion', () async {
    final fake = FakeTextGenerator(text: 'A short summary.');

    final summary = await summarize(fake, 'A long article body.');

    expect(summary, 'A short summary.');
    expect(fake.lastRequest!.prompt, contains('A long article body.'));
  });
}
```

`FakeTextGenerator` takes `text` (the completion, default `'fake completion'`) and `metadata` (echoed on the result). `FakeImageGenerator` takes `bytes`, `mimeType` (default `'image/png'`), and `metadata`; leave `bytes` off and it returns a tiny deterministic default. The four media fakes follow the same shape and return the MIME type for their kind, such as `'video/mp4'` for video and `'audio/mpeg'` for the audio ones.

## MockClient for the real clients

To test a real provider client, inject an `http.Client`. Every client takes an `httpClient` parameter. Pass a `MockClient` from `package:http/testing`, return a canned response for the request, and assert on both the outgoing request and the decoded result.

Two details keep these tests fast and offline. Pass `sleep: (_) async {}` so the retry logic does not actually wait between attempts. Return the exact body shape the client expects, so its decoding path runs for real.

This test drives `OpenAiImageClient` against a `b64_json` response, the same path the client uses in production:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('OpenAiImageClient decodes a b64_json response', () async {
    final png = Uint8List.fromList([7, 7, 7]);
    late http.Request seen;

    final client = MockClient((request) async {
      seen = request;
      return http.Response(
        jsonEncode({
          'data': [
            {'b64_json': base64Encode(png)},
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final generator = OpenAiImageClient(
      credentials: const ProviderCredentials(apiKey: 'sk-test'),
      httpClient: client,
      sleep: (_) async {},
    );

    final result = await generator.generateImage(const ImageRequest(prompt: 'a dog'));

    expect(result.kind, MediaKind.image);
    expect(result.bytes, png);
    expect(seen.headers['authorization'], 'Bearer sk-test');
    expect(seen.url.path, contains('/v1/images/generations'));
  });
}
```

The `MockClient` callback receives the outgoing request, so you can assert on headers, the URL path, and the JSON body. To test an error path, return a non-2xx status: a `429` maps to `AiRateLimitException`, a `401` or `403` to `AiAuthException`, and a body the client cannot parse to `AiResponseException`. See [error handling](error-handling.md) for the full mapping.

The same pattern works for the polling clients (Flux, Veo, Suno). Return the submit response first, then the poll responses, then the download bytes, keyed on `request.url.path`. Pass a small `pollInterval` and keep `sleep` a no-op so the poll loop does not wait.

## See also

- [Write a custom provider](custom-provider.md)
- [Debugging](debugging.md)
- [Error handling](error-handling.md)
