---
title: Error handling
description: The typed AiException hierarchy, how each HTTP status maps to a subclass, and how to tell a transient failure from a permanent one
---

# Error handling

Every failure this package raises is an `AiException` or one of its subclasses.
The subclass tells you what went wrong, so you catch the specific type you can
act on and let the rest propagate.

## The base type

`AiException` carries four things:

- `message`: a human-readable description of the failure.
- `provider`: the provider id that produced it, for example `openai`.
- `statusCode`: the HTTP status, or `null` when the failure was not an HTTP
  response (a network drop, a poll timeout, a parse error).
- `cause`: the underlying error this wraps, when there is one.

Its `toString()` is labelled with the concrete subclass, the provider, and the
status:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

void report(AiException e) {
  print(e.provider);   // openai
  print(e.statusCode); // 401, or null for a non-HTTP failure
  print(e.message);    // invalid api key
  print(e.cause);      // the wrapped error, when there is one
  print(e);            // AiAuthException[openai] (HTTP 401): invalid api key
}
```

## Which subclass you get

The transport maps each failure to one subclass. This is the full table.

| Condition | Subclass | Extra |
| --- | --- | --- |
| HTTP 401 or 403 | `AiAuthException` | |
| HTTP 429 | `AiRateLimitException` | `Duration? retryAfter` |
| HTTP 400 or 422 | `AiInvalidRequestException` | |
| HTTP 5xx | `AiTransientException` | |
| Network or transport failure | `AiTransientException` | |
| Malformed or unexpected response body | `AiResponseException` | |
| Long-job poll deadline exceeded | `AiTimeoutException` | |
| Any other HTTP status | `AiException` (bare base) | |

`retryAfter` on `AiRateLimitException` is parsed from the `Retry-After` header.
It is set only when the provider sends that header in delta-seconds form. The
HTTP-date form is not parsed, so `retryAfter` can be `null` even on a 429.

## Branching on the failure

Catch the specific subclasses you can respond to. Order the specific types
before the bare `AiException`, which catches everything else last.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<GenerationResult> generate(
  TextGenerator client,
  TextRequest request,
) async {
  try {
    return await client.generateText(request);
  } on AiAuthException catch (e) {
    // 401 or 403. The key is wrong or lacks access. Fix the credential.
    throw StateError('Bad credentials for ${e.provider}: ${e.message}');
  } on AiRateLimitException catch (e) {
    // 429. Back off, then retry. retryAfter is set when the provider sent it.
    final wait = e.retryAfter ?? const Duration(seconds: 5);
    await Future<void>.delayed(wait);
    return generate(client, request);
  } on AiInvalidRequestException catch (e) {
    // 400 or 422. The request is malformed. Fix the prompt or parameters.
    throw ArgumentError('Invalid request to ${e.provider}: ${e.message}');
  } on AiTimeoutException catch (_) {
    // A long job (Flux, Veo, Suno) ran past its poll deadline. Retry or report.
    rethrow;
  } on AiTransientException catch (_) {
    // 5xx or a network error. The client already retried and still failed.
    rethrow;
  } on AiResponseException catch (_) {
    // The provider returned a body the package could not parse.
    rethrow;
  } on AiException catch (_) {
    // Any other status the transport did not classify.
    rethrow;
  }
}
```

The rate-limit branch above retries in a loop for illustration. In real code you
want a bounded number of attempts. See
[retries and timeouts](retries-and-timeouts.md) for a loop that gives up.

## Transient versus permanent

Split the subclasses into two groups and your handling falls out of that.

Transient failures are worth retrying: `AiTransientException` (5xx and network
errors), `AiRateLimitException` (after a wait), and often `AiTimeoutException`
(the job may still finish on a fresh attempt). Provider clients already retry
`AiTransientException` internally using their `RetryPolicy`. By the time one
reaches your `catch`, the client has exhausted its attempts, so retrying again
means adding your own outer loop with its own limit.

Permanent failures will not fix themselves on retry: `AiAuthException` (correct
the key or its permissions), `AiInvalidRequestException` (correct the request),
and usually `AiResponseException` (a provider or version mismatch you need to
look into). Retrying these wastes calls and quota. Surface the message and stop.

## See also

- [Retries and timeouts](retries-and-timeouts.md)
- [Debugging](debugging.md)
