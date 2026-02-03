class DiseaseCatalogModel {
  final String id;
  final String name;
  final String scientificName;
  final List<String> affectedPlants;
  final List<String> symptoms;
  final List<String> actions;
  final List<String> aliases;

  DiseaseCatalogModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.affectedPlants,
    required this.symptoms,
    required this.actions,
    required this.aliases,
  });

  factory DiseaseCatalogModel.fromJson(Map<String, dynamic> json) {
    return DiseaseCatalogModel(
      id: json['id'] as String,
      name: json['name'] as String,
      scientificName: json['scientificName'] as String,
      affectedPlants: (json['affectedPlants'] as List<dynamic>).map((e) => e as String).toList(),
      symptoms: (json['symptoms'] as List<dynamic>).map((e) => e as String).toList(),
      actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'affectedPlants': affectedPlants,
        'symptoms': symptoms,
        'actions': actions,
        'aliases': aliases,
      };
}
