# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the versions follow [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-07-06

First public release.

### Added

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
