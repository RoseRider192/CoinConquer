class RecurringRule {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final String? note;
  final String interval; // 'monthly', 'quarterly', 'yearly'
  final String nextDate; // YYYY-MM-DD
  final int reminderEnabled; // 0=auto, 1=remind+confirm
  final int isActive;

  const RecurringRule({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.interval,
    required this.nextDate,
    this.reminderEnabled = 0,
    this.isActive = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'note': note,
      'interval': interval,
      'next_date': nextDate,
      'reminder_enabled': reminderEnabled,
      'is_active': isActive,
    };
  }

  factory RecurringRule.fromMap(Map<String, dynamic> map) {
    return RecurringRule(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      note: map['note'] as String?,
      interval: map['interval'] as String,
      nextDate: map['next_date'] as String,
      reminderEnabled: map['reminder_enabled'] as int? ?? 0,
      isActive: map['is_active'] as int? ?? 1,
    );
  }

  RecurringRule copyWith({
    int? id,
    double? amount,
    String? type,
    int? categoryId,
    String? note,
    String? interval,
    String? nextDate,
    int? reminderEnabled,
    int? isActive,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      interval: interval ?? this.interval,
      nextDate: nextDate ?? this.nextDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isActive: isActive ?? this.isActive,
    );
  }
}
