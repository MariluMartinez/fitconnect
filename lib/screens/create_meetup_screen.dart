import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/google_places_service.dart';

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final EventService _eventService = EventService();
  final GooglePlacesService _placesService = GooglePlacesService();

  String _selectedEventType = 'Walk';

  bool _isSaving = false;
  DateTime? _selectedDateTime;

  List<AutocompletePrediction> _predictions = [];

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
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
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
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      eventType: _selectedEventType,
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
    _cityController.dispose();
    _stateController.dispose();
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
                labelText: 'Search location',
                hintText: 'Example: Ventura Pier',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) async {
                final results = await _placesService.searchPlaces(value);

                if (!mounted) return;

                setState(() {
                  _predictions = results;
                });
              },
            ),

            if (_predictions.isNotEmpty) ...[
              const SizedBox(height: 8),

              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];

                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(prediction.primaryText ?? ''),
                      subtitle: Text(prediction.secondaryText ?? ''),
                      onTap: () {
                        setState(() {
                          _locationController.text =
                              prediction.primaryText ?? '';
                          _predictions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Example: Ventura',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                hintText: 'Example: CA',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedEventType,
              decoration: const InputDecoration(
                labelText: 'Event type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Walk', child: Text('Walk')),
                DropdownMenuItem(value: 'Run', child: Text('Run')),
                DropdownMenuItem(value: 'Hike', child: Text('Hike')),
                DropdownMenuItem(value: 'Gym', child: Text('Gym')),
                DropdownMenuItem(value: 'Social', child: Text('Social')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedEventType = value;
                });
              },
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
