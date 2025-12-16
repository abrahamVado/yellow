import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/payment_method.dart';

// Simple FutureProvider to fetch cards
final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentMethods();
});

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Métodos de Pago', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          methodsAsync.when(
            data: (methods) {
              if (methods.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.solidCreditCard, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text("No tienes tarjetas guardadas", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: methods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final method = methods[index];
                  // Determine icon based on brand (simple heuristic)
                  IconData iconData = FontAwesomeIcons.solidCreditCard;
                  if (method.brand.toLowerCase().contains('visa')) iconData = FontAwesomeIcons.ccVisa;
                  if (method.brand.toLowerCase().contains('master')) iconData = FontAwesomeIcons.ccMastercard;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                      border: method.isDefault ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(iconData, size: 30, color: Colors.blueGrey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.brand.toUpperCase(), 
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                              Text("•••• ${method.lastFour}", style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (method.isDefault)
                          const Chip(label: Text("Default", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.blue)
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          
          // Floating Action Button to Add Card
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () async {
                 await context.push('/dashboard/add-card');
                 // Refresh list on return
                 ref.refresh(paymentMethodsProvider);
              },
              backgroundColor: Colors.black,
              icon: const Icon(FontAwesomeIcons.plus, color: Colors.white),
              label: const Text("Agregar Tarjeta", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
