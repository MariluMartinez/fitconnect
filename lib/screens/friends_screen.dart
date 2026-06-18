import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback? onFriendRequestsChanged;

  const FriendsScreen({super.key, this.onFriendRequestsChanged});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirestoreService firestoreService = FirestoreService();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadIncomingRequests();
    _loadOutgoingRequests();
    _loadLeaderboard();
  }

  Future<void> _loadFriends() async {
    final friends = await firestoreService.getCurrentUserFriends();

    if (!mounted) return;

    setState(() {
      _friends = friends;
    });
  }

  Future<void> _loadLeaderboard() async {
    final leaderboard = await firestoreService.getFriendsLeaderboard();

    if (!mounted) return;

    setState(() {
      _leaderboard = leaderboard;
    });
  }

  Future<void> _loadIncomingRequests() async {
    final requests = await firestoreService.getIncomingFriendRequests();

    if (!mounted) return;

    setState(() {
      _incomingRequests = requests;
    });
  }

  Future<void> _loadOutgoingRequests() async {
    final requests = await firestoreService.getOutgoingFriendRequests();

    if (!mounted) return;

    setState(() {
      _outgoingRequests = requests;
    });
  }

  Future<void> _acceptFriendRequest(String requestId, String fromUid) async {
    await firestoreService.acceptFriendRequest(
      requestId: requestId,
      fromUid: fromUid,
    );

    await _loadIncomingRequests();
    await _loadFriends();
    await _loadLeaderboard();

    widget.onFriendRequestsChanged?.call();

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
              await _loadOutgoingRequests();

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

  Widget _buildUserAvatar(Map<String, dynamic> user, String fallbackText) {
    final photoUrl = user['photoUrl'];

    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(photoUrl));
    }

    return CircleAvatar(child: Text(fallbackText));
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
          await _loadOutgoingRequests();
          await _loadLeaderboard();
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
            if (_outgoingRequests.isNotEmpty) ...[
              const Text(
                'Sent Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._outgoingRequests.map((request) {
                final toUser = request['toUser'] as Map<String, dynamic>?;

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.hourglass_empty),
                    ),
                    title: Text(toUser?['publicName'] ?? 'User'),
                    subtitle: const Text('Pending'),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            if (_leaderboard.isNotEmpty) ...[
              const Text(
                'Friends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._leaderboard.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final steps = user['todaySteps'] ?? 0;
                final goal = user['stepsGoal'] ?? 8000;
                final isCurrentUser = user['isCurrentUser'] == true;

                final rankIcon = index == 0
                    ? '🥇'
                    : index == 1
                    ? '🥈'
                    : index == 2
                    ? '🥉'
                    : '${index + 1}';

                return Card(
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildUserAvatar(user, rankIcon),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: CircleAvatar(
                            radius: 10,
                            child: Text(
                              rankIcon,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      isCurrentUser
                          ? '${user['publicName'] ?? 'You'} (You)'
                          : user['publicName'] ?? 'User',
                    ),
                    subtitle: Text('$steps / $goal steps'),
                    trailing: isCurrentUser
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'remove') {
                                _removeFriend(
                                  user['uid'],
                                  user['publicName'] ?? 'User',
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove Friend'),
                              ),
                            ],
                          ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeFriend(String friendUid, String friendName) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove $friendName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    await firestoreService.removeFriend(friendUid);

    await _loadFriends();
    await _loadLeaderboard();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend removed')));
  }
}
