import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/music_request.dart';

/// The capability of turning a [MusicRequest] into music bytes.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class MusicGenerator {
  /// Generates a music track for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. Completes with a
  /// [GenerationResult] whose bytes are the encoded audio.
  ///
  /// {@macro ai_abstracted.throws}
  /// {@macro ai_abstracted.throws_timeout}
  Future<GenerationResult> generateMusic(
    MusicRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
