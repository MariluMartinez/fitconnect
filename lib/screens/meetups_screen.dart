import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'create_meetup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MeetupsScreen extends StatefulWidget {
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  final EventService _eventService = EventService();

  final _searchAreaController = TextEditingController();
  String _selectedType = 'All';
  int _selectedRadius = 25;

  @override
  void dispose() {
    _searchAreaController.dispose();
    super.dispose();
  }

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

          final search = _searchAreaController.text.trim().toLowerCase();

          final filteredEvents = events.where((event) {
            final areaMatch =
                search.isEmpty ||
                event.city.toLowerCase().contains(search) ||
                event.state.toLowerCase().contains(search) ||
                '${event.city}, ${event.state}'.toLowerCase().contains(search);

            final typeMatch =
                _selectedType == 'All' || event.eventType == _selectedType;

            return areaMatch && typeMatch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchAreaController,
                      decoration: const InputDecoration(
                        labelText: 'Search Area',
                        hintText: 'City, State',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'Walk',
                                child: Text('Walk'),
                              ),
                              DropdownMenuItem(
                                value: 'Run',
                                child: Text('Run'),
                              ),
                              DropdownMenuItem(
                                value: 'Hike',
                                child: Text('Hike'),
                              ),
                              DropdownMenuItem(
                                value: 'Gym',
                                child: Text('Gym'),
                              ),
                              DropdownMenuItem(
                                value: 'Social',
                                child: Text('Social'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedRadius,
                            decoration: const InputDecoration(
                              labelText: 'Radius',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5 mi')),
                              DropdownMenuItem(value: 10, child: Text('10 mi')),
                              DropdownMenuItem(value: 25, child: Text('25 mi')),
                              DropdownMenuItem(value: 50, child: Text('50 mi')),
                              DropdownMenuItem(
                                value: 100,
                                child: Text('100 mi'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRadius = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredEvents.isEmpty
                    ? const Center(
                        child: Text('No meetups match your filters.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];

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
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${event.location}\n${event.city}, ${event.state}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.category_outlined,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(event.eventType),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                      ),
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
                                      const Icon(
                                        Icons.people_outline,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${event.participants.length} participant(s)',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;

                                        if (user == null) return;

                                        final alreadyJoined = event.participants
                                            .contains(user.uid);

                                        if (alreadyJoined) {
                                          await _eventService.leaveEvent(
                                            event.id,
                                            user.uid,
                                          );
                                        } else {
                                          await _eventService.joinEvent(
                                            event.id,
                                            user.uid,
                                          );
                                        }
                                      },
                                      child: Text(
                                        event.participants.contains(
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid,
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
                      ),
              ),
            ],
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
