class Transaction {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final String? customName;
  final String? note;
  final String date; // YYYY-MM-DD
  final int isRecurring;
  final String? recurringInterval;
  final String? createdAt;

  const Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.customName,
    this.note,
    required this.date,
    this.isRecurring = 0,
    this.recurringInterval,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'custom_name': customName,
      'note': note,
      'date': date,
      'is_recurring': isRecurring,
      'recurring_interval': recurringInterval,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      customName: map['custom_name'] as String?,
      note: map['note'] as String?,
      date: map['date'] as String,
      isRecurring: map['is_recurring'] as int? ?? 0,
      recurringInterval: map['recurring_interval'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Transaction copyWith({
    int? id,
    double? amount,
    String? type,
    int? categoryId,
    String? customName,
    String? note,
    String? date,
    int? isRecurring,
    String? recurringInterval,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      customName: customName ?? this.customName,
      note: note ?? this.note,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      createdAt: createdAt,
    );
  }
}
