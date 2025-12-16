class PaymentMethod {
  final int id;
  final String type;
  final String provider;
  final String lastFour;
  final String brand;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    required this.lastFour,
    required this.brand,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'card',
      provider: json['provider'] as String? ?? 'mercadopago',
      lastFour: json['last_four'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
