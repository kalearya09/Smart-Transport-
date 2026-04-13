class AppConstants {
  // ── Mapbox (replace with your tokens from mapbox.com) ──────────
  static const String mapboxPublicToken =
      'pk.YOUR_MAPBOX_PUBLIC_TOKEN_HERE';

  static const String mapboxDirectionsBase =
      'https://api.mapbox.com/directions/v5/mapbox';

  static const String mapboxGeocodingBase =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  static const String mapStyleLight =
      'mapbox://styles/mapbox/streets-v12';
  static const String mapStyleDark =
      'mapbox://styles/mapbox/dark-v11';
  static const String mapStyleSatellite =
      'mapbox://styles/mapbox/satellite-streets-v12';

  // ── Firebase ───────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String driversCollection = 'drivers';
  static const String vehicleLocationsPath = 'vehicle_locations';

  // ── Hive ───────────────────────────────────────────────────────
  static const String favoritesBox = 'favorites';
  static const String settingsBox = 'settings';

  // ── Map defaults (Pune, India) ─────────────────────────────────
  static const double defaultLat = 18.5204;
  static const double defaultLng = 73.8567;
  static const double defaultZoom = 13.0;
  static const double nearbyRadiusKm = 2.0;

  // ── SOS ────────────────────────────────────────────────────────
  static const String sosPhoneNumber = '112';
}