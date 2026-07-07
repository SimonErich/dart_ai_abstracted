import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/speech_request.dart';

/// The capability of turning a [SpeechRequest] into spoken audio bytes.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class SpeechGenerator {
  /// Synthesizes speech for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. Completes with a
  /// [GenerationResult] whose bytes are the encoded audio.
  ///
  /// {@macro ai_abstracted.throws}
  Future<GenerationResult> generateSpeech(
    SpeechRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
