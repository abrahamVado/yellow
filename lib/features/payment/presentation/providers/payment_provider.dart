import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/payment_method.dart';

final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentMethods();
});
