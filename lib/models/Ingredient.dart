class Ingredient {
  final int id;
  final String name;
  final String image;
  final String category;

  Ingredient({required this.id, required this.name, required this.image, required this.category});

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      image: 'assets/ingredients/${map['filename'] ?? 'default_ingredient.png'}',
      category: map['category_name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}