import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'meetup_details_screen.dart'; 

class MyMeetupsScreen extends StatelessWidget {
  const MyMeetupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your meetups.')),
      );
    }

    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Meetups')),
      body: StreamBuilder<List<Event>>(
        stream: eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load meetups.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          final created = events
              .where((event) => event.createdBy == user.uid)
              .toList();

          final joined = events
              .where(
                (event) =>
                    event.participants.contains(user.uid) &&
                    event.createdBy != user.uid,
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle(title: 'Created by Me'),
              if (created.isEmpty)
                const Text('You have not created any meetups yet.')
              else
                ...created.map((event) => _MeetupTile(event: event)),

              const SizedBox(height: 24),

              _SectionTitle(title: 'Joined'),
              if (joined.isEmpty)
                const Text('You have not joined any meetups yet.')
              else
                ...joined.map((event) => _MeetupTile(event: event)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MeetupTile extends StatelessWidget {
  final Event event;

  const _MeetupTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          '${event.location}\n${DateFormat('MMM d, y • h:mm a').format(event.dateTime)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetupDetailsScreen(event: event),
            ),
          );
        },
      ),
    );
  }
}