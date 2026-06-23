import '../../../core/utils/typedefs.dart';
import 'entities/ai_suggestion.dart';

/// Domain port for the "describe → category/summary" feature. The presentation
/// layer depends on this abstraction; the concrete LLM/heuristic lives in data.
abstract class AiService {
  ResultFuture<AiSuggestion> suggest(String description);
}
