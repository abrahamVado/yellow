import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

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

  // Future<List<PaymentMethod>> getPaymentMethods() ...
}
