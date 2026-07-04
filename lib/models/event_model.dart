class Event {
  final String id;
  final String title;
  final String location;
  final String city;
  final String state; 
  final double latitude;
  final double longitude;
  final String eventType;
  final String difficulty; 
  final String description; 
  final DateTime dateTime;
  final String createdBy;
  final List<String> participants;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.eventType,
    required this.difficulty,
    required this.description,
    required this.dateTime,
    required this.createdBy,
    required this.participants,
  });

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      eventType: data['eventType'] ?? 'General',
      difficulty: data['difficulty'] ??  'Any Level', 
      description: data['description'] ?? '',
      dateTime: DateTime.parse(data['dateTime']),
      createdBy: data['createdBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'eventType': eventType,
      'difficulty': difficulty,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'createdBy': createdBy,
      'participants': participants,
    };
  }
}
