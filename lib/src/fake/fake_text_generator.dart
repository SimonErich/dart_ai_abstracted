import 'dart:convert';
import 'dart:typed_data';

import '../contracts/text_generator.dart';
import '../core/generation_metadata.dart';
import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/media_kind.dart';
import '../core/requests/text_request.dart';

/// An in-memory [TextGenerator] for tests: returns a fixed completion.
/// {@category Testing}
class FakeTextGenerator implements TextGenerator {
  /// Creates a [FakeTextGenerator] that always returns [text].
  ///
  /// [metadata] is echoed on the result; the bytes are the UTF-8 encoding of
  /// [text] with MIME type `text/plain`.
  FakeTextGenerator({
    this.text = 'fake completion',
    this.metadata = const GenerationMetadata(model: 'fake-text'),
  });

  /// The completion text every call returns.
  final String text;

  /// The metadata echoed on the result.
  final GenerationMetadata metadata;

  /// The most recent request passed to [generateText], or null before any.
  TextRequest? lastRequest;

  @override
  Future<GenerationResult> generateText(
    TextRequest request, {
    void Function(GenerationProgress)? onProgress,
  }) async {
    lastRequest = request;
    onProgress
      ?..call(const GenerationProgress(stage: GenerationStage.queued))
      ..call(const GenerationProgress(stage: GenerationStage.running))
      ..call(const GenerationProgress(stage: GenerationStage.done));
    return GenerationResult(
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: 'text/plain',
      kind: MediaKind.text,
      metadata: metadata,
      seedUsed: request.seed,
    );
  }
}
