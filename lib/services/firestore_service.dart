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

  Future<void> updateTodayActivity({
    required int steps,
    required double distanceMiles,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'todaySteps': steps,
      'todayDistanceMiles': distanceMiles,
      'activityLastSync': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getFriendsLeaderboard() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final currentUserDoc = await _db
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final currentUserData = currentUserDoc.data();

    if (currentUserData == null) return [];

    final friendIds = List<String>.from(currentUserData['friends'] ?? []);

    final leaderboard = <Map<String, dynamic>>[
      {'uid': currentUser.uid, ...currentUserData, 'isCurrentUser': true},
    ];

    for (final friendId in friendIds) {
      final friendDoc = await _db.collection('users').doc(friendId).get();
      final friendData = friendDoc.data();

      if (friendData != null) {
        leaderboard.add({
          'uid': friendDoc.id,
          ...friendData,
          'isCurrentUser': false,
        });
      }
    }

    leaderboard.sort((a, b) {
      final aSteps = a['todaySteps'] ?? 0;
      final bSteps = b['todaySteps'] ?? 0;
      return bSteps.compareTo(aSteps);
    });

    return leaderboard;
  }

  Future<void> removeFriend(String friendUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final currentUid = currentUser.uid;

    final batch = _db.batch();

    final currentUserRef = _db.collection('users').doc(currentUid);
    final friendRef = _db.collection('users').doc(friendUid);

    final requestOneRef = _db
        .collection('friendRequests')
        .doc('${currentUid}_$friendUid');
    final requestTwoRef = _db
        .collection('friendRequests')
        .doc('${friendUid}_$currentUid');

    batch.update(currentUserRef, {
      'friends': FieldValue.arrayRemove([friendUid]),
    });

    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([currentUid]),
    });

    batch.delete(requestOneRef);
    batch.delete(requestTwoRef);

    await batch.commit();
  }

  Future<int> getIncomingFriendRequestCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return 0;

    final query = await _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return query.docs.length;
  }

  Future<List<Map<String, dynamic>>> getOutgoingFriendRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final query = await _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = <Map<String, dynamic>>[];

    for (final doc in query.docs) {
      final data = doc.data();
      final toUid = data['toUid'];

      final userDoc = await _db.collection('users').doc(toUid).get();
      final userData = userDoc.data();

      requests.add({'requestId': doc.id, ...data, 'toUser': userData});
    }

    return requests;
  }

  Future<void> createChallenge({
    required String type,
    required List<String> playerUids,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    await _db.collection('challenges').add({
      'type': type,
      'status': 'pending',
      'createdBy': currentUser.uid,
      'players': [currentUser.uid, ...playerUids],
      'acceptedPlayers': [currentUser.uid],
      'pendingPlayers': playerUids,
      'declinedPlayers': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptChallenge(String challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final challengeRef = _db.collection('challenges').doc(challengeId);

    await challengeRef.update({
      'acceptedPlayers': FieldValue.arrayUnion([currentUser.uid]),
      'pendingPlayers': FieldValue.arrayRemove([currentUser.uid]),
      'status': 'active',
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final challengeRef = _db.collection('challenges').doc(challengeId);

    await challengeRef.update({
      'declinedPlayers': FieldValue.arrayUnion([currentUser.uid]),
      'pendingPlayers': FieldValue.arrayRemove([currentUser.uid]),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingChallenges() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final query = await _db
        .collection('challenges')
        .where('pendingPlayers', arrayContains: currentUser.uid)
        .get();

    return query.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCurrentChallenges() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return [];

    final query = await _db
        .collection('challenges')
        .where('acceptedPlayers', arrayContains: currentUser.uid)
        .get();

    return query.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> saveBingoCompletedSquares({
    required String challengeId,
    required List<int> completedSquares,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || challengeId.isEmpty) return;

    await _db.collection('challenges').doc(challengeId).set({
      'bingoProgress': {currentUser.uid: completedSquares},
    }, SetOptions(merge: true));
  }

  Future<List<int>> getBingoCompletedSquares(String challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || challengeId.isEmpty) return [];

    final doc = await _db.collection('challenges').doc(challengeId).get();
    final data = doc.data();

    final bingoProgress = data?['bingoProgress'] as Map<String, dynamic>?;

    if (bingoProgress == null) return [];

    final userSquares = bingoProgress[currentUser.uid];

    if (userSquares == null) return [];

    return List<int>.from(userSquares);
  }

  Future<void> saveBingoBoard({
    required String challengeId,
    required List<Map<String, dynamic>> board,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || challengeId.isEmpty) return;

    await _db.collection('challenges').doc(challengeId).set({
      'bingoBoards': {currentUser.uid: board},
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>?> getBingoBoard(String challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || challengeId.isEmpty) return null;

    final doc = await _db.collection('challenges').doc(challengeId).get();
    final data = doc.data();

    if (data == null) return null;

    final boards = data['bingoBoards'] as Map<String, dynamic>?;

    if (boards == null) return null;

    final board = boards[currentUser.uid];

    if (board == null) return null;

    return List<Map<String, dynamic>>.from(board);
  }

  Future<Map<String, List<int>>> getBingoProgressForChallenge(
    String challengeId,
  ) async {
    if (challengeId.isEmpty) return {};

    final doc = await _db.collection('challenges').doc(challengeId).get();
    final data = doc.data();

    if (data == null) return {};

    final bingoProgress = data['bingoProgress'] as Map<String, dynamic>?;

    if (bingoProgress == null) return {};

    final progress = <String, List<int>>{};

    bingoProgress.forEach((uid, squares) {
      progress[uid] = List<int>.from(squares);
    });

    return progress;
  }
}
