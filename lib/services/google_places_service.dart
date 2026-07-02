import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import '../config/google_maps.dart';
import '../models/place_details.dart';

class GooglePlacesService {
  final FlutterGooglePlacesSdk _places = FlutterGooglePlacesSdk(
    GoogleMapsConfig.apiKey,
  );

  Future<List<AutocompletePrediction>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final result = await _places.findAutocompletePredictions(
      query,
      countries: ['US'],
    );

    return result.predictions;
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final result = await _places.fetchPlace(
      placeId,
      fields: [
        PlaceField.Id,
        PlaceField.Name,
        PlaceField.AddressComponents,
        PlaceField.Location,
      ],
    );

    final place = result.place;

    if (place == null || place.latLng == null) return null;

    String city = '';
    String state = '';

    for (final component in place.addressComponents ?? []) {
      final types = component.types ?? [];

      if (types.contains('locality')) {
        city = component.name;
      }

      if (types.contains('administrative_area_level_1')) {
        state = component.shortName ?? component.name;
      }
    }

    return PlaceDetails(
      placeId: place.id ?? placeId,
      name: place.name ?? '',
      city: city,
      state: state,
      latitude: place.latLng!.lat,
      longitude: place.latLng!.lng,
    );
  }
}
