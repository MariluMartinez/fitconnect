import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'games_screen.dart';
import 'meetups_screen.dart';
import 'profile_screen.dart';
import '../services/health_service.dart';
import '../services/fitbit_health_service.dart';
import '../services/firestore_service.dart';
import 'friends_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _friendRequestCount = 0;

  final FitbitHealthService fitbitHealthService = FitbitHealthService();
  final FirestoreService firestoreService = FirestoreService();

  HealthSnapshot? _snapshot;
  bool _isConnected = false;
  bool _isLoadingFitbit = false;

  int stepsGoal = 8000;
  double distanceGoal = 3.0;
  int activeMinutesGoal = 30;
  int sleepGoal = 8;

  Future<void> _loadFitbitData() async {
    try {
      setState(() {
        _isLoadingFitbit = true;
      });

      final snapshot = _isConnected
          ? await fitbitHealthService.fetchTodayData()
          : await fitbitHealthService.connect();

      if (snapshot != null && mounted) {
        await firestoreService.updateTodayActivity(
          steps: snapshot.steps,
          distanceMiles: snapshot.distanceMiles,
        );

        setState(() {
          _snapshot = snapshot;
          _isConnected = true;
        });
      }
    } catch (e) {
      print('Main navigation Fitbit load failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFitbit = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
    _loadFriendRequestCount();
  }

  Future<void> _loadUserGoals() async {
    final profile = await firestoreService.getCurrentUserProfile();

    if (profile == null || !mounted) return;

    setState(() {
      stepsGoal = profile['stepsGoal'] ?? 8000;
      distanceGoal = (profile['distanceGoal'] ?? 3.0).toDouble();
      activeMinutesGoal = profile['activeMinutesGoal'] ?? 30;
      sleepGoal = profile['sleepGoal'] ?? 8;
    });
  }

  Future<void> _loadFriendRequestCount() async {
    final count = await firestoreService.getIncomingFriendRequestCount();

    if (!mounted) return;

    setState(() {
      _friendRequestCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        snapshot: _snapshot,
        stepsGoal: stepsGoal,
        distanceGoal: distanceGoal,
        isConnected: _isConnected,
        isLoadingFitbit: _isLoadingFitbit,
        onRefresh: _loadFitbitData,
      ),
      GamesScreen(
        snapshot: _snapshot,
        stepsGoal: stepsGoal,
        distanceGoal: distanceGoal,
        activeMinutesGoal: activeMinutesGoal,
      ),
      MeetupsScreen(),
      const FriendsScreen(),
      ProfileScreen(
        stepsGoal: stepsGoal,
        distanceGoal: distanceGoal,
        activeMinutesGoal: activeMinutesGoal,
        sleepGoal: sleepGoal,
        onSave: (newSteps, newDistance, newMinutes, newSleep) async {
          setState(() {
            stepsGoal = newSteps;
            distanceGoal = newDistance;
            activeMinutesGoal = newMinutes;
            sleepGoal = newSleep;
          });

          await firestoreService.updateUserGoals(
            stepsGoal: newSteps,
            distanceGoal: newDistance,
            activeMinutesGoal: newMinutes,
            sleepGoal: newSleep,
          );
        },
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7C5CFA),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Meetups',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.people_outline),
                if (_friendRequestCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: CircleAvatar(
                      radius: 8,
                      child: Text(
                        '$_friendRequestCount',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
