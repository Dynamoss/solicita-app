import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../ai_service.dart';
import '../entities/ai_suggestion.dart';

class SuggestRequestMeta extends UseCase<AiSuggestion, String> {
  const SuggestRequestMeta(this._service);

  final AiService _service;

  @override
  ResultFuture<AiSuggestion> call(String description) =>
      _service.suggest(description);
}
