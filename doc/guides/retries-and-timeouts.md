---
title: Retries and timeouts
description: How the shared transport retries flaky calls, backs off, and times out long-running jobs like Veo, Flux, and Suno
---

# Retries and timeouts

Network calls fail. A provider returns a 503, a request times out, or you hit a
rate limit. The shared transport handles those cases for you: it retries the
call with exponential backoff before giving up. Every provider client uses the
same policy, and you can change it per client.

## The retry policy

`RetryPolicy` controls how many times a call is retried and how long the
transport waits between tries.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const policy = RetryPolicy(
  maxAttempts: 4,
  baseDelay: Duration(milliseconds: 400),
  maxDelay: Duration(seconds: 8),
  jitter: 0.2,
);
```

Those are the defaults, so `const RetryPolicy()` gives you the same thing. The
fields:

- `maxAttempts` (4): the total number of tries, including the first. Four
  attempts means one initial call plus up to three retries.
- `baseDelay` (400ms): the wait before the first retry. Each later step doubles
  from here.
- `maxDelay` (8s): the ceiling. The doubling curve is clamped so a retry never
  waits longer than this.
- `jitter` (0.2): the fractional spread applied around each step, up to plus or
  minus 20 percent, so retries do not all fire at the same instant.

`delayFor(attempt)` returns the backoff before a given retry (1-based). It
doubles `baseDelay` each step and clamps to `maxDelay`:

```dart
const policy = RetryPolicy();

policy.delayFor(1); // around 400ms
policy.delayFor(2); // around 800ms
policy.delayFor(3); // around 1600ms
policy.delayFor(6); // clamped to 8000ms
```

The jitter is deterministic. It is derived from the attempt number, not from a
random source, so `delayFor(2)` returns the same value every run. Tests that
assert on backoff timing stay stable.

## Which failures retry

The transport does not retry everything. It retries two error types and
rethrows the rest immediately:

- `AiTransientException`: 5xx responses, network errors, and timeouts. These
  are worth trying again.
- `AiRateLimitException`: a 429. Backing off and retrying is the right move.

Everything else propagates on the first failure. An `AiAuthException` (bad key),
an `AiInvalidRequestException` (a malformed request), or an `AiResponseException`
(an unexpected body) will not get better on a retry, so the transport does not
waste attempts on them. Errors that are not `AiException` subtypes propagate too.

## A custom policy per client

Every provider client takes a `retryPolicy` in its constructor. Pass your own to
change the behavior for that client. Here Claude gets more attempts:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

final client = ClaudeTextClient(
  credentials: ProviderCredentials(apiKey: 'your-anthropic-key'),
  retryPolicy: const RetryPolicy(maxAttempts: 6),
);
```

Everything else on the policy keeps its default, so this client tries up to six
times with the standard 400ms base delay and 8s ceiling.

## Long-running jobs and poll timeouts

Some providers do not return the result on the first call. Veo (video), Flux
(image), and Suno (music) submit the job, hand back an id, and then the client
polls until the job finishes. That polling has its own two knobs, separate from
the retry policy:

- `pollInterval`: how often the client checks the job.
- `pollTimeout`: how long it keeps polling before giving up.

When the elapsed time passes `pollTimeout`, the client raises an
`AiTimeoutException`. The defaults differ by provider because the jobs take
different amounts of time: Veo polls every 10s for up to 10 minutes, Flux every
2s for up to 3 minutes, Suno every 5s for up to 5 minutes.

A Veo video render can run long, so raise its `pollTimeout` if the default is
too tight:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

final veo = VeoVideoClient(
  credentials: ProviderCredentials(apiKey: 'your-gemini-key'),
  pollInterval: const Duration(seconds: 15),
  pollTimeout: const Duration(minutes: 20),
);
```

If the job is still not done after 20 minutes, `generateVideo` throws an
`AiTimeoutException` labelled with the provider. The retry policy still applies
to each individual poll request, so a transient failure while polling is retried
without ending the whole job.

## The sleep seam

Each client takes a `sleep` parameter, which defaults to `Future.delayed`. It
exists so tests can pass `(_) async {}` and run the backoff and polling logic
instantly, with no real waiting. In normal use you leave it alone. See
[Testing](testing.md) for how the fakes and the sleep seam fit together.

## See also

- [Error handling](error-handling.md): the exception types the transport
  raises, and which ones retry.
- [Progress](progress.md): the `onProgress` stages emitted while a job queues,
  runs, and downloads.
