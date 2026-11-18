import 'package:flutter/material.dart';

import '../../services/weather_service.dart';

IconData weatherIcon(String condition) => switch (condition) {
      'Clear' => Icons.wb_sunny_rounded,
      'Clouds' => Icons.cloud_rounded,
      'Rain' || 'Drizzle' => Icons.grain_rounded,
      'Thunderstorm' => Icons.thunderstorm_rounded,
      'Mist' || 'Fog' || 'Haze' || 'Smoke' || 'Dust' => Icons.foggy,
      _ => Icons.wb_cloudy_rounded,
    };

String weatherErrorText(WeatherException? e, String Function(String) t) => switch (e?.code) {
      'no-key' => t('weatherNoKey'),
      'invalid-key' => t('weatherInvalidKey'),
      'network' => t('weatherOffline'),
      _ => t('weatherError'),
    };

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
