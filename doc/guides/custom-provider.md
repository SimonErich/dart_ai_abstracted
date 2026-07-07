---
title: Writing your own provider
description: Add a provider the package does not ship by implementing a capability contract and mapping failures to the exported error types
---

# Writing your own provider

The package ships clients for a fixed set of providers, but the contracts are public, so you can add your own. Pick the capability you need (for example [`ImageGenerator`](../providers/index.md)), implement it as a `final class`, do your own HTTP, and hand back a `GenerationResult`. Callers that already use the package will treat your client like any other one.

## The honest path for code outside the package

The transport helpers that the built-in clients share (the JSON post, the byte fetch, the retry runner) live under `src/` and are not exported. Your own client cannot call them. That is fine: you do the HTTP yourself with `package:http` and map any non-2xx response to one of the exported error types. Those error types are the contract callers depend on, so mapping to them is what makes your provider behave like the built-in ones.

The exported errors, and when to throw each:

- `AiAuthException` for 401 or 403 (bad or missing key).
- `AiRateLimitException` for 429. It carries an optional `retryAfter`.
- `AiInvalidRequestException` for 400 or 422 (the request was wrong).
- `AiTransientException` for 5xx and network failures. These are the retryable ones.
- `AiResponseException` when the status was fine but the body was missing or malformed.
- `AiTimeoutException` when a long-running poll runs past its deadline.

## A skeleton image client

This implements `ImageGenerator`. It takes credentials and an injectable `http.Client` (pass a fake client in tests), posts the prompt, throws the right `AiException` on a non-2xx, and returns the decoded bytes.

```dart
import 'dart:convert';

import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;

/// An image provider that lives in your app, not in the package.
final class MyImageClient implements ImageGenerator {
  MyImageClient({
    required this.credentials,
    http.Client? httpClient,
    this.retryPolicy = const RetryPolicy(),
  }) : _http = httpClient ?? http.Client();

  final ProviderCredentials credentials;
  final RetryPolicy retryPolicy;
  final http.Client _http;

  static const _provider = 'my-provider';

  @override
  Future<GenerationResult> generateImage(
    ImageRequest request, {
    void Function(GenerationProgress)? onProgress,
  }) async {
    onProgress?.call(const GenerationProgress(stage: GenerationStage.running));

    final response = await _http.post(
      Uri.parse('https://api.example.com/v1/images'),
      headers: {
        'authorization': 'Bearer ${credentials.apiKey}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'prompt': request.prompt,
        if (request.width != null) 'width': request.width,
        if (request.height != null) 'height': request.height,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapError(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, Object?>;
    final b64 = json['image'];
    if (b64 is! String) {
      throw AiResponseException('Provider returned no image', provider: _provider);
    }

    onProgress?.call(const GenerationProgress(stage: GenerationStage.done));
    return GenerationResult(
      bytes: base64Decode(b64),
      mimeType: 'image/png',
      kind: MediaKind.image,
      metadata: GenerationMetadata(model: request.model ?? 'my-model'),
    );
  }

  AiException _mapError(int status, String body) => switch (status) {
    401 || 403 => AiAuthException('Rejected credentials', provider: _provider, statusCode: status),
    429 => AiRateLimitException('Rate limited', provider: _provider, statusCode: status),
    400 || 422 => AiInvalidRequestException('Bad request: $body', provider: _provider, statusCode: status),
    _ => AiTransientException('Provider error', provider: _provider, statusCode: status),
  };
}
```

Once it implements the contract, a caller uses it the same way it uses a built-in client:

```dart
Future<void> main() async {
  final client = MyImageClient(
    credentials: const ProviderCredentials(apiKey: 'your-key'),
  );
  final result = await client.generateImage(
    const ImageRequest(prompt: 'a red bicycle on a beach'),
  );
  // result.bytes is a Uint8List. Persist it in your app; the package never
  // touches the filesystem. With dart:io that is File(path).writeAsBytes(...).
  print('${result.bytes.length} bytes, ${result.mimeType}');
}
```

## Reusing the retry policy

`RetryPolicy` is exported, so you can compute backoff delays without reimplementing the curve. `delayFor(attempt)` returns the wait before the given 1-based retry. Retry the transient failures and let the rest surface:

```dart
Future<GenerationResult> generateWithRetry(
  MyImageClient client,
  ImageRequest request,
) async {
  const policy = RetryPolicy();
  for (var attempt = 1; ; attempt++) {
    try {
      return await client.generateImage(request);
    } on AiTransientException {
      if (attempt >= policy.maxAttempts) rethrow;
      await Future<void>.delayed(policy.delayFor(attempt));
    }
  }
}
```

The retry runner the built-in clients use is not exported, so this loop is the amount of reuse you get from outside the package. An in-package client wraps its HTTP call in that shared runner and gets backoff, jitter, and long-job polling for free.

## Consider sending a pull request

If other people would want this provider, the better home for it is the package itself. Inside the package your client can call the shared transport helpers, join the provider registry, read its key through `credentialsFromEnv`, and ship with a fake, so the whole community gets it and maintains it with you. If that sounds right, open a pull request. See [CONTRIBUTING](https://github.com/SimonErich/dart_ai_abstracted/blob/main/CONTRIBUTING.md) for the layout and the test expectations.

## See also

- [Testing your integration](testing.md)
- [The provider list](../providers/index.md)
