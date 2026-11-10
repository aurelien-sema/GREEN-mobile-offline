import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/weather_service.dart';

enum LocationIssue { none, serviceDisabled, denied, deniedForever }

/// Météo partagée par l'Accueil et l'écran Météo (une seule requête, mise en
/// cache 10 minutes par WeatherService).
class WeatherProvider with ChangeNotifier {
  static const defaultCity = 'Douala';
  static const _useLocationKey = 'weather_use_location';

  final WeatherService _service;
  WeatherProvider({WeatherService? service}) : _service = service ?? weatherService;

  WeatherData? data;
  WeatherException? error;
  bool loading = false;
  bool usingLocation = false;
  LocationIssue locationIssue = LocationIssue.none;
  double? lat;
  double? lon;

  Future<void> load({required String lang, bool requestLocation = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final wantsLocation = requestLocation || (prefs.getBool(_useLocationKey) ?? false);
    try {
      if (wantsLocation && await _locate(request: requestLocation)) {
        await prefs.setBool(_useLocationKey, true);
        data = await _service.forCoordinates(lat!, lon!, lang: lang);
        usingLocation = true;
      } else {
        data = await _service.forCity(defaultCity, lang: lang);
        usingLocation = false;
      }
    } on WeatherException catch (e) {
      error = e;
    } catch (_) {
      error = const WeatherException('server');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> _locate({required bool request}) async {
    locationIssue = LocationIssue.none;
    if (!await Geolocator.isLocationServiceEnabled()) {
      locationIssue = LocationIssue.serviceDisabled;
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied && request) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      locationIssue = LocationIssue.deniedForever;
      return false;
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) {
      locationIssue = LocationIssue.denied;
      return false;
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      final pos = last ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low, // la météo n'a pas besoin du GPS précis
              timeLimit: Duration(seconds: 12),
            ),
          );
      lat = pos.latitude;
      lon = pos.longitude;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    if (locationIssue == LocationIssue.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }
}
