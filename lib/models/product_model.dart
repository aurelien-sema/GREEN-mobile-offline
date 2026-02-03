class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String shortDescription;
  final List<String> characteristics;
  final String supplierName;
  final String location;
  final double priceMin;
  final double priceMax;
  final String imageUrl;
  final List<String> tags;
  final double rating;
  final int reviewCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.shortDescription,
    required this.characteristics,
    required this.supplierName,
    required this.location,
    required this.priceMin,
    required this.priceMax,
    required this.imageUrl,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  // Propriété de commodité pour afficher le prix (moyenne ou minimum)
  double get price => (priceMin + priceMax) / 2;
  String get priceRange => '${priceMin.toStringAsFixed(0)} - ${priceMax.toStringAsFixed(0)} FCFA';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String,
      shortDescription: json['shortDescription'] as String,
      characteristics: (json['characteristics'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      supplierName: json['supplierName'] as String,
      location: json['location'] as String,
      priceMin: (json['priceMin'] as num).toDouble(),
      priceMax: (json['priceMax'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'shortDescription': shortDescription,
        'characteristics': characteristics,
        'supplierName': supplierName,
        'location': location,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'imageUrl': imageUrl,
        'tags': tags,
        'rating': rating,
        'reviewCount': reviewCount,
      };
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
      };
}
