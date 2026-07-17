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
      id      : json['id'],
      message : json['message'] ?? '',
      isRead  : json['is_read'] == 1 || json['is_read'] == true,
      sentAt  : DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
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

  static const P = {
    'primary'      : Color(0xFF7d5700),
    'surface'      : Color(0xFFFFFFFF),
    'surfaceLow'   : Color(0xFFF3F3F3),
    'onSurface'    : Color(0xFF1a1c1c),
    'outline'      : Color(0xFF817564),
    'outlineVar'   : Color(0xFFD3C4B0),
    'error'        : Color(0xFFBA1A1A),
    'errorContainer': Color(0xFFFFDAD6),
    'primaryFixed' : Color(0xFFFFDEA9),
    'onPrimaryContainer': Color(0xFF483100),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final api      = ApiService(appState);
      final res      = await api.dio.get('/notifications');
      final List data = res.data ?? [];
      setState(() {
        _notifs  = data.map((j) => NotificationModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _supprimer(NotificationModel n) async {
    try {
      final appState = context.read<AppState>();
      final api      = ApiService(appState);
      await api.dio.delete('/notifications/${n.id}');
      setState(() => _notifs.removeWhere((x) => x.id == n.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _marquerLue(NotificationModel n) async {
    if (n.isRead) return;
    try {
      final appState = context.read<AppState>();
      final api      = ApiService(appState);
      await api.dio.patch('/notifications/${n.id}/lire');
      setState(() {
        final idx = _notifs.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifs[idx] = NotificationModel(
            id: n.id, message: n.message, isRead: true, sentAt: n.sentAt);
        }
      });
    } catch (_) {}
  }

  Future<void> _toutSupprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout supprimer ?'),
        content: const Text('Toutes les notifications seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final appState = context.read<AppState>();
      final api      = ApiService(appState);
      for (final n in List.from(_notifs)) {
        await api.dio.delete('/notifications/${n.id}');
      }
      setState(() => _notifs.clear());
    } catch (_) {}
  }

  String _formatDate(DateTime d) {
    final now  = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: P['surfaceLow'],
      appBar: AppBar(
        backgroundColor: P['surface'],
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_notifs.isNotEmpty)
            TextButton(
              onPressed: _toutSupprimer,
              child: Text('Tout supprimer',
                  style: TextStyle(color: P['error'], fontSize: 12, fontFamily: 'Poppins')),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            color: P['outline'],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: P['outlineVar']),
                  const SizedBox(height: 14),
                  Text('Aucune notification',
                      style: TextStyle(color: P['outline'], fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Les notifications apparaîtront ici.',
                      style: TextStyle(color: P['outlineVar'], fontSize: 12, fontFamily: 'Poppins')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _notifs.length,
                itemBuilder: (context, i) {
                  final n = _notifs[i];
                  return Dismissible(
                    key: Key('notif_${n.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: P['error'],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => _supprimer(n),
                    child: GestureDetector(
                      onTap: () => _marquerLue(n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead ? P['surface'] : P['primaryFixed'],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n.isRead ? P['outlineVar']! : P['onPrimaryContainer']!.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? P['surfaceLow']
                                    : P['onPrimaryContainer']!.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                n.isRead ? Icons.notifications_none : Icons.notifications_active,
                                size: 18,
                                color: n.isRead ? P['outline'] : P['onPrimaryContainer'],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                        fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                                        color: P['onSurface'],
                                      )),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 11, color: P['outline']),
                                      const SizedBox(width: 4),
                                      Text(_formatDate(n.sentAt),
                                          style: TextStyle(
                                              fontSize: 11, color: P['outline'], fontFamily: 'Poppins')),
                                      if (!n.isRead) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 6, height: 6,
                                          decoration: BoxDecoration(
                                            color: P['primary'], shape: BoxShape.circle),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 16, color: P['outline']),
                              onPressed: () => _supprimer(n),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}