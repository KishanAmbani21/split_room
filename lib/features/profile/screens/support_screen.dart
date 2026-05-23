import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HelpTile(
            icon: Icons.group_add_rounded,
            title: 'Create or join groups',
            body:
                'Use Groups to create a room, add members, and track shared expenses.',
          ),
          _HelpTile(
            icon: Icons.receipt_long_rounded,
            title: 'Add expenses',
            body:
                'Add an expense from the home button or group details. Split equally or by custom amounts.',
          ),
          _HelpTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            body:
                'Members receive in-app and push notifications when group activity happens.',
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      contentPadding: EdgeInsets.zero,
    );
  }
}
