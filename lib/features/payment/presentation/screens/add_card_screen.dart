import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:yellow/core/network/dio_client.dart';
import 'package:yellow/features/payment/data/repositories/payment_repository.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController(); // MM/YY
  final _cvvController = TextEditingController();
  
  bool _isLoading = false;

  // TODO: Move to Env or fetch from API
  String? _mpPublicKey;
  
  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
        final key = await ref.read(paymentRepositoryProvider).getPublicKey();
        if (mounted) {
            setState(() {
                _mpPublicKey = key;
            });
        }
    } catch(e) {
        print("Error fetching settings: $e");
    }
  } 

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Tokenize with Mercado Pago
      final token = await _tokenizeCard();
      
      // 2. Send to Backend
      await ref.read(paymentRepositoryProvider).saveCard(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta guardada exitosamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'No se pudo guardar la tarjeta. Intente nuevamente.';
        
        if (e.toString().contains('500') || e.toString().contains('internal server error')) {
           errorMessage = 'Error con la tarjeta.';
        } else if (e.toString().contains('Mercado Pago Error')) {
           errorMessage = e.toString().replaceAll('Exception: Mercado Pago Error:', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _tokenizeCard() async {
    final dio = Dio();
    
    // Parse Expiry
    final expiryParts = _expiryDateController.text.split('/');
    final month = int.parse(expiryParts[0]);
    final year = 2000 + int.parse(expiryParts[1]); // Assuming 20xx

    final data = {
      "card_number": _cardNumberController.text.replaceAll(' ', ''),
      "security_code": _cvvController.text,
      "expiration_month": month,
      "expiration_year": year,
      "cardholder": {
        "name": _cardHolderController.text,
      }
    };

    if (_mpPublicKey == null) {
      throw Exception("Configuración de pagos no cargada. Intente nuevamente.");
    }

    try {
      final response = await dio.post(
        'https://api.mercadopago.com/v1/card_tokens?public_key=$_mpPublicKey',
        data: data,
      );
      
      return response.data['id'];
    } on DioException catch (e) {
      throw Exception('Mercado Pago Error: ${e.response?.data['message'] ?? e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Tarjeta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Number
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  prefixIcon: Icon(FontAwesomeIcons.solidCreditCard),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.replaceAll(' ', '').length < 13) return 'Inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Card Holder
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Titular',
                  prefixIcon: Icon(FontAwesomeIcons.user),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Expiry
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expira (MM/YY)',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        hintText: 'MM/YY'
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (v) {
                        if (v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) return 'Use MM/YY';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (v) => (v!.length < 3) ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Tarjeta'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
