import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int stepsGoal;
  final double distanceGoal;
  final int activeMinutesGoal;
  final int sleepGoal;
  final Future<void> Function(int, double, int, int) onSave;

  const ProfileScreen({
    super.key,
    required this.stepsGoal,
    required this.distanceGoal,
    required this.activeMinutesGoal,
    required this.sleepGoal,
    required this.onSave,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String publicName = 'User';
  String email = '';

  late final TextEditingController stepsController;
  late final TextEditingController distanceController;
  late final TextEditingController activeMinutesController;
  late final TextEditingController sleepController;

  @override
  void initState() {
    super.initState();

    _loadUserInfo();

    stepsController = TextEditingController(text: widget.stepsGoal.toString());
    distanceController = TextEditingController(
      text: widget.distanceGoal.toStringAsFixed(1),
    );
    activeMinutesController = TextEditingController(
      text: widget.activeMinutesGoal.toString(),
    );
    sleepController = TextEditingController(text: widget.sleepGoal.toString());
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      publicName = doc.data()?['publicName'] ?? user.displayName ?? 'User';
      email = user.email ?? doc.data()?['email'] ?? '';
    });
  }

  @override
  void dispose() {
    stepsController.dispose();
    distanceController.dispose();
    activeMinutesController.dispose();
    sleepController.dispose();
    super.dispose();
  }

  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF7C5CFA),
                      child: Text(
                        publicName.isNotEmpty
                            ? publicName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            publicName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Fitness Goals',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int>(
                value: int.tryParse(stepsController.text) ?? 8000,
                items: List.generate(101, (index) => index * 500)
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    stepsController.text = value.toString();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Daily Steps Goal',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<double>(
                value: double.tryParse(distanceController.text) ?? 3.0,
                items: List.generate(61, (index) => index * 0.5)
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.toStringAsFixed(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    distanceController.text = value!.toStringAsFixed(1);
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Distance Goal (miles)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            _buildField('Active Minutes Goal', activeMinutesController),
            _buildField('Sleep Goal (hours)', sleepController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final steps =
                    int.tryParse(stepsController.text) ?? widget.stepsGoal;
                final distance =
                    double.tryParse(distanceController.text) ??
                    widget.distanceGoal;
                final activeMinutes =
                    int.tryParse(activeMinutesController.text) ??
                    widget.activeMinutesGoal;
                final sleep =
                    int.tryParse(sleepController.text) ?? widget.sleepGoal;

                await widget.onSave(steps, distance, activeMinutes, sleep);

                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Goals saved!')));
              },
              child: const Text('Save Goals'),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _logOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Log Out', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
