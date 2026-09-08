import 'package:equatable/equatable.dart';

/// Current weather ambience passed to the globe renderer.
class MapWeatherAmbience extends Equatable {
  const MapWeatherAmbience({
    this.temperature = 20,
    this.humidity = 0.5,
    this.cloudCover = 0.2,
    this.windSpeed = 2,
    this.windDirection = 180,
    this.condition = 'clear',
    this.isStorm = false,
    this.isRain = false,
    this.isSnow = false,
  });

  /// Backend's `/weather/current/` passes through the raw OpenWeather
  /// `data/2.5/weather` payload (nested `main`/`wind`/`clouds`/`weather[]`),
  /// not a flat normalized shape. This parses that raw shape, while still
  /// accepting the flat field names as a fallback for other callers/tests.
  factory MapWeatherAmbience.fromJson(Map<String, dynamic> json) {
    final mainBlock = json['main'] is Map ? json['main'] as Map : null;
    final windBlock = json['wind'] is Map ? json['wind'] as Map : null;
    final cloudsBlock = json['clouds'] is Map ? json['clouds'] as Map : null;
    final weatherList = json['weather'] is List ? json['weather'] as List : null;
    final weatherEntry = (weatherList != null && weatherList.isNotEmpty)
        ? weatherList.first
        : null;
    final weatherMain =
        weatherEntry is Map ? weatherEntry['main'] as String? : null;

    final condition = json['condition'] as String? ??
        weatherMain ??
        (json['main'] is String ? json['main'] as String : null) ??
        'clear';
    final conditionLower = condition.toLowerCase();

    final humidityRaw =
        (mainBlock?['humidity'] as num?) ?? (json['humidity'] as num?);
    final cloudsRaw =
        (cloudsBlock?['all'] as num?) ?? (json['clouds'] as num?);

    return MapWeatherAmbience(
      temperature: (mainBlock?['temp'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble() ??
          20,
      humidity: humidityRaw != null
          ? (humidityRaw > 1 ? humidityRaw / 100 : humidityRaw).toDouble()
          : 0.5,
      cloudCover: (json['cloud_cover'] as num?)?.toDouble() ??
          (cloudsRaw != null
              ? (cloudsRaw > 1 ? cloudsRaw / 100 : cloudsRaw).toDouble()
              : null) ??
          0.2,
      windSpeed: (windBlock?['speed'] as num?)?.toDouble() ??
          (json['wind_speed'] as num?)?.toDouble() ??
          2,
      windDirection: (windBlock?['deg'] as num?)?.toDouble() ??
          (json['wind_direction'] as num?)?.toDouble() ??
          (json['wind_deg'] as num?)?.toDouble() ??
          180,
      condition: condition,
      isStorm: json['is_storm'] as bool? ??
          conditionLower.contains('thunderstorm'),
      isRain: json['is_rain'] as bool? ??
          json['rain'] != null ||
          conditionLower.contains('rain') ||
          conditionLower.contains('drizzle'),
      isSnow: json['is_snow'] as bool? ??
          json['snow'] != null ||
          conditionLower.contains('snow'),
    );
  }

  final double temperature;
  final double humidity;
  final double cloudCover;
  final double windSpeed;
  final double windDirection;
  final String condition;
  final bool isStorm;
  final bool isRain;
  final bool isSnow;

  Map<String, dynamic> toGlobePayload() => {
        'temperature': temperature,
        'humidity': humidity,
        'cloudCover': cloudCover,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'condition': condition,
        'isStorm': isStorm,
        'isRain': isRain,
        'isSnow': isSnow,
      };

  @override
  List<Object?> get props => [
        temperature,
        humidity,
        cloudCover,
        windSpeed,
        windDirection,
        condition,
        isStorm,
        isRain,
        isSnow,
      ];
}
