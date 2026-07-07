import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/text_request.dart';

/// The capability of turning a [TextRequest] into a text completion.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class TextGenerator {
  /// Generates text for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. The completion is
  /// returned as UTF-8 bytes in the result, with MIME type `text/plain`; read
  /// it conveniently via [GenerationResult.text].
  ///
  /// {@macro ai_abstracted.throws}
  Future<GenerationResult> generateText(
    TextRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
