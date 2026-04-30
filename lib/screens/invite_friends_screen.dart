import 'package:flutter/material.dart';
import 'bingo_game_screen.dart';
import '../services/health_service.dart';

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
  final List<String> friends = ['Alex', 'Sam', 'Jordan', 'Taylor'];

  final Set<String> selectedFriends = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite Friends')),
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
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = selectedFriends.contains(friend);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(friend),
                    secondary: const CircleAvatar(child: Icon(Icons.person)),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedFriends.add(friend);
                        } else {
                          selectedFriends.remove(friend);
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
