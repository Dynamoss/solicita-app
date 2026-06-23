import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/request_status.dart';
import '../models/request_model.dart';

/// A page fetched from the remote, with the total count reported by the server
/// (json-server's `X-Total-Count` header) so the repository can compute paging.
typedef RemotePage = ({List<RequestModel> items, int total});

abstract class RequestRemoteDataSource {
  Future<RemotePage> fetchRequests({
    required int page,
    required int limit,
    RequestStatus? status,
  });

  Future<RequestModel> fetchById(String id);

  Future<RequestModel> create(RequestModel model);

  Future<RequestModel> updateStatus({
    required String id,
    required RequestStatus status,
    required DateTime updatedAt,
  });
}

/// json-server-backed implementation.
///
/// Targets the stable json-server 0.17 query semantics (`_page`, `_limit`,
/// `_sort`/`_order`, `X-Total-Count`) — pinned in the mock's package.json.
class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  RequestRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _path = '/requests';

  @override
  Future<RemotePage> fetchRequests({
    required int page,
    required int limit,
    RequestStatus? status,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        _path,
        queryParameters: {
          '_page': page,
          '_limit': limit,
          '_sort': 'createdAt',
          '_order': 'desc',
          if (status != null) 'status': status.apiValue,
        },
      );
      _ensureSuccess(response.statusCode);

      final items = (response.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(RequestModel.fromJson)
          .toList();

      final totalHeader = response.headers.value('X-Total-Count');
      final total = int.tryParse(totalHeader ?? '') ?? items.length;

      return (items: items, total: total);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<RequestModel> fetchById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
      _ensureSuccess(response.statusCode);
      return RequestModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<RequestModel> create(RequestModel model) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path,
        data: model.toJson(),
      );
      _ensureSuccess(response.statusCode);
      return RequestModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<RequestModel> updateStatus({
    required String id,
    required RequestStatus status,
    required DateTime updatedAt,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_path/$id',
        data: {
          'status': status.apiValue,
          'updatedAt': updatedAt.toIso8601String(),
        },
      );
      _ensureSuccess(response.statusCode);
      return RequestModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  void _ensureSuccess(int? statusCode) {
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw ServerException(
        'Resposta inesperada do servidor.',
        statusCode: statusCode,
      );
    }
  }

  ServerException _mapDioError(DioException e) {
    final isTimeout = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
    return ServerException(
      isTimeout ? 'Servidor indisponível.' : (e.message ?? 'Erro de rede.'),
      statusCode: e.response?.statusCode,
    );
  }
}
