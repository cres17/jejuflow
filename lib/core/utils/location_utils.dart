import 'package:geolocator/geolocator.dart';
import '../models/spot.dart';

Future<SpotRegion> detectRegion() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return SpotRegion.jejuCity;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return SpotRegion.jejuCity;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(const Duration(seconds: 10));

    return pos.latitude < 33.38 ? SpotRegion.seogwipo : SpotRegion.jejuCity;
  } catch (_) {
    return SpotRegion.jejuCity;
  }
}
