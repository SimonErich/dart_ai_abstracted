import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/image_request.dart';

/// The capability of turning an [ImageRequest] into image bytes.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class ImageGenerator {
  /// Generates an image for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. Completes with a
  /// [GenerationResult] whose bytes are the encoded image.
  ///
  /// {@macro ai_abstracted.throws}
  /// {@macro ai_abstracted.throws_timeout}
  Future<GenerationResult> generateImage(
    ImageRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
