import 'dart:convert';
import 'dart:io';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'health_service.dart';

class FitbitHealthService implements HealthService {
  static const String clientId = '23VC6K';
  static const String redirectUri = 'fitconnect://callback';

  @override
  Future<HealthSnapshot?> connect() async {
    final authUrl = Uri.https('www.fitbit.com', '/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'activity profile',
      'expires_in': '31536000',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'fitconnect',
    );

    final callbackUri = Uri.parse(result);
    final code = callbackUri.queryParameters['code'];

    if (code == null) {
      throw Exception('No authorization code returned from Fitbit.');
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('http://10.0.2.2:3000/exchange-token'),
      );

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'code': code}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Backend token response: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Backend token exchange failed: $responseBody');
      }

      final data = jsonDecode(responseBody);

      final tokens = data['tokens'];
      final activity = data['activity'];

      final accessToken = tokens['access_token'];
      final refreshToken = tokens['refresh_token'];

      final summary = activity['summary'];
      final steps = summary['steps'] ?? 0;

      final distances = summary['distances'] as List;
      final totalDistance = distances.firstWhere(
        (item) => item['activity'] == 'total',
        orElse: () => {'distance': 0},
      )['distance'];

      print('Real Fitbit steps: $steps');
      print('Real Fitbit distance: $totalDistance');

      if (accessToken == null) {
        throw Exception('No access token returned from backend.');
      }

      print('Fitbit access token received.');
      print('Refresh token received: ${refreshToken != null}');

      return HealthSnapshot(
        steps: steps,
        distanceMiles: totalDistance.toDouble(),
        source: 'Fitbit',
        lastSync: 'Just now',
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<HealthSnapshot?> fetchTodayData() async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('http://10.0.2.2:3000/fitbit-data'),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Fetch data response: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Fitbit data: $responseBody');
      }

      final data = jsonDecode(responseBody);
      final activity = data['activity'];

      final summary = activity['summary'];
      final steps = summary['steps'] ?? 0;

      final distances = summary['distances'] as List;
      final totalDistance = distances.firstWhere(
        (item) => item['activity'] == 'total',
        orElse: () => {'distance': 0},
      )['distance'];

      return HealthSnapshot(
        steps: steps,
        distanceMiles: totalDistance.toDouble(),
        source: 'Fitbit',
        lastSync: 'Just now',
      );
    } finally {
      client.close();
    }
  }
}
