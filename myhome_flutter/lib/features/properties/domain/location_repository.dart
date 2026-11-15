class PropertyLocation {
  final double latitude, longitude;
  const PropertyLocation(this.latitude, this.longitude);
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= 22 &&
      latitude <= 32 &&
      longitude >= 24 &&
      longitude <= 37;
  Map<String, String> toJson() => {
    'latitude': latitude.toStringAsFixed(7),
    'longitude': longitude.toStringAsFixed(7),
  };
  static PropertyLocation? fromValues(Map<String, dynamic> values) {
    final lat = double.tryParse('${values['latitude']}'),
        lon = double.tryParse('${values['longitude']}');
    if (lat == null || lon == null) return null;
    final point = PropertyLocation(lat, lon);
    return point.valid ? point : null;
  }
}

class MapConfiguration {
  final String tileUrl, attribution, attributionUrl;
  const MapConfiguration({
    this.tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.attribution = '© OpenStreetMap contributors',
    this.attributionUrl = 'https://www.openstreetmap.org/copyright',
  });
}

class LocationFailure implements Exception {
  final String code;
  const LocationFailure(this.code);
}

abstract class LocationRepository {
  Future<PropertyLocation> currentLocation();
  Future<PropertyLocation?> parseLink(String link);
  Future<MapConfiguration> configuration();
}
