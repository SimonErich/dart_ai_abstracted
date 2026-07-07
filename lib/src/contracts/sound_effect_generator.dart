import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/sound_effect_request.dart';

/// The capability of turning a [SoundEffectRequest] into sound-effect bytes.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class SoundEffectGenerator {
  /// Generates a sound effect for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. Completes with a
  /// [GenerationResult] whose bytes are the encoded audio.
  ///
  /// {@macro ai_abstracted.throws}
  Future<GenerationResult> generateSoundEffect(
    SoundEffectRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
