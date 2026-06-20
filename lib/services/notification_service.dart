import 'dart:async';
import '../models/notification_item.dart';

class NotificationService {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Breaking News: Water Found on Mars',
      body: 'NASA Rover Curiosity finds definitive evidence of liquid water flows underneath Gale Crater.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationItem(
      id: 'n2',
      title: 'Falcon 9 Launch Successful',
      body: 'SpaceX completes its 50th launch of the year, carrying 22 Starlink satellites to orbit.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationItem(
      id: 'n3',
      title: 'Artemis Crew Finalized',
      body: 'NASA announces the four astronauts selected for the historic lunar orbit mission.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    NotificationItem(
      id: 'n4',
      title: 'Supernova Captured in Real-Time',
      body: 'James Webb Space Telescope captures high-resolution images of a supernova explosion in a neighboring galaxy.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: 'n5',
      title: 'Welcome to SpaceNews Core',
      body: 'Thank you for signing up. Enjoy advanced international news portal access, save favorites, and explore the universe!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<List<NotificationItem>> getNotifications() async {
    // Return sorted by timestamp descending
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.from(_notifications);
  }
}
