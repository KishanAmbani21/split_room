import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            'SplitRoom stores your profile, groups, members, expenses, notifications, and Firebase push token so shared expense features can work across members.',
          ),
          SizedBox(height: 12),
          Text(
            'Your expense and group data is only shown to authenticated members of the same group. Push tokens are used only for app notifications.',
          ),
          SizedBox(height: 12),
          Text(
            'To remove your data, delete groups/expenses from the app or contact the app owner.',
          ),
        ],
      ),
    );
  }
}
