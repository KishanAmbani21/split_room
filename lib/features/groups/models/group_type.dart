import 'package:flutter/material.dart';

enum GroupType {
  room('Room', Icons.home_work_outlined),
  friends('Friends', Icons.people_outline_rounded),
  trip('Trip', Icons.flight_takeoff_rounded),
  office('Office', Icons.business_center_outlined),
  other('Other', Icons.category_outlined);

  const GroupType(this.label, this.icon);

  final String label;
  final IconData icon;
}
