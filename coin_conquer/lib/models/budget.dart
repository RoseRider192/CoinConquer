class Budget {
  final int? id;
  final int categoryId;
  final double amount;
  final String month; // YYYY-MM

  const Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
    );
  }

  Budget copyWith({
    int? id,
    int? categoryId,
    double? amount,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
    );
  }
}
