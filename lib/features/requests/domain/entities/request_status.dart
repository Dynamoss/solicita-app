/// Lifecycle states of a service request.
///
/// [apiValue] is the wire format (snake_case) and [label] the pt-BR UI text,
/// keeping serialization and presentation concerns out of the rest of the code.
enum RequestStatus {
  open('open', 'Aberto'),
  inProgress('in_progress', 'Em andamento'),
  resolved('resolved', 'Resolvido'),
  cancelled('cancelled', 'Cancelado');

  const RequestStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RequestStatus fromApi(String? value) => RequestStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => RequestStatus.open,
      );
}

/// Business priority of a request.
enum RequestPriority {
  low('low', 'Baixa'),
  medium('medium', 'Média'),
  high('high', 'Alta');

  const RequestPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RequestPriority fromApi(String? value) =>
      RequestPriority.values.firstWhere(
        (p) => p.apiValue == value,
        orElse: () => RequestPriority.medium,
      );
}
