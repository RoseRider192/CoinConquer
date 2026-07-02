class Category {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String color;
  final int isDefault; // 0=custom, 1=preset
  final String? createdAt;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isDefault: map['is_default'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? isDefault,
    String? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
