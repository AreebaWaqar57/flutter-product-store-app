import 'package:dio/dio.dart';

import '../models/product_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ProductApiService {
  ProductApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://dummyjson.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<List<Product>> getProducts({int limit = 100}) async {
    try {
      final res = await _dio.get(
        '/products',
        queryParameters: {'limit': limit},
      );
      final list = (res.data['products'] as List).cast<Map<String, dynamic>>();
      return list.map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw ApiException('unexpected server error');
    }
  }

  Future<Product> getProduct(int id) async {
    try {
      final res = await _dio.get('/products/$id');
      return Product.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw ApiException('Unexpected response from server.');
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      await _dio.post('/products/add', data: product.toJson());
      return product.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        isLocal: true,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Product> updateProduct(Product product) async {
    if (product.isLocal) return product;
    try {
      await _dio.patch('/products/${product.id}', data: product.toJson());
      return product;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteProduct(Product product) async {
    if (product.isLocal) return;
    try {
      await _dio.delete('/products/${product.id}');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return ApiException('No internet connection.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        final msg = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Server error';
        return ApiException('$msg (code $code)', statusCode: code);
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');
      default:
        return ApiException('Something went wrong. Please try again.');
    }
  }
}
