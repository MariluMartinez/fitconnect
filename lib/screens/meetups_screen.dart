import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'create_meetup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MeetupsScreen extends StatelessWidget {
  MeetupsScreen({super.key});

  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Meetups')),
      body: StreamBuilder<List<Event>>(
        stream: _eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong loading meetups.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text('No meetups yet. Create the first meetup!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event.location)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'MMM d, y • h:mm a',
                            ).format(event.dateTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 18),
                          const SizedBox(width: 6),
                          Text('${event.participants.length} participant(s)'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;

                            if (user == null) return;

                            final alreadyJoined = event.participants.contains(
                              user.uid,
                            );

                            if (alreadyJoined) {
                              await _eventService.leaveEvent(
                                event.id,
                                user.uid,
                              );
                            } else {
                              await _eventService.joinEvent(event.id, user.uid);
                            }
                          },
                          child: Text(
                            event.participants.contains(
                                  FirebaseAuth.instance.currentUser?.uid,
                                )
                                ? 'Leave'
                                : 'Join',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMeetupScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
