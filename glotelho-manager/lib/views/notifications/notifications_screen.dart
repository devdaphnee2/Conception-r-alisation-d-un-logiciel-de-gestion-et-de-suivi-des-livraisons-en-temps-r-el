import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../services/api_service.dart';

class NotificationModel {
  final int id;
  final String message;
  final bool isRead;
  final DateTime sentAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifs = [];
  bool _loading = true;

  static const Color redDot = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      final res = await api.dio.get('/notifications');
      final List data = res.data ?? [];
      setState(() {
        _notifs = data.map((j) => NotificationModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _supprimer(NotificationModel n) async {
    try {
      final appState = context.read<AppState>();
      final api = ApiService(appState);
      await api.dio.delete('/notifications/${n.id}');
      setState(() => _notifs.removeWhere((x) => x.id == n.id));
    } catch (_) {}
  }

  Future<void> _toutEffacer() async {
    if (_notifs.isEmpty) return;

    final appState = context.read<AppState>();
    final isDark = appState.isDarkTheme;

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2A4A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tout effacer ?',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Toutes les notifications seront supprimées.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: redDot),
            child: const Text('Effacer tout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmer != true) return;

    try {
      final api = ApiService(appState);
      for (final n in List.from(_notifs)) {
        await api.dio.delete('/notifications/${n.id}');
      }
      setState(() => _notifs.clear());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkTheme;

    // Palette dynamique
    final bgColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFFAF7F2);
    final cardUnreadColor = isDark ? const Color(0xFF1B2A4A) : const Color(0xFFF2ECE1);
    final textColor = isDark ? Colors.white : const Color(0xFF1D1B1E);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF79747E);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (_notifs.isNotEmpty)
                    TextButton.icon(
                      onPressed: _toutEffacer,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: redDot),
                      label: const Text('Tout effacer', style: TextStyle(color: redDot)),
                    ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: textColor),
                    onPressed: _load,
                  ),
                ],
              ),
            ),

            // --- LISTE / ÉTAT VIDE ---
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: isDark ? Colors.amber : Colors.black))
                  : _notifs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 56, color: textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune notification',
                      style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _notifs.length,
                itemBuilder: (context, index) {
                  final n = _notifs[index];
                  return Container(
                    color: n.isRead ? Colors.transparent : cardUnreadColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.message,
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: redDot, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}