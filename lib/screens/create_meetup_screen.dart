import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final EventService _eventService = EventService();

  bool _isSaving = false;
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveMeetup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (_titleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedDateTime == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final event = Event(
      id: '',
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      dateTime: _selectedDateTime!,
      createdBy: user.uid,
      participants: [user.uid],
    );

    await _eventService.createEvent(event);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Meetup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Meetup title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _selectedDateTime == null
                    ? 'Choose date and time'
                    : _selectedDateTime.toString().split('.').first,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeetup,
              child: Text(_isSaving ? 'Saving...' : 'Create Meetup'),
            ),
          ],
        ),
      ),
    );
  }
}
