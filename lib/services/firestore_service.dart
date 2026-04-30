import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'publicName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoUrl': user.photoURL,
        'stepsGoal': 8000,
        'distanceGoal': 3.0,
        'activeMinutesGoal': 30,
        'sleepGoal': 8,
        'friends': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();

    return doc.data();
  }

  Future<void> updateUserGoals({
    required int stepsGoal,
    required double distanceGoal,
    required int activeMinutesGoal,
    required int sleepGoal,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'stepsGoal': stepsGoal,
      'distanceGoal': distanceGoal,
      'activeMinutesGoal': activeMinutesGoal,
      'sleepGoal': sleepGoal,
    });
  }
}
