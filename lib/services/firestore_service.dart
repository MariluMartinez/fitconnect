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

  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .get();

    return query.docs
        .where((doc) => doc.id != currentUser.uid)
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> sendFriendRequest(String receiverUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final requestId = '${currentUser.uid}_$receiverUid';

    await _db.collection('friendRequests').doc(requestId).set({
      'fromUid': currentUser.uid,
      'toUid': receiverUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final query = await _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = <Map<String, dynamic>>[];

    for (final doc in query.docs) {
      final data = doc.data();
      final fromUid = data['fromUid'];

      final userDoc = await _db.collection('users').doc(fromUid).get();
      final userData = userDoc.data();

      requests.add({'requestId': doc.id, ...data, 'fromUser': userData});
    }

    return requests;
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final currentUid = currentUser.uid;

    final batch = _db.batch();

    final currentUserRef = _db.collection('users').doc(currentUid);
    final friendUserRef = _db.collection('users').doc(fromUid);
    final requestRef = _db.collection('friendRequests').doc(requestId);

    batch.update(currentUserRef, {
      'friends': FieldValue.arrayUnion([fromUid]),
    });

    batch.update(friendUserRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
    });

    batch.update(requestRef, {'status': 'accepted'});

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCurrentUserFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final currentUserDoc = await _db
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final data = currentUserDoc.data();

    if (data == null) return [];

    final friendIds = List<String>.from(data['friends'] ?? []);

    final friends = <Map<String, dynamic>>[];

    for (final friendId in friendIds) {
      final friendDoc = await _db.collection('users').doc(friendId).get();
      final friendData = friendDoc.data();

      if (friendData != null) {
        friends.add({'uid': friendDoc.id, ...friendData});
      }
    }

    return friends;
  }
}
