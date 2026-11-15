import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/data/api_auth_repository.dart';
import '../domain/location_repository.dart';

class DeviceLocationRepository implements LocationRepository {
  final Dio dio;
  final ApiAuthRepository auth;
  DeviceLocationRepository(this.dio, this.auth);
  @override
  Future<PropertyLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure('locationDisabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationFailure('locationDenied');
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = PropertyLocation(position.latitude, position.longitude);
      if (!point.valid) throw const LocationFailure('locationOutside');
      return point;
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure('locationFailed');
    }
  }

  @override
  Future<PropertyLocation?> parseLink(String link) async {
    try {
      final data = await auth.authorizedRequest(
        '/locations/parse-link',
        method: 'POST',
        data: {'url': link},
      );
      return data['coordinates'] == null
          ? null
          : PropertyLocation.fromValues(
              Map<String, dynamic>.from(data['coordinates']),
            );
    } catch (_) {
      throw const LocationFailure('mapLinkInvalid');
    }
  }

  @override
  Future<MapConfiguration> configuration() async {
    try {
      final data = (await dio.get<Map<String, dynamic>>(
        '/locations/map-config',
      )).data!;
      return MapConfiguration(
        tileUrl: data['tile_url'] as String,
        attribution: data['attribution'] as String,
        attributionUrl: data['attribution_url'] as String,
      );
    } catch (_) {
      return const MapConfiguration();
    }
  }
}
