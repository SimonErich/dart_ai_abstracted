/// The providers this package can talk to.
///
/// Each value carries a stable lower-case wire name in [id], used to label
/// errors and to key credentials.
enum ProviderId {
  /// Google Gemini (text and image; "Nano Banana" image model).
  gemini('gemini'),

  /// Google Veo (video), accessed through the Gemini API.
  veo('veo'),

  /// OpenAI (image via gpt-image-1).
  openai('openai'),

  /// Black Forest Labs FLUX (image).
  flux('flux'),

  /// ElevenLabs (speech and sound effects).
  elevenLabs('elevenlabs'),

  /// Suno (music).
  suno('suno'),

  /// Anthropic Claude (text).
  claude('claude'),

  /// Mistral (text).
  mistral('mistral'),

  /// Ollama (local text; keyless).
  ollama('ollama');

  const ProviderId(this.id);

  /// A stable lower-case wire name for this provider.
  final String id;
}
