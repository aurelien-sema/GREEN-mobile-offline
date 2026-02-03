import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String? _safeEnv(String key) {
  try {
    return dotenv.env[key];
  } catch (_) {
    return null;
  }
}

class WeatherData {
  final double temperature; // Celsius
  final String description;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });
}

class WeatherService {
  // Uses OpenWeatherMap API if apiKey is provided
  final String? apiKey;

  WeatherService({this.apiKey});

  Future<WeatherData> fetchWeatherForCity(String city, {String lang = 'fr'}) async {
    if (apiKey == null || apiKey!.isEmpty) {
      // Return mock data
      return WeatherData(
        temperature: 18.5,
        description: lang == 'en' ? 'Sunny' : 'Ensoleillé',
        humidity: 55,
        windSpeed: 3.2,
      );
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city)}&units=metric&appid=$apiKey&lang=$lang',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }
    final Map<String, dynamic> json = jsonDecode(resp.body);
    final main = json['main'];
    final wind = json['wind'];
    final weatherList = json['weather'] as List<dynamic>;
    final desc = weatherList.isNotEmpty
        ? weatherList[0]['description'] as String
        : '';
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      description: desc,
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
    );
  }

  Future<WeatherData> fetchWeatherForCoordinates(double lat, double lon, {String lang = 'fr'}) async {
    if (apiKey == null || apiKey!.isEmpty) {
      // Mock data for dev
      return WeatherData(
        temperature: 22.5,
        description: lang == 'en' ? 'Partly cloudy' : 'Partiellement nuageux',
        humidity: 60,
        windSpeed: 4.5,
      );
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey&lang=$lang',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }
    final Map<String, dynamic> json = jsonDecode(resp.body);
    final main = json['main'];
    final wind = json['wind'];
    final weatherList = json['weather'] as List<dynamic>;
    final desc = weatherList.isNotEmpty
        ? weatherList[0]['description'] as String
        : '';
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      description: desc,
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
    );
  }
}

final weatherService = WeatherService(apiKey: _safeEnv('OPENWEATHER_API_KEY'));
