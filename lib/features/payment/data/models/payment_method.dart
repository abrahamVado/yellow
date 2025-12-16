class PaymentMethod {
  final int id;
  final String type;
  final String provider;
  final String lastFour;
  final String brand;
  final String cardHolderName;
  final String token;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    required this.lastFour,
    required this.brand,
    required this.cardHolderName,
    required this.token,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'card',
      provider: json['provider'] as String? ?? 'mercadopago',
      lastFour: json['last_four'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      cardHolderName: json['card_holder_name'] as String? ?? '',
      token: json['token'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
