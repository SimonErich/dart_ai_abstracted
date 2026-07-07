import '../core/generation_progress.dart';
import '../core/generation_result.dart';
import '../core/requests/video_request.dart';

/// The capability of turning a [VideoRequest] into video bytes.
/// {@category Capabilities}
// ignore: one_member_abstracts, the contract is a type so it can be injected and faked
abstract interface class VideoGenerator {
  /// Generates a video for [request].
  ///
  /// Calls [onProgress] with lifecycle updates when provided. The result's
  /// [GenerationResult.metadata] reports whether the clip carries an audio
  /// track (`hasAudio`, set for providers such as Veo 3).
  ///
  /// {@macro ai_abstracted.throws}
  /// {@macro ai_abstracted.throws_timeout}
  Future<GenerationResult> generateVideo(
    VideoRequest request, {
    void Function(GenerationProgress)? onProgress,
  });
}
