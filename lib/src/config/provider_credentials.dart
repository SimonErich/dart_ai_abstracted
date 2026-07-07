import 'package:meta/meta.dart';

/// Credentials and connection settings for a single provider.
/// {@category Credentials}
@immutable
final class ProviderCredentials {
  /// Creates [ProviderCredentials] authenticating with [apiKey].
  const ProviderCredentials({
    required this.apiKey,
    this.baseUrl,
    this.organization,
    this.project,
    this.extra = const {},
  });

  /// Creates credentials for a keyless provider such as Ollama.
  ///
  /// [apiKey] is left empty. Use this instead of passing an empty string, so a
  /// missing key on a provider that needs one stays a loud error.
  const ProviderCredentials.keyless({
    this.baseUrl,
    this.organization,
    this.project,
    this.extra = const {},
  }) : apiKey = '';

  /// The provider API key. Empty for keyless providers (such as Ollama); use
  /// [ProviderCredentials.keyless] for that case.
  final String apiKey;

  /// An optional base URL override (for self-hosted or proxied endpoints).
  final Uri? baseUrl;

  /// An optional organization id, for providers that scope by organization.
  final String? organization;

  /// An optional project id, for providers that scope by project.
  final String? project;

  /// Any extra provider-specific settings, passed through verbatim.
  final Map<String, String> extra;
}
