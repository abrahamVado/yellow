import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../payment/presentation/providers/payment_provider.dart';
import '../../../payment/data/models/payment_method.dart';

class AccountStatementScreen extends ConsumerWidget {
  const AccountStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeConfigProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    // Calculate Balance
    final double totalBalance = transactionsAsync.maybeWhen(
      data: (txs) => txs.fold(0.0, (sum, tx) {
         if (tx.flow == 'inflow') return sum + tx.amount;
         return sum - tx.amount;
      }),
      orElse: () => 0.0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Billetera', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Wallet Card
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeConfig.primaryColor, Colors.orange.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeConfig.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                   Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(FontAwesomeIcons.wallet, size: 150, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Verificado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // const Icon(FontAwesomeIcons.ccVisa, color: Colors.white, size: 30), // Removed Visa Icon to be generic
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo', // Simplified label
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                             Text(
                                '\$ ${totalBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.0,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Quick Actions (Only Tarjetas)
            Center( // Centered since it's only one
              child: _buildActionButton(
                  context, 
                  icon: FontAwesomeIcons.solidCreditCard, 
                  label: 'Administrar Tarjetas', 
                  color: Colors.purple
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Recent Transactions
            const Text(
              'Movimientos Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            transactionsAsync.when(
              data: (transactions) {
                 if (transactions.isEmpty) return const Text("No hay movimientos recientes");
                 
                 // Sort by date desc if not already? Usually backend does it.
                 
                 return ListView.separated(
                  itemCount: transactions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isNegative = tx.flow == 'outflow'; 
                    final amount = tx.amount;
                    
                    IconData icon = FontAwesomeIcons.moneyBill;
                    if (tx.type == 'trip_payment' || tx.type == 'payment') icon = FontAwesomeIcons.taxi;
                    if (tx.type == 'topup') icon = FontAwesomeIcons.wallet;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isNegative ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isNegative ? Colors.red : Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _translateDescription(tx.description),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${tx.createdAt.day}/${tx.createdAt.month} ${tx.createdAt.hour}:${tx.createdAt.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${isNegative ? '-' : '+'} \$${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: isNegative ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Error: $e"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          width: 70, // Slightly bigger since it's alone
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 28),
            onPressed: () {
               // Only supports Cards now
               context.push('/dashboard/payment-methods');
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  String _translateDescription(String desc) {
    // Simple mapping for translation
    final lower = desc.toLowerCase();
    if (lower.contains('trip payment') || lower.contains('trip')) return 'Pago de Viaje';
    if (lower.contains('top up') || lower.contains('topup')) return 'Recarga';
    if (lower.contains('refund')) return 'Reembolso';
    if (lower.contains('commission')) return 'Comisión';
    if (lower.contains('payment')) return 'Pago';
    return desc;
  }
}
