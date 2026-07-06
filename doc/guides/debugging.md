---
title: Debugging
description: Read ai_abstracted failures by printing the exception, inspecting statusCode and cause, and reproducing offline with MockClient
---

# Debugging

When a request fails, the exception carries most of what you need. Print it, read the fields, then narrow down by symptom. This page shows how.

## Start with the exception

Every failure this package raises is an `AiException`. Catch it and print it. The `toString` shows the provider, the HTTP status, and the message on one line.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> run(ImageGenerator images) async {
  try {
    final result = await images.generateImage(
      const ImageRequest(prompt: 'a red bicycle'),
    );
    print('got ${result.bytes.length} bytes');
  } on AiException catch (error) {
    // toString shows provider, HTTP status, and message, for example:
    // AiAuthException[flux] (HTTP 401): invalid api key
    print(error);
    print('status: ${error.statusCode}'); // null when not from a response
    print('cause: ${error.cause}');        // the underlying error, if any
  }
}
```

Two fields do the heavy lifting. `statusCode` is the HTTP status when the failure came from a response, and null for network errors, malformed bodies, and poll timeouts. `cause` holds the underlying error when the exception wraps one (a socket error, a JSON parse failure), so you can see what the client was reacting to.

## A checklist by symptom

The subclass tells you the category. Catch the specific types when you want to act on each one differently.

```dart
// Inside an async function.
try {
  await images.generateImage(request);
} on AiAuthException catch (error) {
  // Missing or wrong key. Confirm the env var name in credentials.md
  // and that the value reached your process.
  print('auth failed for ${error.provider}: ${error.message}');
} on AiInvalidRequestException catch (error) {
  // Bad parameters: an unsupported size, an empty prompt, a bad aspect ratio.
  print('bad request: ${error.message}');
} on AiRateLimitException catch (error) {
  // 429. retryAfter is set when the provider sent a Retry-After header.
  print('rate limited, wait ${error.retryAfter}');
} on AiResponseException catch (error) {
  // The provider returned a shape the client did not expect.
  print('unexpected response: ${error.message}');
} on AiTimeoutException catch (error) {
  // A long job passed its poll deadline. Raise pollTimeout on the client.
  print('timed out: ${error.message}');
}
```

How to read each one:

- `AiAuthException` (401/403) means the key is missing or wrong. Check the env var name for your provider in [credentials.md](credentials.md), and confirm the value is actually in the environment your process reads.
- `AiInvalidRequestException` (400/422) means the request is malformed. Look at the parameters you passed: an image size the provider does not support, an empty prompt, an aspect ratio it rejects. The message usually quotes the provider's reason.
- `AiResponseException` means the provider returned a body the client did not expect. This one carries a description, not a status code. To see what actually came back, log the raw body (the next two sections show how).
- `AiRateLimitException` (429) carries `retryAfter` when the provider sent a `Retry-After` header. It is a `Duration?`, so it can be null. See [retries-and-timeouts.md](retries-and-timeouts.md) for how the client already backs off.
- `AiTimeoutException` means a long-running job (Flux, Veo, Suno) passed its poll deadline. If the job is genuinely slow, raise `pollTimeout` on the client rather than retrying from scratch.

## Log the HTTP traffic

To see the exact requests and responses, wrap your own `http.Client` and pass it in. Every provider client takes an `httpClient` parameter, so the logger sits between the client and the network.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;

/// Wraps another client and logs every request and response to stderr.
class LoggingClient extends http.BaseClient {
  LoggingClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    stderr.writeln('-> ${request.method} ${request.url}');
    final response = await _inner.send(request);
    stderr.writeln('<- ${response.statusCode} ${request.url}');
    return response;
  }
}

void main() {
  final flux = FluxImageClient(
    credentials: const ProviderCredentials(apiKey: 'your-key'),
    httpClient: LoggingClient(http.Client()),
  );
  // Every call flux makes now prints its method, url, and status.
}
```

This logs the status line. It does not log the response body, because the transport reads that stream once and reading it in the logger would consume it. When you need the body, reproduce the failure with a fake client instead.

## Reproduce a failure offline

`MockClient` from `package:http/testing.dart` returns whatever response you hand it, with no network. Paste the error body the provider sent you into a mock and you can rerun the failure as many times as you like.

```dart
import 'dart:convert';

import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> main() async {
  // Return the exact status and body the provider sent you.
  final client = MockClient((request) async {
    return http.Response(jsonEncode({'error': 'width must be a multiple of 32'}), 400);
  });

  final flux = FluxImageClient(
    credentials: const ProviderCredentials(apiKey: 'test-key'),
    httpClient: client,
  );

  try {
    await flux.generateImage(const ImageRequest(prompt: 'a red bicycle', width: 100));
  } on AiInvalidRequestException catch (error) {
    print(error); // AiInvalidRequestException[flux] (HTTP 400): ...
  }
}
```

This confirms which exception a given status and body produce, and lets you step through the client without spending on a real call. [testing.md](testing.md) covers the in-memory fakes for the same job at a higher level.

## Check the endpoint and baseUrl

If requests reach the wrong host, or a proxy in front of a provider, check two overrides. `endpoint` retargets one client's URL. `baseUrl` on the credentials retargets a whole provider (for example a self-hosted Ollama).

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

void main() {
  // endpoint overrides the submit URL for a single client.
  final flux = FluxImageClient(
    credentials: const ProviderCredentials(apiKey: 'your-key'),
    endpoint: Uri.parse('https://api.bfl.ml/v1/flux-pro-1.1'),
  );

  // baseUrl retargets the provider, for example a remote Ollama instance.
  final ollama = OllamaTextClient(
    credentials: ProviderCredentials(
      apiKey: '',
      baseUrl: Uri.parse('http://gpu-box.local:11434'),
    ),
  );
}
```

A 401 or a connection refused right after an override usually means the override points somewhere unexpected. Print the `Uri` you passed and compare it to the provider's documented host.

## See also

- [error-handling.md](error-handling.md) for the full exception hierarchy and how to recover from each type.
- [testing.md](testing.md) for the in-memory fakes and MockClient patterns.
- [retries-and-timeouts.md](retries-and-timeouts.md) for backoff, `retryAfter`, and `pollTimeout`.
- [credentials.md](credentials.md) for env var names when an `AiAuthException` shows up.
