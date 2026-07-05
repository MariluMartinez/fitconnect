import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/health_service.dart';

class HomeScreen extends StatefulWidget {
  final HealthSnapshot? snapshot;
  final int stepsGoal;
  final double distanceGoal;
  final bool isConnected;
  final bool isLoadingFitbit;
  final Future<void> Function() onRefresh;

  const HomeScreen({
    super.key,
    required this.snapshot,
    required this.stepsGoal,
    required this.distanceGoal,
    required this.isConnected,
    required this.isLoadingFitbit,
    required this.onRefresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'there';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      userName = doc.data()?['publicName'] ?? user.displayName ?? 'there';
    });
  }

  String formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.snapshot?.steps ?? 0;
    final distance = widget.snapshot?.distanceMiles ?? 0.0;
    final progress = widget.stepsGoal == 0
        ? 0.0
        : (steps / widget.stepsGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('FitConnect'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                'Hey, $userName 👋',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Here is your movement snapshot for today.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C5CFA), Color(0xFFA98CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${formatNumber(steps)} steps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Distance: ${distance.toStringAsFixed(1)} miles',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 16),

                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of your ${formatNumber(widget.stepsGoal)}-step goal',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.flag_outlined,
                    title: 'Today\'s Goal',
                    value: formatNumber(widget.stepsGoal),
                    subtitle: 'Daily steps',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.sync,
                    title: 'Last Sync',
                    value: widget.snapshot?.lastSync ?? 'Not synced',
                    subtitle: widget.isConnected
                        ? 'Fitbit connected'
                        : 'Connect Fitbit',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: widget.isLoadingFitbit
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final wasConnected = widget.isConnected;

                        try {
                          await widget.onRefresh();

                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                wasConnected
                                    ? 'Data refreshed!'
                                    : 'Fitbit connected!',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.isLoadingFitbit
                      ? 'Loading...'
                      : widget.isConnected
                      ? 'Refresh Fitbit Data'
                      : 'Connect Fitbit Data',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7C5CFA)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
