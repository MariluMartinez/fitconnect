import 'package:flutter/material.dart';
import 'bingo_game_screen.dart';
import '../services/health_service.dart';
import '../services/firestore_service.dart';

class InviteFriendsScreen extends StatefulWidget {
  final String challengeName;
  final HealthSnapshot? snapshot;

  const InviteFriendsScreen({
    super.key,
    required this.challengeName,
    required this.snapshot,
  });

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final FirestoreService firestoreService = FirestoreService();

  List<Map<String, dynamic>> friends = [];

  final Set<String> selectedFriends = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final loadedFriends = await firestoreService.getCurrentUserFriends();

    if (!mounted) return;

    setState(() {
      friends = loadedFriends;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.challengeName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Choose friends to invite to this challenge.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: friends.isEmpty
                  ? const Center(
                      child: Text('Add friends before starting a challenge.'),
                    )
                  : ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];

                        final uid = friend['uid'];

                        final name = friend['publicName'] ?? 'User';

                        final isSelected = selectedFriends.contains(uid);

                        return CheckboxListTile(
                          value: isSelected,

                          title: Text(name),

                          subtitle: Text(friend['email'] ?? ''),

                          secondary: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),

                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedFriends.add(uid);
                              } else {
                                selectedFriends.remove(uid);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: selectedFriends.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BingoGameScreen(
                              invitedFriends: selectedFriends.toList(),
                              snapshot: widget.snapshot,
                              challengeId: '',
                            ),
                          ),
                        );
                      },

                child: const Text('Start Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
