---
title: Structured output
description: Get JSON back from a text model by passing TextRequest.jsonSchema, and validate the parsed result yourself
---

# Structured output

When you want a text model to return JSON instead of prose, pass a `jsonSchema`
map on the `TextRequest`. The presence of that map is the trigger: each text
client turns on its provider's JSON mode. You then parse `result.text` with
`jsonDecode`.

## Ask for JSON

`TextRequest.jsonSchema` is a `Map<String, Object?>?`. Set it to a JSON Schema
that describes the object you expect. Here is a request against Gemini that
extracts two fields, then decodes the reply.

```dart
import 'dart:convert';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = ProviderCredentials(apiKey: 'YOUR_GEMINI_API_KEY');
  final client = GeminiTextClient(credentials: credentials);

  const request = TextRequest(
    prompt: 'Extract the city and country from: "I live in Kyoto, Japan."',
    jsonSchema: {
      'type': 'object',
      'properties': {
        'city': {'type': 'string'},
        'country': {'type': 'string'},
      },
      'required': ['city', 'country'],
    },
  );

  final result = await client.generateText(request); // makes a real API call
  final data = jsonDecode(result.text) as Map<String, Object?>;
  print(data['city']); // Kyoto
  print(data['country']); // Japan
}
```

`result.text` is the UTF-8 decode of `result.bytes`, so for a text result it is
the model's reply as a string. `jsonDecode` turns that string into Dart maps and
lists.

## What each client does with the schema

The clients differ in how much they can enforce. Today they use the schema map
as an on/off signal for JSON mode. Here is what each one sends when
`jsonSchema` is non-null:

- **Gemini** (`GeminiTextClient`) sets `responseMimeType` to
  `application/json` in `generationConfig`.
- **Mistral** (`MistralTextClient`) sets `response_format` to
  `{"type": "json_object"}`.
- **Ollama** (`OllamaTextClient`) sets `format` to `json`.
- **Claude** (`ClaudeTextClient`) has no schema switch. It ignores `jsonSchema`.
  To get JSON from Claude, ask for it in the `prompt` or `system` field.

Notice what the clients do not do: they do not send your full schema on the
wire, and they do not check that the reply matches it. The map's presence flips
the provider into JSON mode. The fields, types, and `required` list in your map
are a description for you, not a contract the provider validates against. Treat
the reply as untrusted and validate it yourself (see below).

## Getting JSON from Claude

Since Claude has no JSON-mode flag here, state the shape you want in the prompt
or system message. You can still fill in `jsonSchema` for your own code to read,
but the client will not act on it.

```dart
import 'dart:convert';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = ProviderCredentials(apiKey: 'YOUR_ANTHROPIC_API_KEY');
  final client = ClaudeTextClient(credentials: credentials);

  const request = TextRequest(
    prompt: 'Extract the city and country from: "I live in Kyoto, Japan."',
    system: 'Reply with a single JSON object with string keys '
        '"city" and "country". Output no other text.',
  );

  final result = await client.generateText(request); // makes a real API call
  final data = jsonDecode(result.text) as Map<String, Object?>;
  print(data['city']);
  print(data['country']);
}
```

Models sometimes wrap JSON in a code fence or add a sentence around it. If that
happens, strip the surrounding text before you decode, or tighten the
instruction.

## Validate the parsed result

Because no client enforces your schema, check the decoded value before you use
it. `jsonDecode` can also throw on a malformed reply, so wrap it.

```dart
Map<String, String> parseLocation(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw StateError('Model did not return valid JSON: $text');
  }
  if (decoded is! Map<String, Object?>) {
    throw StateError('Expected a JSON object, got: $text');
  }
  final city = decoded['city'];
  final country = decoded['country'];
  if (city is! String || country is! String) {
    throw StateError('Missing or non-string city/country: $text');
  }
  return {'city': city, 'country': country};
}
```

This keeps the parsing failure at your boundary, where you can retry, fall back,
or surface a clear error, rather than letting a bad shape flow into the rest of
your code.

## See also

- [Conversations and vision](conversations-and-vision.md) for multi-turn history and image input on the same `TextRequest`
- [The Gemini provider](../providers/gemini.md) for its models, defaults, and endpoint
