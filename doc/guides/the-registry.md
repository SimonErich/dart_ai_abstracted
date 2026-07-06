---
title: The provider registry
description: Use ProviderRegistry to resolve a ProviderId plus credentials to a concrete capability client when you pick the provider at runtime
---

# The provider registry

`ProviderRegistry` turns a `ProviderId` and a set of credentials into a
concrete client for one capability. You call one method per capability, pass
the id you want, and get back the matching generator. Reach for it when the
provider is a runtime value (a config entry, a user setting, an environment
variable) instead of a type you can name at compile time.

The registry holds no state, so a single `const` instance is enough:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const registry = ProviderRegistry();
```

## The six methods

There is one method per capability. Each takes the same three arguments: a
`ProviderId`, a `ProviderCredentials`, and an optional named `httpClient` for
injecting your own `http.Client`.

- `imageGenerator(id, credentials, {httpClient})` returns an `ImageGenerator`.
- `videoGenerator(id, credentials, {httpClient})` returns a `VideoGenerator`.
- `speechGenerator(id, credentials, {httpClient})` returns a `SpeechGenerator`.
- `soundEffectGenerator(id, credentials, {httpClient})` returns a `SoundEffectGenerator`.
- `musicGenerator(id, credentials, {httpClient})` returns a `MusicGenerator`.
- `textGenerator(id, credentials, {httpClient})` returns a `TextGenerator`.

Each returns the provider's client for that capability, or throws when the
provider does not offer it.

## Picking a provider at runtime

Say the text provider comes from config. You hold it as a `ProviderId`
variable and let the registry pick the client. The rest of your code depends
only on the `TextGenerator` contract, so switching providers is a one-line
change to the id.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<String> summarize(
  ProviderId provider,
  ProviderCredentials credentials,
  String text,
) async {
  const registry = ProviderRegistry();
  final client = registry.textGenerator(provider, credentials);
  final result = await client.generateText(
    TextRequest(prompt: 'Summarize this in one sentence:\n$text'),
  );
  return result.text;
}
```

Pass `ProviderId.claude`, `ProviderId.gemini`, `ProviderId.mistral`, or
`ProviderId.ollama` and the same function talks to a different backend. See
[credentials.md](credentials.md) for loading the matching key from the
environment.

## When a provider lacks a capability

Not every provider offers every capability. Text comes from Gemini, Claude,
Mistral, and Ollama. Image comes from Gemini, OpenAI, and Flux. Video is Veo
only, speech and sound effects are ElevenLabs, and music is Suno. Ask for a
capability a provider does not have and the method throws
`AiInvalidRequestException`. The message names the provider and the missing
capability, for example `Provider "flux" does not support text generation`.

Catch it when the provider is user-supplied and you cannot be sure it fits:

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

TextGenerator? tryTextGenerator(
  ProviderId provider,
  ProviderCredentials credentials,
) {
  const registry = ProviderRegistry();
  try {
    return registry.textGenerator(provider, credentials);
  } on AiInvalidRequestException {
    return null; // this provider has no text client
  }
}
```

`AiInvalidRequestException` is a subclass of `AiException`, so you can also let
it bubble up to a single handler. See [error-handling.md](error-handling.md)
for the full exception hierarchy.

## Or construct the client directly

The registry earns its place when the provider is dynamic. When you already
know the provider at compile time, name the client and skip the lookup. This
is shorter and the type is fixed, so a mismatched capability is a compile
error instead of a thrown exception.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<String> summarize(
  ProviderCredentials credentials,
  String text,
) async {
  final client = ClaudeTextClient(credentials: credentials);
  final result = await client.generateText(
    TextRequest(prompt: 'Summarize this in one sentence:\n$text'),
  );
  return result.text;
}
```

Both paths build the same client with the same defaults. Use the registry for
provider choice you resolve at runtime, and the constructor for a provider you
have already settled on.

## See also

- [credentials.md](credentials.md) for building `ProviderCredentials` and loading keys from the environment.
- [error-handling.md](error-handling.md) for `AiInvalidRequestException` and the rest of the exception types.
