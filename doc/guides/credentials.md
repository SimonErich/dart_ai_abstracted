---
title: Credentials and configuration
description: How API keys and connection settings reach a provider client, and how to load them from the environment
---

# Credentials and configuration

Every provider client needs an API key and, sometimes, a connection override.
Both travel in one value: `ProviderCredentials`. You build it yourself or load
it from the environment, then hand it to a client or to the registry.

## ProviderCredentials

`ProviderCredentials` holds the key and the optional connection settings for a
single provider. Only `apiKey` is required.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

const credentials = ProviderCredentials(apiKey: 'sk-...');
```

The other fields are optional and default to unset or empty:

- `apiKey` (`String`, required) authenticates the request. It may be empty for
  keyless providers such as Ollama.
- `baseUrl` (`Uri?`) overrides the host, for self-hosted or proxied endpoints.
- `organization` (`String?`) sets an organization id, for providers that scope
  by organization (OpenAI).
- `project` (`String?`) sets a project id, for providers that scope by project.
- `extra` (`Map<String, String>`) carries provider-specific settings, passed
  through verbatim.

```dart
final credentials = ProviderCredentials(
  apiKey: 'sk-...',
  organization: 'org-abc123',
);
```

## Load from the environment

Hardcoding a key in source is a mistake waiting to leak. The common path is to
read the key from an environment variable. `credentialsFromEnv` does that for
one provider: give it a `ProviderId` and an environment map, and it returns
`ProviderCredentials?`.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

void main() {
  final credentials = credentialsFromEnv(ProviderId.openai, Platform.environment);
  if (credentials == null) {
    stderr.writeln('OPENAI_API_KEY is not set');
    return;
  }
  // Use credentials with a client or the registry.
}
```

It returns `null` when the provider's key is absent, so you can check for a
missing key without a `try`. Two providers behave differently:

- Ollama is keyless. It always resolves to credentials with an empty `apiKey`,
  never `null`.
- Veo authenticates through the Gemini API. It reads `VEO_API_KEY` first, then
  falls back to `GEMINI_API_KEY`.

`Platform.environment` comes from `dart:io`. The package itself does not depend
on `dart:io`, so it does not read the environment for you. You pass the map in.
In a test you can pass a plain literal instead:

```dart
final credentials = credentialsFromEnv(
  ProviderId.gemini,
  {'GEMINI_API_KEY': 'test-key'},
);
```

## Load every configured provider at once

`allCredentialsFromEnv` walks all providers and returns a map of the ones whose
key is present. Ollama is always included (keyless). Veo is included whenever a
Veo or Gemini key is set.

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

void main() {
  final all = allCredentialsFromEnv(Platform.environment);
  for (final id in all.keys) {
    stdout.writeln('configured: ${id.id}');
  }
}
```

Use this at startup to see which providers are ready, or to build a lookup you
pass around your app.

## Environment variable per provider

| Provider   | `ProviderId`          | Environment variable                        |
| ---------- | --------------------- | ------------------------------------------- |
| Gemini     | `ProviderId.gemini`   | `GEMINI_API_KEY`                            |
| Veo        | `ProviderId.veo`      | `VEO_API_KEY`, then `GEMINI_API_KEY`        |
| OpenAI     | `ProviderId.openai`   | `OPENAI_API_KEY`                            |
| Flux       | `ProviderId.flux`     | `BFL_API_KEY`                               |
| ElevenLabs | `ProviderId.elevenLabs` | `ELEVENLABS_API_KEY`                      |
| Suno       | `ProviderId.suno`     | `SUNO_API_KEY`                              |
| Claude     | `ProviderId.claude`   | `ANTHROPIC_API_KEY`                         |
| Mistral    | `ProviderId.mistral`  | `MISTRAL_API_KEY`                           |
| Ollama     | `ProviderId.ollama`   | none (keyless)                              |

Flux reads `BFL_API_KEY` (Black Forest Labs), not `FLUX_API_KEY`. Claude reads
`ANTHROPIC_API_KEY`, matching Anthropic's own tooling. These names trip people
up, so check them against the table when a key seems set but does not resolve.

## Point at a self-hosted or proxied endpoint

`baseUrl` changes where a client sends its requests. Use it for a remote Ollama,
a corporate gateway, or any proxy that fronts a provider. The key stays empty
for keyless Ollama:

```dart
final ollama = ProviderCredentials(
  apiKey: '',
  baseUrl: Uri.parse('http://gpu-box.internal:11434'),
);
```

For a keyed provider behind a gateway, set both:

```dart
final proxied = ProviderCredentials(
  apiKey: 'sk-...',
  baseUrl: Uri.parse('https://ai-gateway.internal/openai'),
);
```

## A note on secrets

Keep keys out of source. Do not paste an API key into a `.dart` file or commit
one to git. Read keys from the environment, a `.env` file you keep untracked, or
a secret manager, then pass them in as a map. `credentialsFromEnv` and
`allCredentialsFromEnv` exist so the key lives in one place and never in your
code.

## See also

- [The provider registry](the-registry.md) turns credentials into a capability client.
- [Provider reference](../providers/index.md) lists each provider, its key, and its models.
