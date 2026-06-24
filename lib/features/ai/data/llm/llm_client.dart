/// Transport abstraction over a chat-completion LLM.
///
/// This is the seam that decouples the AI feature from any single vendor: each
/// provider (Anthropic, OpenAI, …) implements [complete] with its own wire
/// format — headers, request body and response parsing — while everything above
/// (prompt building, JSON extraction, fallback) stays provider-agnostic in
/// `RemoteAiService`.
abstract class LlmClient {
  /// Sends [prompt] as a single user turn and returns the model's raw text
  /// completion. Throws [LlmException] (or a transport error) on failure — the
  /// caller is expected to degrade gracefully.
  Future<String> complete(String prompt);
}

/// Raised when a provider responds but the payload has no usable text content.
class LlmException implements Exception {
  const LlmException(this.message);

  final String message;

  @override
  String toString() => 'LlmException: $message';
}
