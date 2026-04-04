import 'package:geolocator/geolocator.dart';

Future<Position?> getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    return null;
  }
}
