import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/difficulty_utils.dart';
import '../models/event_model.dart';

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
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.directions),
            label: const Text("Directions"),
          ),
        ],
      ),
    );
  }
}
