import 'dart:typed_data';

import '../contracts/image_generator.dart';
import '../core/generation_metadata.dart';
import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/media_kind.dart';
import '../core/requests/image_request.dart';

/// An in-memory [ImageGenerator] for tests: no network, deterministic bytes.
class FakeImageGenerator implements ImageGenerator {
  /// Creates a [FakeImageGenerator].
  ///
  /// [bytes] are returned verbatim (a tiny deterministic default otherwise),
  /// [mimeType] labels them, and [metadata] is echoed on the result.
  FakeImageGenerator({
    Uint8List? bytes,
    this.mimeType = 'image/png',
    this.metadata = const GenerationMetadata(model: 'fake-image'),
  }) : bytes = bytes ?? Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47]);

  /// The image bytes every call returns.
  final Uint8List bytes;

  /// The MIME type reported on the result.
  final String mimeType;

  /// The metadata echoed on the result.
  final GenerationMetadata metadata;

  /// The most recent request passed to [generateImage], or null before any.
  ImageRequest? lastRequest;

  @override
  Future<GenerationResult> generateImage(
    ImageRequest request, {
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
      kind: MediaKind.image,
      metadata: metadata,
      seedUsed: request.seed,
    );
  }
}
