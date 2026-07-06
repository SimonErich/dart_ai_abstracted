---
title: Conversations and vision
description: Send prior turns as TextRequest.history and attach an image to the current turn for vision-capable text models
---

# Conversations and vision

A `TextRequest` carries more than one prompt. Prior turns go in `history`, the current user turn stays in `prompt`, and a vision-capable model can also read an image attached to that current turn.

## Multi-turn conversations

`TextRequest.history` is a `List<TextMessage>`, oldest first. Build each earlier turn with `TextMessage.user(...)` or `TextMessage.assistant(...)`. Do not put the current turn in `history`. It stays in `prompt`, and the client appends it after the history when it builds the request.

`system` sets an optional system prompt that frames how the model answers. It is not a conversation turn, so leave it out of `history`.

Here is a two-turn conversation. The first user question and the assistant's reply are the history. The follow-up question is the current turn.

```dart
import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = ProviderCredentials(apiKey: 'your-anthropic-key');
  final client = ClaudeTextClient(credentials: credentials);

  final request = TextRequest(
    prompt: 'And what is its population?',
    system: 'You are a concise geography tutor.',
    history: const [
      TextMessage.user('What is the capital of France?'),
      TextMessage.assistant('Paris.'),
    ],
  );

  final result = await client.generateText(request); // makes a real API call
  print(result.text);
}
```

To continue the conversation, append the model's answer and the next question. Take `result.text`, wrap it in `TextMessage.assistant(...)`, add it to the history alongside the previous turns, and set the new question as `prompt`.

## Attaching an image

`TextRequest.image` is a `TextImage`. It holds raw `bytes` and a `mimeType` (default `image/png`), and it attaches to the current user turn only. Use it to ask a question about a picture.

Only vision-capable text clients read the image. Claude and Gemini accept it and send it inline. Mistral and Ollama ignore it, so the request still runs but the image has no effect.

The package never touches the filesystem, so you load the bytes yourself. This example reads a file with `dart:io` and hands the bytes to `TextImage`. Set `mimeType` to match the file (`image/jpeg` here, not the `image/png` default).

```dart
import 'dart:io';

import 'package:ai_abstracted/ai_abstracted.dart';

Future<void> main() async {
  final credentials = ProviderCredentials(apiKey: 'your-anthropic-key');
  final client = ClaudeTextClient(credentials: credentials);

  final bytes = await File('photo.jpg').readAsBytes();

  final request = TextRequest(
    prompt: 'What is in this picture?',
    image: TextImage(bytes: bytes, mimeType: 'image/jpeg'),
  );

  final result = await client.generateText(request); // makes a real API call
  print(result.text);
}
```

You can combine `history` and `image` in the same request. The image always rides on the current turn, never on a turn from the history.

## Tokens and temperature

`maxTokens` caps the length of the reply. It defaults to `4096`. Lower it to keep answers short or to bound cost, raise it when you expect a long completion.

`temperature` is optional. It controls how much the sampling varies. A low value gives steadier, more repeatable answers, a higher value gives more variation. Leave it unset to use the provider's own default.

```dart
final request = TextRequest(
  prompt: 'Summarize the plot of Hamlet in two sentences.',
  maxTokens: 512,
  temperature: 0.2,
);
```

## See also

- [Structured output](structured-output.md) constrains the reply to a JSON schema.
- [Claude](../providers/claude.md) covers the vision-capable text client used above.
