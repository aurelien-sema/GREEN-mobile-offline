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

  // Casts défensifs (valeurs de repli plutôt que TypeError) : un futur ajout
  // ou une traduction de diseases.json avec un champ manquant/mal typé ne
  // doit pas faire échouer le chargement de tout le catalogue.
  factory DiseaseCatalogModel.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) =>
        (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return DiseaseCatalogModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      affectedPlants: stringList(json['affectedPlants']),
      symptoms: stringList(json['symptoms']),
      actions: stringList(json['actions']),
      aliases: stringList(json['aliases']),
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
