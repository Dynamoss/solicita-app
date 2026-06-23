part of 'request_detail_cubit.dart';

enum DetailStatus { loading, loaded, updating, error }

class RequestDetailState extends Equatable {
  const RequestDetailState({
    this.status = DetailStatus.loading,
    this.request,
    this.errorMessage,
  });

  final DetailStatus status;
  final ServiceRequest? request;
  final String? errorMessage;

  RequestDetailState copyWith({
    DetailStatus? status,
    ServiceRequest? request,
    String? errorMessage,
  }) {
    return RequestDetailState(
      status: status ?? this.status,
      request: request ?? this.request,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, request, errorMessage];
}
