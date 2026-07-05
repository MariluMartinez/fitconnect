import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/health_service.dart';
import '../models/bingo_goal.dart';
import '../widgets/player_card.dart';
import '../services/firestore_service.dart';

class BingoGameScreen extends StatefulWidget {
  final List<String> invitedFriends;
  final HealthSnapshot? snapshot;
  final String challengeId;

  const BingoGameScreen({
    super.key,
    required this.invitedFriends,
    required this.snapshot,
    required this.challengeId,
  });

  @override
  State<BingoGameScreen> createState() => _BingoGameScreenState();
}

class _BingoGameScreenState extends State<BingoGameScreen> {
  int usedSteps = 0;
  double usedDistance = 0.0;
  int usedActiveMinutes = 0;
  String patternName = 'Bingo Pattern';

  final FirestoreService firestoreService = FirestoreService();

  List<BingoGoal> bingoGoals = [];

  final Set<int> completedSquares = {};

  Map<String, List<int>> playerProgress = {};
  Map<String, String> playerNames = {};
  List<String> acceptedPlayerUids = [];
  Map<String, String> playerPhotos = {};

  bool isChallengeFinished = false;
  String winnerName = '';

  Set<int> targetShapeSquares = {0, 4, 6, 8, 12, 16, 18, 20, 24};

  @override
  void initState() {
    super.initState();
    _loadBingoBoard();
    _loadSavedCompletedSquares();
    _loadPlayerProgress();
    _loadPlayerNames();
    _loadAcceptedPlayerUids();
    _loadPlayerPhotos();
    _loadChallengeStatus();
    _loadBingoPattern();
  }

  List<BingoGoal> _generateRandomBingoBoard() {
    final random = Random();
    final board = <BingoGoal>[];

    for (int i = 0; i < 25; i++) {
      final type = BingoGoalType.values[random.nextInt(3)];

      if (type == BingoGoalType.steps) {
        final steps = 100 + random.nextInt(900);
        final roundedSteps = (steps / 100).round() * 100;

        board.add(
          BingoGoal(
            type: BingoGoalType.steps,
            label: '$roundedSteps',
            requiredValue: roundedSteps.toDouble(),
          ),
        );
      }

      if (type == BingoGoalType.distance) {
        final distance = 0.5 + random.nextDouble() * 9.0;

        board.add(
          BingoGoal(
            type: BingoGoalType.distance,
            label: '${distance.toStringAsFixed(1)} mi',
            requiredValue: distance,
          ),
        );
      }

      if (type == BingoGoalType.activeMinutes) {
        final minutes = 10 + random.nextInt(56);

        board.add(
          BingoGoal(
            type: BingoGoalType.activeMinutes,
            label: '$minutes min',
            requiredValue: minutes.toDouble(),
          ),
        );
      }
    }

    return board;
  }

  Future<void> _loadBingoBoard() async {
    final savedBoard = await firestoreService.getBingoBoard(widget.challengeId);

    if (savedBoard != null) {
      if (!mounted) return;

      setState(() {
        bingoGoals = savedBoard.map((tile) {
          final typeString = tile['type'];
          final label = tile['label'];
          final requiredValue = tile['requiredValue'];

          BingoGoalType type;

          if (typeString == 'steps') {
            type = BingoGoalType.steps;
          } else if (typeString == 'distance') {
            type = BingoGoalType.distance;
          } else {
            type = BingoGoalType.activeMinutes;
          }

          return BingoGoal(
            type: type,
            label: label,
            requiredValue: (requiredValue as num).toDouble(),
          );
        }).toList();
      });

      return;
    }

    final newBoard = _generateRandomBingoBoard();

    await firestoreService.saveBingoBoard(
      challengeId: widget.challengeId,
      board: newBoard.map((goal) {
        String typeString;

        if (goal.type == BingoGoalType.steps) {
          typeString = 'steps';
        } else if (goal.type == BingoGoalType.distance) {
          typeString = 'distance';
        } else {
          typeString = 'activeMinutes';
        }

        return {
          'type': typeString,
          'label': goal.label,
          'requiredValue': goal.requiredValue,
        };
      }).toList(),
    );

    if (!mounted) return;

    setState(() {
      bingoGoals = newBoard;
    });
  }

  Future<void> _loadBingoPattern() async {
    final pattern = await firestoreService.getBingoPattern(widget.challengeId);

    final name = await firestoreService.getBingoPatternName(widget.challengeId);

    final hasSeen = await firestoreService.hasSeenBingoPattern(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      targetShapeSquares = pattern;
      patternName = name;
    });

    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        _showPatternPopup();

        await firestoreService.markBingoPatternSeen(widget.challengeId);
      });
    }
  }

  void _showPatternPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(patternName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Complete these highlighted tiles to win.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _PatternPreview(targetShapeSquares: targetShapeSquares),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSavedCompletedSquares() async {
    final savedSquares = await firestoreService.getBingoCompletedSquares(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      completedSquares.addAll(savedSquares);
    });
  }

  Future<void> _loadAcceptedPlayerUids() async {
    final uids = await firestoreService.getAcceptedPlayerUids(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      acceptedPlayerUids = uids;
    });
  }

  Future<void> _loadPlayerProgress() async {
    final progress = await firestoreService.getBingoProgressForChallenge(
      widget.challengeId,
    );

    if (!mounted) return;

    setState(() {
      playerProgress = progress;
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

  Future<void> _loadChallengeStatus() async {
    final challenge = await firestoreService.getChallengeById(
      widget.challengeId,
    );

    if (challenge == null || !mounted) return;

    final status = challenge['status'];
    final winner = challenge['winnerName'] ?? 'Someone';

    setState(() {
      isChallengeFinished = status == 'finished';
      winnerName = winner;
    });

    if (status == 'finished') {
      _showWinnerDialog(winner);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.snapshot?.steps ?? 0;
    final totalDistance = widget.snapshot?.distanceMiles ?? 0.0;
    final totalActiveMinutes = widget.snapshot?.activeMinutes ?? 0;

    final availableSteps = totalSteps - usedSteps;
    final availableDistance = totalDistance - usedDistance;
    final availableActiveMinutes = totalActiveMinutes - usedActiveMinutes;

    final completedTargetSquares = completedSquares
        .where((index) => targetShapeSquares.contains(index))
        .length;

    final totalTargetSquares = targetShapeSquares.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Bingo Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Your Bingo Card',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Available: $availableSteps steps • ${availableDistance.toStringAsFixed(1)} mi • $availableActiveMinutes min',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C5CFA),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Pattern progress: $completedTargetSquares / $totalTargetSquares tiles',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Expanded(
              flex: 3,
              child: GridView.builder(
                itemCount: bingoGoals.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final goal = bingoGoals[index];
                  final isCompleted = completedSquares.contains(index);
                  final isTargetSquare = targetShapeSquares.contains(index);

                  return GestureDetector(
                    onTap: () {
                      _tryCompleteSquare(
                        context,
                        index,
                        goal,
                        availableSteps,
                        availableDistance,
                        availableActiveMinutes,
                        targetShapeSquares,
                      );
                    },

                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : _getTileColor(goal.type),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isTargetSquare
                              ? Colors.amber
                              : Colors.blue.shade100,
                          width: isTargetSquare ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIcon(goal.type),
                            color: isCompleted ? Colors.white : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Players',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: acceptedPlayerUids.isEmpty
                    ? 1
                    : acceptedPlayerUids.length,
                itemBuilder: (context, index) {
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;

                  if (acceptedPlayerUids.isEmpty) {
                    return PlayerCard(
                      name: 'You',
                      photoUrl: '',
                      targetShapeSquares: targetShapeSquares,
                      completedSquares: completedSquares,
                    );
                  }

                  final uid = acceptedPlayerUids[index];
                  final squares = playerProgress[uid] ?? [];

                  final isYou = uid == currentUid;

                  return PlayerCard(
                    name: isYou ? 'You' : playerNames[uid] ?? 'Unknown Player',
                    photoUrl: playerPhotos[uid] ?? '',
                    targetShapeSquares: targetShapeSquares,
                    completedSquares: squares.toSet(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tryCompleteSquare(
    BuildContext context,
    int index,
    BingoGoal goal,
    int availableSteps,
    double availableDistance,
    int availableActiveMinutes,
    Set<int> targetShapeSquares,
  ) {
    if (isChallengeFinished) {
      _showWinnerDialog(winnerName.isEmpty ? 'Someone' : winnerName);
      return;
    }
    if (!targetShapeSquares.contains(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This tile is not part of the required pattern.'),
        ),
      );
      return;
    }
    if (completedSquares.contains(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This square is already completed.')),
      );
      return;
    }

    if (goal.type == BingoGoalType.steps) {
      final requiredSteps = goal.requiredValue.toInt();

      if (availableSteps >= requiredSteps) {
        setState(() {
          completedSquares.add(index);
          usedSteps += requiredSteps;
        });

        _checkForPatternWin(context, goal.label);
        firestoreService.saveBingoCompletedSquares(
          challengeId: widget.challengeId,
          completedSquares: completedSquares.toList(),
        );
        _loadPlayerProgress();
      } else {
        _showNotEnoughMessage(
          context,
          'You need $requiredSteps available steps. You only have $availableSteps.',
        );
      }
    }

    if (goal.type == BingoGoalType.distance) {
      final requiredDistance = goal.requiredValue;

      if (availableDistance >= requiredDistance) {
        setState(() {
          completedSquares.add(index);
          usedDistance += requiredDistance;
        });

        _checkForPatternWin(context, goal.label);
        firestoreService.saveBingoCompletedSquares(
          challengeId: widget.challengeId,
          completedSquares: completedSquares.toList(),
        );
        _loadPlayerProgress();
      } else {
        _showNotEnoughMessage(
          context,
          'You need ${requiredDistance.toStringAsFixed(1)} available miles. You only have ${availableDistance.toStringAsFixed(1)}.',
        );
      }
    }

    if (goal.type == BingoGoalType.activeMinutes) {
      final requiredMinutes = goal.requiredValue.toInt();

      if (availableActiveMinutes >= requiredMinutes) {
        setState(() {
          completedSquares.add(index);
          usedActiveMinutes += requiredMinutes;
        });

        _checkForPatternWin(context, goal.label);
        firestoreService.saveBingoCompletedSquares(
          challengeId: widget.challengeId,
          completedSquares: completedSquares.toList(),
        );
        _loadPlayerProgress();
      } else {
        _showNotEnoughMessage(
          context,
          'You need $requiredMinutes available active minutes. You only have $availableActiveMinutes.',
        );
      }
    }
  }

  Future<void> _checkForPatternWin(BuildContext context, String label) async {
    final hasCompletedPattern = targetShapeSquares.every(
      (index) => completedSquares.contains(index),
    );

    if (hasCompletedPattern) {
      await firestoreService.finishChallenge(challengeId: widget.challengeId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('🏆 Bingo!'),
            content: const Text(
              'You completed the pattern and won the challenge!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Games'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Completed: $label')));
    }
  }

  void _showWinnerDialog(String winner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🏆 Bingo Finished'),
          content: Text('$winner won this challenge!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotEnoughMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

IconData _getIcon(BingoGoalType type) {
  switch (type) {
    case BingoGoalType.steps:
      return Icons.directions_walk;
    case BingoGoalType.distance:
      return Icons.place;
    case BingoGoalType.activeMinutes:
      return Icons.local_fire_department;
  }
}

Color _getTileColor(BingoGoalType type) {
  switch (type) {
    case BingoGoalType.steps:
      return const Color(0xFF2EC4B6); // teal
    case BingoGoalType.distance:
      return const Color(0xFF6C63FF); // purple
    case BingoGoalType.activeMinutes:
      return const Color(0xFFFF4DA6); // pink
  }
}

class _PatternPreview extends StatelessWidget {
  final Set<int> targetShapeSquares;

  const _PatternPreview({required this.targetShapeSquares});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 25,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final isTarget = targetShapeSquares.contains(index);

          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTarget ? Colors.green : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }
}
