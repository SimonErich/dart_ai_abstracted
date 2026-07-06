---
title: Performance and cost
description: Spend fewer tokens, dollars, and seconds by capping output, reusing one HTTP client, running requests concurrently, and caching bytes yourself
---

# Performance and cost

Every call to a provider costs tokens or credits and takes time on the wire. The package does not batch, cache, or deduplicate calls for you, so what a run costs comes down to how you make requests. This page covers the levers you control: output size, model choice, client reuse, concurrency, polling cadence, and your own cache.

## Tokens and cost

For text, most of the bill is output tokens. `TextRequest.maxTokens` caps how many the model may generate, so it caps both the length of the answer and the output cost. It defaults to `4096`. If you expect a short answer, set it low.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

// A fragment: build the request, then hand it to a text client.
final request = TextRequest(
  prompt: 'Summarize this release note in two sentences.',
  model: 'gemini-2.5-flash',
  maxTokens: 200,
);
```

`request.model` picks the model. Each client has a default (Gemini text is `gemini-2.5-flash`), but the top model is rarely the cheapest. When you do not need it, name a smaller model on the request and pay less per call. Provider pricing lives in each provider's dashboard, so check there before you settle on a default.

`temperature` does not change the price of a call. It changes how much the output varies. A high temperature makes the model wander, so you are more likely to reject a result and generate it again, and each regeneration is another paid call. If you want output you do not have to redo by hand, use a lower temperature.

## Latency and throughput

Every provider client takes an optional `http.Client`. If you do not pass one, the client creates its own. Create one `http.Client`, share it across many calls so connections get reused, and close it when you are done.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final client = http.Client();
  try {
    final gemini = GeminiTextClient(
      credentials: ProviderCredentials(apiKey: 'your-gemini-key'),
      httpClient: client,
    );
    for (final topic in ['tides', 'granite', 'kelp']) {
      final result = await gemini.generateText(
        TextRequest(prompt: 'Write one sentence about $topic.'),
      );
      print(result.text);
    }
  } finally {
    client.close();
  }
}
```

The loop above waits for each answer before it starts the next. When the requests do not depend on each other, run them at the same time with `Future.wait`. The wall-clock time drops to about the slowest single call instead of the sum.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final client = http.Client();
  final gemini = GeminiTextClient(
    credentials: ProviderCredentials(apiKey: 'your-gemini-key'),
    httpClient: client,
  );
  try {
    final prompts = ['A haiku about rain.', 'A haiku about frost.'];
    final results = await Future.wait([
      for (final prompt in prompts) gemini.generateText(TextRequest(prompt: prompt)),
    ]);
    for (final result in results) {
      print(result.text);
    }
  } finally {
    client.close();
  }
}
```

Concurrency is bounded by the provider's rate limit, not by the package. If you fan out too wide you will get `AiRateLimitException` (HTTP 429). Keep the batch size modest.

## Long jobs

Polling clients (Flux, Veo, Suno) submit a job and then poll until it finishes. `pollInterval` is the wait between polls. It trades API calls against how quickly you notice the job is done. A short interval means you spot completion sooner and spend more poll calls; a long interval means fewer calls and a slower reaction. Shorten it for jobs that finish in seconds, lengthen it for jobs that run for minutes. `pollTimeout` bounds the whole wait and raises `AiTimeoutException` when it is exceeded.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

final flux = FluxImageClient(
  credentials: ProviderCredentials(apiKey: 'your-bfl-key'),
  pollInterval: const Duration(seconds: 1),
  pollTimeout: const Duration(minutes: 1),
);
```

The Flux defaults are a 2 second interval and a 3 minute timeout. Leave them alone unless your jobs are much faster or much slower than that.

## Caching

The package never caches results and never writes files. Every call goes to the provider. If you ask for the same thing twice, you pay twice. So cache the result bytes yourself, keyed by the prompt plus the parameters that change the output.

```dart
import 'dart:typed_data';

import 'package:ai_abstracted/ai_abstracted.dart';

final _imageCache = <String, Uint8List>{};

String _cacheKey(ImageRequest request) =>
    [request.model, request.seed, request.width, request.height, request.prompt].join('|');

Future<Uint8List> generateOnce(ImageGenerator provider, ImageRequest request) async {
  final key = _cacheKey(request);
  final cached = _imageCache[key];
  if (cached != null) {
    return cached;
  }
  final result = await provider.generateImage(request);
  return _imageCache[key] = result.bytes;
}
```

To keep a cache across runs, write `result.bytes` to disk yourself with `File(path).writeAsBytes(result.bytes)` from `dart:io`, and read it back on the next run. The package stays free of `dart:io`; where the bytes live is your call.

For providers that support reproducibility, set `seed` on the request. The same prompt and seed give you the same output, so your cache key stays stable and you avoid regenerating an image you already have. Not every provider honors `seed`, so treat it as a hint, not a guarantee.

## Retries

Every provider client already retries transient failures. The default `RetryPolicy` makes up to 4 attempts with exponential backoff, starting at 400ms and capped at 8s, with deterministic jitter. Rate limits (429) and server errors (5xx) are retried; a 400 or a 401 is not, because retrying will not fix it.

Do not wrap your own retry loop around a call. You would multiply the built-in attempts and hit the rate limit harder. If the defaults do not fit, pass a tuned `RetryPolicy` to the client instead.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

final flux = FluxImageClient(
  credentials: ProviderCredentials(apiKey: 'your-bfl-key'),
  retryPolicy: const RetryPolicy(maxAttempts: 6, maxDelay: Duration(seconds: 20)),
);
```

## See also

- [Retries and timeouts](retries-and-timeouts.md) for how backoff, jitter, and poll deadlines behave.
- [Progress and long jobs](progress.md) for tracking a polling job with `onProgress`.
- [The provider list](../providers/index.md) for each provider's default model and pricing dashboard.
