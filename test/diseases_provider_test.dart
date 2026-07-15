import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/providers/diseases_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiseasesProvider offline matching', () {
    test('matches french plant and disease names against the local catalog', () async {
      final provider = DiseasesProvider();
      await provider.load();

      final disease = provider.findByPlantAndDisease('Maïs', 'Virus de la strie du maïs');

      expect(disease, isNotNull);
      expect(disease!.name, 'Virus de la strie du maïs');
      expect(disease.symptoms, isNotEmpty);
      expect(disease.actions, isNotEmpty);
    });

    test('matches healthy results using the french disease name', () async {
      final provider = DiseasesProvider();
      await provider.load();

      final disease = provider.findByPlantAndDisease('Tomate', 'Saine');

      expect(disease, isNotNull);
      expect(disease!.name, 'Saine');
    });
  });
}
