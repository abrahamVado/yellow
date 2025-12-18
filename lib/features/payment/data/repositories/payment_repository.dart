import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';

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

  Future<List<PaymentTransaction>> getTransactions() async {
    try {
      final response = await _dio.get('/finance/transactions');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => PaymentTransaction.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching transactions: $e");
      return [];
    }
  }
  Future<String> tokenizeSavedCard(String cardId, String cvv, String publicKey) async {
    final dio = Dio(); 
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

  Future<String> createCardToken({
    required String cardNumber,
    required String cardholderName,
    required String expirationMonth,
    required String expirationYear,
    required String securityCode,
    required String identificationType,
    required String identificationNumber,
    required String publicKey,
  }) async {
    final dio = Dio();
    try {
      final response = await dio.post(
        'https://api.mercadopago.com/v1/card_tokens?public_key=$publicKey',
        data: {
          "card_number": cardNumber,
          "cardholder": {
            "name": cardholderName,
            "identification": {
              "type": identificationType,
              "number": identificationNumber
            }
          },
          "expiration_month": expirationMonth,
          "expiration_year": expirationYear,
          "security_code": securityCode
        },
      );
      return response.data['id'];
    } on DioException catch (e) {
       print("Create Token Error: ${e.response?.data}");
       throw Exception('MP Token Error: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<String?> getPublicKey() async {
      try {
          final response = await _dio.get('/api/settings/1'); 
          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
               final key = response.data['data']['mp_public_key'];
               // Prefer API key, but if empty/null, might fall back to hardcoded in caller.
               // However, for verify we use the one passed to createCardToken
               return key?.toString().isNotEmpty == true ? key : 'APP_USR-92c554d9-615c-436d-b342-fbbdf734e306';
          }
          return 'APP_USR-92c554d9-615c-436d-b342-fbbdf734e306';
      } catch(e) {
          print("Error fetching mp key: $e");
          return 'APP_USR-92c554d9-615c-436d-b342-fbbdf734e306';
      }
  }

  Future<void> processPayment({
    required double amount, 
    required String token, 
    required int installments, 
    required String paymentMethodId,
    required String payerEmail,
    String? accessToken, // Optional passed token or hardcoded fallback
  }) async {
    final dio = Dio();
    
    // Access Token from Screenshot (12/15)
    final effectiveToken = accessToken ?? "APP_USR-690168984070480-121419-6cf75442044e7c6bc5351c858f6c8c40-45251974"; 

    try {
      print("Processing Payment for \$$amount with token $token");
      
      final response = await dio.post(
        'https://api.mercadopago.com/v1/payments',
        options: Options(
          headers: {
            'Authorization': 'Bearer $effectiveToken',
            'Content-Type': 'application/json',
            'X-Idempotency-Key': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
        data: {
          "transaction_amount": amount,
          "token": token,
          "description": "Viaje Taxi Yellow",
          "installments": installments,
          "payment_method_id": paymentMethodId,
          "payer": {
            "email": payerEmail
          }
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Payment Success: ${response.data['status']}");
        if (response.data['status'] == 'approved') {
          return;
        } else {
           throw Exception('Payment status: ${response.data['status']}');
        }
      } else {
        throw Exception('Payment Failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("Payment API Error: ${e.response?.data}");
      throw Exception('Payment Error: ${e.response?.data['message'] ?? e.message}');
    }
  }
}
