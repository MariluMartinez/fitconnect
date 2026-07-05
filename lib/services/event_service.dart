import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsCollection => _firestore.collection('events');

  Future<String> createEvent(Event event) async {
    final doc = await _eventsCollection.add(event.toMap());

    return doc.id;
  }

  Stream<List<Event>> getEvents() {
    return _eventsCollection.orderBy('dateTime').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> joinEvent(String eventId, String userId) async {
    await _eventsCollection.doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    await _eventsCollection.doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> updateEvent(Event event) async {
    await _eventsCollection.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }
}
