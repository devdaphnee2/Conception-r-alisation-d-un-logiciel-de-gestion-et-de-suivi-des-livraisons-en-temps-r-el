import 'package:flutter/material.dart';

class AppNotification {
  final IconData icon;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.icon,
    required this.title,
    required this.body,
    DateTime? time,
    this.isRead = false,
  }) : time = time ?? DateTime.now();

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

/// État global des notifications de l'app — alimenté en temps réel
/// (ex : arrivée du livreur depuis LiveTrackingScreen) et consommé
/// par la cloche de notifications de HomeScreen.
class NotificationState extends ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      icon: Icons.check_circle_outline,
      title: 'Commande #GE-902341 livrée',
      body: 'Votre colis a été livré avec succès',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
  ];

  List<AppNotification> get notifications => List.unmodifiable(_notifications.reversed);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void add({required IconData icon, required String title, required String body}) {
    _notifications.add(AppNotification(icon: icon, title: title, body: body));
    notifyListeners();
  }

  void remove(AppNotification n) {
    _notifications.remove(n);
    notifyListeners();
  }

  void markAsRead(AppNotification n) {
    n.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}