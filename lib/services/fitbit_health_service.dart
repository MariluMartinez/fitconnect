import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'health_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FitbitHealthService implements HealthService {
  static const String clientId = '23VC6K';
  static const String redirectUri = 'fitconnect://callback';

  String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://127.0.0.1:3000';
    }
  }

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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in.');
    }

    final uid = user.uid;
    debugPrint('Current UID: $uid');

    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$baseUrl/exchange-token'),
      );

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'code': code, 'uid': uid}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('Backend token response: $responseBody');

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
      final activeMinutes = summary['fairlyActiveMinutes'] ?? 0;

      final distances = summary['distances'] as List;
      final totalDistance = distances.firstWhere(
        (item) => item['activity'] == 'total',
        orElse: () => {'distance': 0},
      )['distance'];

      if (accessToken == null) {
        throw Exception('No access token returned from backend.');
      }

      debugPrint('Real Fitbit steps: $steps');
      debugPrint('Real Fitbit distance: $totalDistance');
      debugPrint('Real Fitbit active minutes: $activeMinutes');
      debugPrint('Refresh token received: ${refreshToken != null}');

      return HealthSnapshot(
        steps: steps,
        distanceMiles: totalDistance.toDouble(),
        activeMinutes: activeMinutes,
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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in.');
    }

    final uid = user.uid;

    try {
      final request = await client.getUrl(Uri.parse('$baseUrl/fitbit-data?uid=$uid'));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('Fetch data response: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch Fitbit data: $responseBody');
      }

      final data = jsonDecode(responseBody);
      final activity = data['activity'];

      final summary = activity['summary'];
      final steps = summary['steps'] ?? 0;
      final activeMinutes = summary['fairlyActiveMinutes'] ?? 0;

      final distances = summary['distances'] as List;
      final totalDistance = distances.firstWhere(
        (item) => item['activity'] == 'total',
        orElse: () => {'distance': 0},
      )['distance'];

      return HealthSnapshot(
        steps: steps,
        distanceMiles: totalDistance.toDouble(),
        activeMinutes: activeMinutes,
        source: 'Fitbit',
        lastSync: 'Just now',
      );
    } finally {
      client.close();
    }
  }
}
