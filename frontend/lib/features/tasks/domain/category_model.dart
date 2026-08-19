class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color = '#2D6A4F',
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      name: json['name'] as String,
      color: (json['color'] ?? '#2D6A4F') as String,
      icon: json['icon'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}
