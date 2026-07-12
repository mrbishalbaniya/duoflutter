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

  factory MapWeatherAmbience.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'] as String? ??
        json['main'] as String? ??
        'clear';
    return MapWeatherAmbience(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 20,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.5,
      cloudCover: (json['cloud_cover'] as num?)?.toDouble() ??
          (json['clouds'] as num?)?.toDouble() ??
          0.2,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 2,
      windDirection: (json['wind_direction'] as num?)?.toDouble() ??
          (json['wind_deg'] as num?)?.toDouble() ??
          180,
      condition: condition,
      isStorm: json['is_storm'] as bool? ?? false,
      isRain: json['is_rain'] as bool? ??
          json['rain'] != null ||
          condition.toLowerCase().contains('rain'),
      isSnow: json['is_snow'] as bool? ??
          json['snow'] != null ||
          condition.toLowerCase().contains('snow'),
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
