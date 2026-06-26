import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'invite_friends_screen.dart';
import 'bingo_game_screen.dart';
import '../services/firestore_service.dart';

class GamesScreen extends StatefulWidget {
  final HealthSnapshot? snapshot;
  final int stepsGoal;
  final double distanceGoal;
  final int activeMinutesGoal;

  const GamesScreen({
    super.key,
    this.snapshot,
    required this.stepsGoal,
    required this.distanceGoal,
    required this.activeMinutesGoal,
  });

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final FirestoreService firestoreService = FirestoreService();
  List<Map<String, dynamic>> _currentChallenges = [];
  List<Map<String, dynamic>> _pendingChallenges = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentChallenges();
    _loadPendingChallenges();
  }

  Future<void> _loadCurrentChallenges() async {
    final challenges = await firestoreService.getCurrentChallenges();

    if (!mounted) return;

    setState(() {
      _currentChallenges = challenges;
    });
  }

  Future<void> _loadPendingChallenges() async {
    final firestoreService = FirestoreService();

    final challenges = await firestoreService.getPendingChallenges();

    if (!mounted) return;

    setState(() {
      _pendingChallenges = challenges;
    });
  }

  Future<void> _acceptChallenge(String challengeId) async {
    await firestoreService.acceptChallenge(challengeId);

    await _loadPendingChallenges();
    await _loadCurrentChallenges();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Challenge accepted')));
  }

  Future<void> _declineChallenge(String challengeId) async {
    await firestoreService.declineChallenge(challengeId);

    await _loadPendingChallenges();
    await _loadCurrentChallenges();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Challenge declined')));
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.snapshot?.steps ?? 0;
    final distance = widget.snapshot?.distanceMiles ?? 0.0;
    final activeMinutes = 0; // Later: connect real Fitbit active minutes.

    final stepsProgress = widget.stepsGoal == 0
        ? 0.0
        : (steps / widget.stepsGoal).clamp(0.0, 1.0);

    final distanceProgress = widget.distanceGoal == 0
        ? 0.0
        : (distance / widget.distanceGoal).clamp(0.0, 1.0);

    final activeMinutesProgress = widget.activeMinutesGoal == 0
        ? 0.0
        : (activeMinutes / widget.activeMinutesGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Personal Goals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 195,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GoalCard(
                    title: 'Steps',
                    value: steps.toString(),
                    goal: widget.stepsGoal.toString(),
                    unit: 'steps',
                    progress: stepsProgress,
                    icon: Icons.directions_walk,
                    onTap: () {
                      _showGoalDetailsPopup(
                        context,
                        title: 'Steps',
                        value: steps.toString(),
                        goal: widget.stepsGoal.toString(),
                        unit: 'steps',
                        progress: stepsProgress,
                        streakDays: 3,
                      );
                    },
                  ),

                  _GoalCard(
                    title: 'Distance',
                    value: distance.toStringAsFixed(1),
                    goal: widget.distanceGoal.toStringAsFixed(1),
                    unit: 'miles',
                    progress: distanceProgress,
                    icon: Icons.map,
                    onTap: () {
                      _showGoalDetailsPopup(
                        context,
                        title: 'Distance',
                        value: distance.toStringAsFixed(1),
                        goal: widget.distanceGoal.toStringAsFixed(1),
                        unit: 'miles',
                        progress: distanceProgress,
                        streakDays: 2,
                      );
                    },
                  ),

                  _GoalCard(
                    title: 'Active Zone',
                    value: activeMinutes.toString(),
                    goal: widget.activeMinutesGoal.toString(),
                    unit: 'min',
                    progress: activeMinutesProgress,
                    icon: Icons.local_fire_department,
                    onTap: () {
                      _showGoalDetailsPopup(
                        context,
                        title: 'Active Zone',
                        value: activeMinutes.toString(),
                        goal: widget.activeMinutesGoal.toString(),
                        unit: 'min',
                        progress: activeMinutesProgress,
                        streakDays: 1,
                      );
                    },
                  ),

                  _GoalCard(
                    title: 'Workout',
                    value: '0',
                    goal: '1',
                    unit: 'done',
                    progress: 0.0,
                    icon: Icons.fitness_center,
                    onTap: () {
                      _showGoalDetailsPopup(
                        context,
                        title: 'Workout',
                        value: '0',
                        goal: '1',
                        unit: 'done',
                        progress: 0.0,
                        streakDays: 0,
                      );
                    },
                  ),
                ],
              ),
            ),

            if (_pendingChallenges.isNotEmpty) ...[
              const SizedBox(height: 32),

              const Text(
                'Challenge Invitations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 205,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _pendingChallenges.map((challenge) {
                    final type = challenge['type'] ?? 'challenge';

                    final title = challenge['title'] ?? 'Challenge';

                    IconData icon;

                    if (type == 'bingo') {
                      icon = Icons.grid_view;
                    } else if (type == 'step_race') {
                      icon = Icons.emoji_events;
                    } else if (type == 'distance') {
                      icon = Icons.map;
                    } else {
                      icon = Icons.flag_outlined;
                    }

                    return _ChallengeInviteCard(
                      title: title,
                      subtitle: 'Someone invited you',
                      icon: icon,
                      onAccept: () {
                        _acceptChallenge(challenge['id']);
                      },
                      onDecline: () {
                        _declineChallenge(challenge['id']);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 32),

            const Text(
              'Current Challenges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 205,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _currentChallenges.isEmpty
                    ? [
                        _GroupChallengeCard(
                          title: 'No Active Challenges',
                          subtitle: 'Start a challenge below',
                          progressText: '0 active',
                          icon: Icons.flag_outlined,
                        ),
                      ]
                    : _currentChallenges.map((challenge) {
                        final type = challenge['type'] ?? 'challenge';
                        final players = List<String>.from(
                          challenge['players'] ?? [],
                        );
                        final status = challenge['status'] ?? 'pending';

                        final statusText = status == 'pending'
                            ? 'Waiting for players'
                            : status == 'active'
                            ? 'Active now'
                            : status.toString();

                        final title = challenge['title'] ?? 'Challenge';

                        IconData icon;

                        if (type == 'bingo') {
                          icon = Icons.grid_view;
                        } else if (type == 'step_race') {
                          icon = Icons.emoji_events;
                        } else if (type == 'distance') {
                          icon = Icons.map;
                        } else {
                          icon = Icons.flag_outlined;
                        }

                        return _GroupChallengeCard(
                          title: title,
                          subtitle: '${players.length} players',
                          progressText: statusText,
                          icon: icon,
                          onTap: () {
                            if (type == 'bingo') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BingoGameScreen(
                                    invitedFriends: List.generate(
                                      players.length - 1,
                                      (index) => 'Friend ${index + 1}',
                                    ),
                                    snapshot: widget.snapshot,
                                    challengeId: challenge['id'],
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Start a Challenge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 205,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CreateChallengeCard(
                    onTap: () {
                      _showCreateChallengePopup(context);
                    },
                  ),

                  _GroupChallengeCard(
                    title: 'Bingo',
                    subtitle: 'Weekly challenge',
                    progressText: 'Invite friends',
                    icon: Icons.grid_view,
                    onTap: () {
                      _createQuickChallenge(context, 'bingo');
                    },
                  ),

                  _GroupChallengeCard(
                    title: 'Step Race',
                    subtitle: 'Most steps wins',
                    progressText: 'Invite friends',
                    icon: Icons.emoji_events,
                    onTap: () {
                      _createQuickChallenge(context, 'step_race');
                    },
                  ),

                  _GroupChallengeCard(
                    title: 'Distance',
                    subtitle: 'Most miles wins',
                    progressText: 'Invite friends',
                    icon: Icons.map,
                    onTap: () {
                      _createQuickChallenge(context, 'distance');
                    },
                  ),

                  _GroupChallengeCard(
                    title: 'Active Minutes',
                    subtitle: 'Most active minutes',
                    progressText: 'Invite friends',
                    icon: Icons.local_fire_department,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChallengePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start a Group Challenge',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _ChallengeOption(
                title: 'Bingo',
                subtitle: 'Complete fitness squares before your friends.',
                icon: Icons.grid_view,
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InviteFriendsScreen(
                        challengeName: 'Bingo',
                        snapshot: widget.snapshot,
                      ),
                    ),
                  );
                },
              ),

              _ChallengeOption(
                title: 'Step Race',
                subtitle: 'Compete to get the most steps.',
                icon: Icons.directions_run,
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              _ChallengeOption(
                title: 'Distance Challenge',
                subtitle: 'See who can go the farthest.',
                icon: Icons.map,
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              _ChallengeOption(
                title: 'Active Minutes',
                subtitle: 'Compete for the most active minutes.',
                icon: Icons.local_fire_department,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createQuickChallenge(BuildContext context, String type) async {
    final firestoreService = FirestoreService();
    final friends = await firestoreService.getCurrentUserFriends();

    if (!context.mounted) return;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add friends before starting a challenge'),
        ),
      );
      return;
    }

    final selectedFriends = <String>{};
    final titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Challenge'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Challenge name',
                        hintText: 'Example: Weekend Bingo',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...friends.map((friend) {
                      final uid = friend['uid'];
                      final name = friend['publicName'] ?? 'User';

                      return CheckboxListTile(
                        value: selectedFriends.contains(uid),
                        title: Text(name),
                        subtitle: Text(friend['email'] ?? ''),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedFriends.add(uid);
                            } else {
                              selectedFriends.remove(uid);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedFriends.isEmpty
                      ? null
                      : () async {
                          final typedTitle = titleController.text.trim();

                          await firestoreService.createChallenge(
                            type: type,
                            playerUids: selectedFriends.toList(),
                            title: typedTitle.isEmpty
                                ? 'Bingo Challenge'
                                : typedTitle,
                          );

                          await _loadCurrentChallenges();

                          if (!context.mounted) return;

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$type challenge created')),
                          );
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String value;
  final String goal;
  final String unit;
  final double progress;
  final IconData icon;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.value,
    required this.goal,
    required this.unit,
    required this.progress,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '$value / $goal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(unit, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text('$percent% complete', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CreateChallengeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateChallengeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 42),
            SizedBox(height: 12),
            Text(
              'Start\nChallenge',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGoalDetailsPopup(
  BuildContext context, {
  required String title,
  required String value,
  required String goal,
  required String unit,
  required double progress,
  required int streakDays,
}) {
  final percent = (progress * 100).round();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 145,
                    width: 145,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFEDEDF2),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text('$value / $goal $unit', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 12),

            Text(
              '$streakDays day streak',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
  );
}

class _GroupChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String progressText;
  final IconData icon;
  final VoidCallback? onTap;

  const _GroupChallengeCard({
    required this.title,
    required this.subtitle,
    required this.progressText,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Text(
              progressText,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeInviteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ChallengeInviteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(subtitle, style: const TextStyle(color: Colors.grey)),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ChallengeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
