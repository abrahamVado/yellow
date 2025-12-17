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
    
    // Mock Data for "Wow" Factor
    final transactions = [
      {'title': 'Viaje Finalizado', 'date': 'Hoy, 10:23 AM', 'amount': '- \$45.00', 'isNegative': true, 'icon': FontAwesomeIcons.taxi},
      {'title': 'Recarga de Saldo', 'date': 'Ayer, 04:15 PM', 'amount': '+ \$200.00', 'isNegative': false, 'icon': FontAwesomeIcons.wallet},
      {'title': 'Viaje Finalizado', 'date': '10 Dic, 08:30 PM', 'amount': '- \$62.50', 'isNegative': true, 'icon': FontAwesomeIcons.taxi},
      {'title': 'Bono de Bienvenida', 'date': '08 Dic, 09:00 AM', 'amount': '+ \$50.00', 'isNegative': false, 'icon': FontAwesomeIcons.gift},
    ];

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
                            const Icon(FontAwesomeIcons.ccVisa, color: Colors.white, size: 30),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Disponible',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '\$ 142.50',
                              style: TextStyle(
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
            
            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(context, icon: FontAwesomeIcons.plus, label: 'Recargar', color: Colors.blue),
                _buildActionButton(context, icon: FontAwesomeIcons.solidCreditCard, label: 'Tarjeta', color: Colors.purple),
                _buildActionButton(context, icon: FontAwesomeIcons.receipt, label: 'Facturas', color: Colors.orange),
              ],
            ),
            
            const SizedBox(height: 40),
            
            const SizedBox(height: 30),
            
            // Recent Transactions
            const Text(
              'Movimientos Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ref.watch(transactionsProvider).when(
              data: (transactions) {
                 if (transactions.isEmpty) return const Text("No hay movimientos recientes");
                 return ListView.separated(
                  itemCount: transactions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isNegative = tx.flow == 'outflow'; // Or logic based on 'type'
                    final amount = tx.amount; // Should format currency
                    
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
                                  tx.description.isNotEmpty ? tx.description : 'Movimiento',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${tx.createdAt.day}/${tx.createdAt.month} ${tx.createdAt.hour}:${tx.createdAt.minute}",
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {
               if (label == 'Tarjeta') {
                 context.push('/dashboard/payment-methods');
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente...')));
               }
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
}
