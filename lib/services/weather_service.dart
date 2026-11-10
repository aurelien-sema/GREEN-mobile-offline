import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String place;
  final double temperature; // °C
  final double feelsLike;
  final String description;
  final String condition; // ex. 'Rain', 'Clouds' (code OpenWeather, non traduit)
  final int humidity; // %
  final double windSpeed; // m/s
  final int pressure; // hPa
  final int cloudiness; // %
  final double rainLastHour; // mm
  final DateTime observedAt;

  const WeatherData({
    required this.place,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.cloudiness,
    required this.rainLastHour,
    required this.observedAt,
  });

  bool get isRaining => rainLastHour > 0 || condition == 'Rain' || condition == 'Drizzle' || condition == 'Thunderstorm';

  /// Pulvérisation déconseillée : pluie, ou vent > 4 m/s (≈ 15 km/h) qui
  /// emporte le produit hors de la parcelle.
  bool get sprayingDiscouraged => isRaining || windSpeed > 4;

  factory WeatherData.fromOpenWeather(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = (json['wind'] as Map<String, dynamic>?) ?? const {};
    final weather = (json['weather'] as List?) ?? const [];
    final first = weather.isEmpty ? const <String, dynamic>{} : weather.first as Map<String, dynamic>;
    final rain = (json['rain'] as Map<String, dynamic>?) ?? const {};
    return WeatherData(
      place: (json['name'] as String?) ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? (main['temp'] as num).toDouble(),
      description: (first['description'] as String?) ?? '',
      condition: (first['main'] as String?) ?? '',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      pressure: (main['pressure'] as num?)?.toInt() ?? 0,
      cloudiness: ((json['clouds'] as Map?)?['all'] as num?)?.toInt() ?? 0,
      rainLastHour: (rain['1h'] as num?)?.toDouble() ?? 0,
      observedAt: DateTime.fromMillisecondsSinceEpoch(((json['dt'] as num?)?.toInt() ?? 0) * 1000),
    );
  }
}

class WeatherException implements Exception {
  /// 'no-key' | 'network' | 'invalid-key' | 'not-found' | 'server'
  final String code;
  const WeatherException(this.code);
  @override
  String toString() => 'WeatherException($code)';
}

/// Météo actuelle (OpenWeatherMap). Aucune donnée fictive : sans clé ou sans
/// réseau, l'écran affiche l'erreur (la v1 affichait une météo inventée).
class WeatherService {
  static const _base = 'https://api.openweathermap.org/data/2.5/weather';
  static const _cacheValidity = Duration(minutes: 10);

  final http.Client _http;
  final String? _explicitKey;
  WeatherData? _last;
  String? _lastQuery;
  DateTime? _lastAt;

  WeatherService({http.Client? client, String? apiKey})
      : _http = client ?? http.Client(),
        _explicitKey = apiKey;

  String? get _key {
    if (_explicitKey != null) return _explicitKey;
    try {
      return dotenv.maybeGet('OPENWEATHER_API_KEY');
    } catch (_) {
      return null;
    }
  }

  Future<WeatherData> forCity(String city, {String lang = 'fr'}) =>
      _fetch('q=${Uri.encodeComponent(city)}', lang);

  Future<WeatherData> forCoordinates(double lat, double lon, {String lang = 'fr'}) =>
      _fetch('lat=${lat.toStringAsFixed(4)}&lon=${lon.toStringAsFixed(4)}', lang);

  Future<WeatherData> _fetch(String query, String lang) async {
    final key = _key;
    if (key == null || key.trim().isEmpty) throw const WeatherException('no-key');
    final apiLang = lang == 'pid' ? 'en' : lang;
    final cacheKey = '$query|$apiLang';
    if (_last != null && _lastQuery == cacheKey && DateTime.now().difference(_lastAt!) < _cacheValidity) {
      return _last!;
    }
    final http.Response res;
    try {
      res = await _http
          .get(Uri.parse('$_base?$query&units=metric&lang=$apiLang&appid=${key.trim()}'))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const WeatherException('network');
    } on TimeoutException {
      throw const WeatherException('network');
    } on http.ClientException {
      throw const WeatherException('network');
    }
    if (res.statusCode == 401) throw const WeatherException('invalid-key');
    if (res.statusCode == 404) throw const WeatherException('not-found');
    if (res.statusCode != 200) throw const WeatherException('server');
    final data = WeatherData.fromOpenWeather(jsonDecode(res.body) as Map<String, dynamic>);
    _last = data;
    _lastQuery = cacheKey;
    _lastAt = DateTime.now();
    return data;
  }
}

final weatherService = WeatherService();
