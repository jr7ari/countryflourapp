import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ─── Location State ───────────────────────────────────────────────────────────

enum LocationStatus { initial, loading, granted, denied, disabled }

class LocationState {
  final LocationStatus status;
  final String city;
  final String locality; // full "City, State" string

  const LocationState({
    this.status = LocationStatus.initial,
    this.city = '',
    this.locality = '',
  });

  LocationState copyWith({
    LocationStatus? status,
    String? city,
    String? locality,
  }) =>
      LocationState(
        status: status ?? this.status,
        city: city ?? this.city,
        locality: locality ?? this.locality,
      );

  /// Display string: "City, State" or fallback
  String get displayLocation {
    if (locality.isNotEmpty) return locality;
    if (city.isNotEmpty) return city;
    return 'Detecting location...';
  }
}

// ─── Location Notifier ────────────────────────────────────────────────────────

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(status: LocationStatus.loading);

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: LocationStatus.disabled,
        city: 'Location off',
        locality: 'Location off',
      );
      return;
    }

    // Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LocationStatus.denied,
        city: 'Location denied',
        locality: 'Location denied',
      );
      return;
    }

    // Fetch position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // low accuracy = faster + less battery
          timeLimit: Duration(seconds: 10),
        ),
      );

      await _reverseGeocode(position.latitude, position.longitude);
    } catch (_) {
      // Fallback to last known position if fresh fetch fails
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          await _reverseGeocode(last.latitude, last.longitude);
          return;
        }
      } catch (_) {}

      state = state.copyWith(
        status: LocationStatus.granted,
        city: 'Unknown',
        locality: 'Unknown location',
      );
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        final state = p.administrativeArea ?? '';
        final locality = [city, state].where((s) => s.isNotEmpty).join(', ');

        this.state = this.state.copyWith(
          status: LocationStatus.granted,
          city: city,
          locality: locality,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: LocationStatus.granted,
        city: 'Unknown',
        locality: 'Unknown location',
      );
    }
  }

  /// Call this to re-fetch (e.g. on tap of the location chip)
  Future<void> refresh() => _init();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final userLocationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
