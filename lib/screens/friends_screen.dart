import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirestoreService firestoreService = FirestoreService();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadIncomingRequests();
  }

  Future<void> _loadFriends() async {
    final friends = await firestoreService.getCurrentUserFriends();

    if (!mounted) return;

    setState(() {
      _friends = friends;
    });
  }

  Future<void> _loadIncomingRequests() async {
    final requests = await firestoreService.getIncomingFriendRequests();

    if (!mounted) return;

    setState(() {
      _incomingRequests = requests;
    });
  }

  Future<void> _acceptFriendRequest(String requestId, String fromUid) async {
    await firestoreService.acceptFriendRequest(
      requestId: requestId,
      fromUid: fromUid,
    );

    await _loadIncomingRequests();
    await _loadFriends();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request accepted')));
  }

  Future<void> _showAddFriendDialog() async {
    await _loadFriends();

    final emailController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchUsers() async {
              final email = emailController.text.trim();

              if (email.isEmpty) return;

              setDialogState(() {
                isSearching = true;
              });

              final foundUsers = await firestoreService.searchUsersByEmail(
                email,
              );

              setDialogState(() {
                results = foundUsers;
                isSearching = false;
              });
            }

            Future<void> sendRequest(String uid) async {
              await firestoreService.sendFriendRequest(uid);

              if (!context.mounted) return;

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend request sent')),
              );
            }

            return AlertDialog(
              title: const Text('Add Friend'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Search by email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSearching ? null : searchUsers,
                        child: Text(isSearching ? 'Searching...' : 'Search'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (results.isEmpty)
                      const Text('No users found yet')
                    else
                      ...results.map((user) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(user['publicName'] ?? 'User'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing:
                              _friends.any(
                                (friend) => friend['uid'] == user['uid'],
                              )
                              ? const Icon(Icons.check, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () {
                                    sendRequest(user['uid']);
                                  },
                                  child: const Text('Add'),
                                ),
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRequests = _incomingRequests.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFriends();
          await _loadIncomingRequests();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hasRequests) ...[
              const Text(
                'Friend Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._incomingRequests.map((request) {
                final fromUser = request['fromUser'] as Map<String, dynamic>?;

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(fromUser?['publicName'] ?? 'User'),
                    subtitle: Text(fromUser?['email'] ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _acceptFriendRequest(
                          request['requestId'],
                          request['fromUid'],
                        );
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            const Text(
              'My Friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_friends.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('No friends yet. Tap + to add someone.'),
                ),
              )
            else
              ..._friends.map((friend) {
                final steps = friend['todaySteps'] ?? 0;

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(friend['publicName'] ?? 'User'),
                    subtitle: Text('$steps steps today'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
