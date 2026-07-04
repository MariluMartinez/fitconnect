import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class MeetupParticipantsScreen extends StatelessWidget {
  final List<String> participantIds;

  const MeetupParticipantsScreen({super.key, required this.participantIds});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: participantIds.isEmpty
          ? const Center(child: Text('No participants yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: participantIds.length,
              itemBuilder: (context, index) {
                final uid = participantIds[index];

                return FutureBuilder(
                  future: Future.wait([
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),

                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .get(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text('Loading...'),
                        ),
                      );
                    }

                    final participantDoc = snapshot.data![0];
                    final currentUserDoc = snapshot.data![1];

                    final participantData =
                        participantDoc.data() as Map<String, dynamic>?;

                    final currentUserData =
                        currentUserDoc.data() as Map<String, dynamic>?;

                    final name =
                        participantData?['publicName'] ??
                        participantData?['email'] ??
                        'Unknown User';

                    final friends = List<String>.from(
                      currentUserData?['friends'] ?? [],
                    );

                    final isMe = currentUser.uid == uid;
                    final isFriend = friends.contains(uid);

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),

                        title: Text(name),

                        trailing: isMe
                            ? const Text('You')
                            : isFriend
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check),
                                  SizedBox(width: 4),
                                  Text('Friend'),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  await FirestoreService().sendFriendRequest(
                                    uid,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Friend request sent'),
                                    ),
                                  );
                                },
                                child: const Text('Add'),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
