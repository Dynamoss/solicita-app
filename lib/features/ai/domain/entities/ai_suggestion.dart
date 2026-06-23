import 'package:equatable/equatable.dart';

/// AI-generated metadata for a request description.
class AiSuggestion extends Equatable {
  const AiSuggestion({
    required this.category,
    required this.summary,
    this.fromFallback = false,
  });

  final String category;
  final String summary;

  /// `true` when produced by the on-device heuristic instead of the LLM
  /// (no API key configured, or the remote call failed). Surfaced in the UI so
  /// the behavior is transparent.
  final bool fromFallback;

  @override
  List<Object?> get props => [category, summary, fromFallback];
}
