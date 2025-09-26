import 'package:flutter/material.dart';
import 'dart:ui';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notifications data
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Poll "Favorite Color" has closed',
      'message': 'Voting is now complete. Check the results!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
    },
    {
      'title': 'New poll available: "Best Programming Language"',
      'message': 'Cast your vote now!',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
    },
    {
      'title': 'Your vote was recorded',
      'message': 'Transaction confirmed for poll "Weekend Activity".',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
    },
  ];

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['read'] = true;
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: _notifications.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (ctx, i) {
                          final notif = _notifications[i];
                          return ListTile(
                            leading: Icon(
                              notif['read'] ? Icons.notifications_none : Icons.notifications,
                              color: notif['read'] ? Colors.white70 : Colors.white,
                            ),
                            title: Text(
                              notif['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: notif['read'] ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['message'],
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  '${notif['timestamp'].difference(DateTime.now()).inHours.abs()} hours ago',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: notif['read']
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.mark_as_unread, color: Colors.white),
                                    onPressed: () => _markAsRead(i),
                                  ),
                            onTap: () => _markAsRead(i),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}