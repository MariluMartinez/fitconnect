class Event {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime;
  final String createdBy;
  final List<String> participants;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.dateTime,
    required this.createdBy,
    required this.participants,
  });

  // Convert from Firestore (Map → Event)
  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      dateTime: DateTime.parse(data['dateTime']),
      createdBy: data['createdBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  // Convert to Firestore (Event → Map)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'createdBy': createdBy,
      'participants': participants,
    };
  }
}