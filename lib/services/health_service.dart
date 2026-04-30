class HealthSnapshot {
  final int steps;
  final double distanceMiles;
  final String source;
  final String lastSync;

  const HealthSnapshot({
    required this.steps,
    required this.distanceMiles,
    required this.source,
    required this.lastSync,
  });
}

abstract class HealthService {
  Future<HealthSnapshot?> connect();
  Future<HealthSnapshot?> fetchTodayData();
}