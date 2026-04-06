import 'package:flutter/material.dart';
import 'package:smartirrigation/entity/WeatherModel.dart';
import 'package:smartirrigation/services/CurrentLocationService.dart';
import 'package:smartirrigation/services/WeatherService.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherModel? weather;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    final pos = await getCurrentLocation();
    if (pos != null) {
      final data = await WeatherService().fetchWeather(
        pos.latitude,
        pos.longitude,
      );
      setState(() {
        weather = data;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (weather == null) {
      return const Text("Weather unavailable");
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather!.city,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Sky: ${weather!.description}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Humidity: ${weather!.humidity}%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "${weather!.temperature.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              (weather!.temperature > 30)
                  ? Icon(Icons.sunny, size: 32, color: Colors.orange[400])
                  : Icon(Icons.wb_cloudy, size: 32, color: Colors.blue[400]),
            ],
          ),
        ],
      ),
    );
  }
}
