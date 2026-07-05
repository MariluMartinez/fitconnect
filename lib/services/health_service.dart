class HealthSnapshot {
  final int steps;
  final double distanceMiles;
  final int activeMinutes;
  final String source;
  final String lastSync;

  const HealthSnapshot({
    required this.steps,
    required this.distanceMiles,
    required this.activeMinutes,
    required this.source,
    required this.lastSync,
  });
}

abstract class HealthService {
  Future<HealthSnapshot?> connect();
  Future<HealthSnapshot?> fetchTodayData();
}
