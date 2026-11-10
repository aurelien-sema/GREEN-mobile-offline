import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/weather_service.dart';

void main() {
  Map<String, dynamic> owm({double wind = 2, String main = 'Clouds', Map<String, dynamic>? rain}) => {
        'name': 'Douala',
        'dt': 1794060000,
        'main': {'temp': 29.4, 'feels_like': 33.1, 'humidity': 82, 'pressure': 1009},
        'wind': {'speed': wind},
        'clouds': {'all': 75},
        'weather': [
          {'main': main, 'description': 'nuageux'},
        ],
        'rain': ?rain,
      };

  test('lecture de la réponse OpenWeather (aucune valeur inventée)', () {
    final d = WeatherData.fromOpenWeather(owm());
    expect(d.place, 'Douala');
    expect(d.pressure, 1009);
    expect(d.feelsLike, 33.1);
    expect(d.sprayingDiscouraged, isFalse);
  });

  test('pulvérisation déconseillée par vent fort ou pluie', () {
    expect(WeatherData.fromOpenWeather(owm(wind: 6)).sprayingDiscouraged, isTrue);
    expect(WeatherData.fromOpenWeather(owm(main: 'Rain', rain: {'1h': 0.4})).sprayingDiscouraged, isTrue);
  });

  test('sans clé, erreur explicite au lieu d\'une météo fictive', () async {
    final s = WeatherService(apiKey: '');
    await expectLater(s.forCity('Douala'), throwsA(isA<WeatherException>().having((e) => e.code, 'code', 'no-key')));
  });
}
