class Event {
  final String id;
  final String title;
  final String location;
  final String city;
  final String state; 
  final String eventType;
  final DateTime dateTime;
  final String createdBy;
  final List<String> participants;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.city,
    required this.state,
    required this.eventType,
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
      eventType: data['eventType'] ?? 'General',
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
      'eventType': eventType,
      'dateTime': dateTime.toIso8601String(),
      'createdBy': createdBy,
      'participants': participants,
    };
  }
}
