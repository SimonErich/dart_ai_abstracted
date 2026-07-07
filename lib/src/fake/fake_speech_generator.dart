import 'dart:typed_data';

import '../contracts/speech_generator.dart';
import '../core/generation_metadata.dart';
import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/media_kind.dart';
import '../core/requests/speech_request.dart';

/// An in-memory [SpeechGenerator] for tests: no network, deterministic bytes.
class FakeSpeechGenerator implements SpeechGenerator {
  /// Creates a [FakeSpeechGenerator].
  ///
  /// [bytes] are returned verbatim (a tiny deterministic default otherwise),
  /// [mimeType] labels them, and [metadata] is echoed on the result.
  FakeSpeechGenerator({
    Uint8List? bytes,
    this.mimeType = 'audio/mpeg',
    this.metadata = const GenerationMetadata(model: 'fake-speech'),
  }) : bytes = bytes ?? Uint8List.fromList(const [0x49, 0x44, 0x33, 0x04]);

  /// The audio bytes every call returns.
  final Uint8List bytes;

  /// The MIME type reported on the result.
  final String mimeType;

  /// The metadata echoed on the result.
  final GenerationMetadata metadata;

  /// The most recent request passed to [generateSpeech], or null before any.
  SpeechRequest? lastRequest;

  @override
  Future<GenerationResult> generateSpeech(
    SpeechRequest request, {
    void Function(GenerationProgress)? onProgress,
  }) async {
    lastRequest = request;
    onProgress
      ?..call(const GenerationProgress(stage: GenerationStage.queued))
      ..call(const GenerationProgress(stage: GenerationStage.running))
      ..call(const GenerationProgress(stage: GenerationStage.done));
    return GenerationResult(
      bytes: bytes,
      mimeType: mimeType,
      kind: MediaKind.speech,
      metadata: metadata,
      seedUsed: request.seed,
    );
  }
}
