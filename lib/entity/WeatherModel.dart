class WeatherModel {
  final String city;
  final double temperature;
  final String description;
  final int humidity;

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'],
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
    );
  }
}
