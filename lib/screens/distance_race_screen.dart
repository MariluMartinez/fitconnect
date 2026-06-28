import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../services/firestore_service.dart';

class DistanceRaceScreen extends StatefulWidget {
  final String challengeId;
  final HealthSnapshot? snapshot;

  const DistanceRaceScreen({
    super.key,
    required this.challengeId,
    required this.snapshot,
  });

  @override
  State<DistanceRaceScreen> createState() => _DistanceRaceScreenState();
}

class _DistanceRaceScreenState extends State<DistanceRaceScreen> {
  final FirestoreService firestoreService = FirestoreService();

  double distanceGoal = 5.0;
  String title = 'Distance Race';

  Map<String, String> playerNames = {};
  Map<String, String> playerPhotos = {};
  List<String> acceptedPlayerUids = [];
  Map<String, Map<String, dynamic>> playerData = {};

  @override
  void initState() {
    super.initState();
    _loadChallenge();
    _loadPlayerNames();
    _loadPlayerPhotos();
    _loadAcceptedPlayers();
    _loadPlayerData();
  }

  Future<void> _loadChallenge() async {
    final challenge = await firestoreService.getChallengeById(
      widget.challengeId,
    );

    if (challenge == null || !mounted) return;

    setState(() {
      title = challenge['title'] ?? 'Distance Race';
      distanceGoal = (challenge['distanceGoal'] as num?)?.toDouble() ?? 5.0;
    });
  }

  Future<void> _loadPlayerNames() async {
    final names = await firestoreService.getChallengePlayerNames(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      playerNames = names;
    });
  }

  Future<void> _loadPlayerPhotos() async {
    final photos = await firestoreService.getChallengePlayerPhotos(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      playerPhotos = photos;
    });
  }

  Future<void> _loadAcceptedPlayers() async {
    final challenge = await firestoreService.getChallengeById(
      widget.challengeId,
    );

    if (challenge == null || !mounted) return;

    setState(() {
      acceptedPlayerUids = List<String>.from(
        challenge['acceptedPlayers'] ?? [],
      );
    });
  }

  Future<void> _loadPlayerData() async {
    final data = await firestoreService.getChallengePlayerData(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      playerData = data;
    });

    _checkForDistanceRaceWinner();
  }

  String? _getLeaderUid() {
    if (playerData.isEmpty) return null;

    String? leaderUid;
    double leaderDistance = -1;

    playerData.forEach((uid, data) {
      final distance = (data['todayDistanceMiles'] as num?)?.toDouble() ?? 0.0;

      if (distance > leaderDistance) {
        leaderDistance = distance;
        leaderUid = uid;
      }
    });

    return leaderUid;
  }

  void _showWinnerDialog(
    String winnerName,
    double winnerDistance,
    String winnerUid,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🏆 Challenge Complete!'),
          content: Text(
            '$winnerName won $title!\n\n'
            'Goal: ${_formatMiles(distanceGoal)} miles\n'
            '$winnerName: ${_formatMiles(winnerDistance)} miles',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await firestoreService.finishChallenge(
                  challengeId: widget.challengeId,
                );

                if (!mounted) return;

                Navigator.pop(context); // close dialog

                Navigator.pop(context); // go back to Challenges
              },
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }

  void _checkForDistanceRaceWinner() {
    for (final entry in playerData.entries) {
      final uid = entry.key;
      final data = entry.value;

      final distance = (data['todayDistanceMiles'] as num?)?.toDouble() ?? 0.0;

      if (distance >= distanceGoal) {
        final name = data['name'] ?? playerNames[uid] ?? 'Someone';

        _showWinnerDialog(name, distance, uid);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Race',
            onPressed: () async {
              await _loadPlayerData();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            Center(
              child: Text(
                'Goal: ${_formatMiles(distanceGoal)} miles',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: _DistanceRaceTrack(
                playerUids: acceptedPlayerUids,
                playerData: playerData,
                playerNames: playerNames,
                playerPhotos: playerPhotos,
                distanceGoal: distanceGoal,
                leaderUid: _getLeaderUid(),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DistanceRaceTrack extends StatelessWidget {
  final List<String> playerUids;
  final Map<String, Map<String, dynamic>> playerData;
  final Map<String, String> playerNames;
  final Map<String, String> playerPhotos;
  final double distanceGoal;
  final String? leaderUid;

  const _DistanceRaceTrack({
    required this.playerUids,
    required this.playerData,
    required this.playerNames,
    required this.playerPhotos,
    required this.distanceGoal,
    required this.leaderUid,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const avatarRadius = 24.0;
        const labelWidth = 72.0;
        const rightLabelWidth = 36.0;

        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final finishY = height * 0.07;
        final startY = height * 0.70;
        final laneTop = finishY;
        final laneBottom = startY;
        final laneHeight = laneBottom - laneTop;

        final trackLeft = labelWidth;
        final trackRight = width - rightLabelWidth;
        final trackWidth = trackRight - trackLeft;

        final players = playerUids.map((uid) {
          final player = playerData[uid] ?? {};
          final name = player['name'] ?? playerNames[uid] ?? 'Unknown';
          final photoUrl = player['photoUrl'] ?? playerPhotos[uid] ?? '';
          final distance = (player['todayDistanceMiles'] as num?)?.toDouble() ?? 0.0;
          final progress = distanceGoal == 0
              ? 0.0
              : (distance / distanceGoal).clamp(0.0, 1.0);

          return {
            'uid': uid,
            'name': name,
            'photoUrl': photoUrl,
            'distance': distance,
            'progress': progress,
          };
        }).toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // light progress guide lines
              for (final percent in [0.2, 0.4, 0.6, 0.8])
                Positioned(
                  left: trackLeft,
                  right: rightLabelWidth,
                  top: laneBottom - (laneHeight * percent),
                  child: Divider(thickness: 1, color: Colors.grey.shade300),
                ),

              // right-side percent labels
              for (final percent in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
                Positioned(
                  right: 5,
                  top: laneBottom - (laneHeight * percent) - 8,
                  width: rightLabelWidth,
                  child: Text(
                    '${(percent * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ),

              // FINISH label + line
              Positioned(
                left: 8,
                top: finishY - 12,
                width: labelWidth,
                child: const Text(
                  'FINISH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),

              Positioned(
                left: trackLeft,
                right: rightLabelWidth + 5,
                top: finishY - 8,
                child: const Divider(thickness: 2, color: Colors.black87),
              ),

              // START label + line
              Positioned(
                left: 8,
                top: startY - 14,
                width: labelWidth,
                child: const Text(
                  'START',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),

              Positioned(
                left: trackLeft,
                right: rightLabelWidth + 5,
                top: startY - 8,
                child: const Divider(thickness: 2, color: Colors.black87),
              ),

              // player lanes
              ...players.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;

                final uid = player['uid'] as String;
                final name = player['name'] as String;
                final photoUrl = player['photoUrl'] as String;
                final distance = (player['distance'] as num?)?.toDouble() ?? 0.0;
                final progress = player['progress'] as double;

                final isLeader = uid == leaderUid;
                final hasFinished = progress >= 1.0;

                final laneCount = players.length;
                final laneSpacing = laneCount <= 1
                    ? trackWidth / 2
                    : trackWidth / laneCount;

                final laneX = laneCount <= 1
                    ? trackLeft + trackWidth / 2
                    : trackLeft + laneSpacing * index + laneSpacing / 2;

                final avatarCenterY = hasFinished
                    ? laneTop
                    : laneBottom - (laneHeight * progress);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // vertical lane
                    Positioned(
                      left: laneX - 7.5,
                      top: laneTop,
                      child: Container(
                        width: 15,
                        height: laneHeight,
                        decoration: BoxDecoration(
                          color: isLeader
                              ? Colors.amber.shade200
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    // trophy for finished winner
                    if (hasFinished && isLeader)
                      Positioned(
                        left: laneX - 18,
                        top: avatarCenterY - avatarRadius - 48,
                        child: const Text('🏆', style: TextStyle(fontSize: 28)),
                      ),

                    // distance bubble
                    // distance bubble
                    if (distance > 0 && !hasFinished)
                      Positioned(
                        left: laneX - 30,
                        top: avatarCenterY - avatarRadius - 26,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isLeader
                                ? Colors.amber.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLeader
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            _formatMiles(distance),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLeader
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),

                    // avatar
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      left: laneX - avatarRadius,
                      top: avatarCenterY - avatarRadius,
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: isLeader
                            ? const Color(0xFFFFD700)
                            : Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                      ),
                    ),

                    // distance
                    Positioned(
                      left: laneX - 65,
                      top: startY + 30,
                      width: 130,
                      child: Text(
                        '${_formatMiles(distance)} / ${_formatMiles(distanceGoal)} mi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

String _formatMiles(double miles) {
  return miles.toStringAsFixed(1);
}
