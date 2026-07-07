# Changelog

## 0.2.0

A standards-alignment release. One behavior change (Errors no longer retry) and
a few type-modifier changes; the rest is documentation, tests, and packaging.

- **BREAKING** The value types (`GenerationResult`, `GenerationMetadata`,
  `GenerationProgress`, `ProviderCredentials`) and the concrete `AiException`
  subclasses are now `final`. Extend `AiException` itself for a custom provider
  exception; use composition rather than subclassing a value type.
- **BREAKING** The transport wraps only `Exception`s as transient. An `Error`
  (a programming bug) now propagates with its stack trace instead of being
  retried as a transport failure.
- Added `ProviderCredentials.keyless()` for keyless providers such as Ollama,
  so a missing key stays a loud error on the default constructor.
- `RetryPolicy` is now an `interface class`: implement it to supply a custom
  backoff curve.
- The in-memory fakes are open for extension, so a test can override one method.
- The capability methods now document the exceptions they throw, and the
  library documentation links the key types.
- `@useResult` marks the pure builders (`RetryPolicy.delayFor`,
  `retryableStatus`, `credentialsFromEnv`, `allCredentialsFromEnv`).

## 0.1.0

First public release.

- Provider-agnostic contracts for text, image, video, speech, sound-effect, and
  music generation, each a single async method that takes a typed request and
  returns a `GenerationResult` (bytes plus normalized metadata).
- A shared HTTP transport with exponential backoff, jittered retries, and
  async-job polling for the providers that run long jobs.
- Typed error hierarchy (`AiException` and friends) that maps HTTP status codes
  to auth, rate-limit, invalid-request, transient, and timeout failures.
- Clients for Google Gemini (text and image), Google Veo (video, with Veo 3
  audio), OpenAI (image), Black Forest Labs FLUX (image), ElevenLabs (speech and
  sound effects), Suno (music), Anthropic Claude (text), Mistral (text), and
  Ollama (local text).
- Multi-turn conversations (`TextRequest.history`) and an optional image on the
  current turn (`TextRequest.image`) for vision-capable text models.
- An environment credential loader, a provider registry, and an in-memory fake
  for every capability so downstream code stays testable without a network.
