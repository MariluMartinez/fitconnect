import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import '../config/google_maps.dart';

class GooglePlacesService {
  final FlutterGooglePlacesSdk _places =
      FlutterGooglePlacesSdk(GoogleMapsConfig.apiKey);

  Future<List<AutocompletePrediction>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final result = await _places.findAutocompletePredictions(
      query,
      countries: ['US'],
    );

    return result.predictions;
  }
}