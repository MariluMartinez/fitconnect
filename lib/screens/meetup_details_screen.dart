import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/difficulty_utils.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/notifications_service.dart';
import 'create_meetup_screen.dart';
import 'meetup_participants_screen.dart';

class MeetupDetailsScreen extends StatelessWidget {
  final Event event;

  const MeetupDetailsScreen({super.key, required this.event});

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == event.createdBy;

    return Scaffold(
      appBar: AppBar(title: const Text('Meetup Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            event.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(event.location),
            subtitle: Text("${event.city}, ${event.state}"),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(event.eventType),
          ),
          ListTile(
            leading: difficultyDot(event.difficulty, size: 16),
            title: Text(event.difficulty),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              DateFormat('MMMM d, y • h:mm a').format(event.dateTime),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text("${event.participants.length} participant(s)"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetupParticipantsScreen(
                    participantIds: event.participants,
                  ),
                ),
              );
            },
          ),
          if (event.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(event.description),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.directions),
            label: const Text("Directions"),
          ),
          if (isCreator) ...[
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateMeetupScreen(existingEvent: event),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Meetup'),
            ),

            const SizedBox(height: 8),

            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Meetup?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await NotificationService.cancelReminder(event.id.hashCode);

                await EventService().deleteEvent(event.id);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Meetup'),
            ),
          ],
        ],
      ),
    );
  }
}
