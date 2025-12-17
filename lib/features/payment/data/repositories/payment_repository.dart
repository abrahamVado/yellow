import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_method.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(dioProvider));
});

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<void> saveCard(String token) async {
    try {
      await _dio.post('/finance/payment-methods', data: {
        'type': 'card',
        'provider': 'mercadopago', // or 'stripe'
        'token': token,
      });
    } catch (e) {
      throw Exception('Failed to save card: $e');
    }
  }

  Future<void> deletePaymentMethod(int id) async {
    try {
      await _dio.delete('/finance/payment-methods/$id');
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/finance/payment-methods');
      if (response.statusCode == 200 && response.data != null) {
        // Backend returns raw list based on handler.go: c.JSON(http.StatusOK, methods)
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => PaymentMethod.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // Return empty list on error for now or rethrow
      return [];
    }
  }
  Future<String> tokenizeSavedCard(String cardId, String cvv, String publicKey) async {
    final dio = Dio(); // New Dio instance to avoid interceptors (or use basic one)
    try {
      final response = await dio.post(
        'https://api.mercadopago.com/v1/card_tokens?public_key=$publicKey',
        data: {
          "card_id": cardId,
          "security_code": cvv,
        },
      );
      return response.data['id'];
    } on DioException catch (e) {
      throw Exception('Mercado Pago Error: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<String?> getPublicKey() async {
      try {
          final response = await _dio.get('/api/settings/1'); 
          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
               final key = response.data['data']['mp_public_key'];
               print("DEBUG: Using MP Public Key: $key");
               return key;
          }
          return null;
      } catch(e) {
          print("Error fetching mp key: $e");
          return null;
      }
  }
}
