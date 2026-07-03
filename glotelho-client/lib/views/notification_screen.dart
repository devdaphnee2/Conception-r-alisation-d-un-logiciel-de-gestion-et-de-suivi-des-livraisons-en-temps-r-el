import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';
import '../utils/constants.dart';
import '../utils/notification_state.dart';

/// Écran de notifications complet, style centre de notifications moderne.
/// Remplace le bottom sheet basique.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifState = context.watch<NotificationState>();
    final state = context.watch<AppState>();
    final isEn = state.language == 'English';

    final scaffoldBg = isDark ? const Color(0xFF0B0F17) : const Color(0xFFF2F4F7);
    final cardBg = isDark ? const Color(0xFF161D29) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final tabSelectedBg = isDark ? Colors.white : Colors.black87;
    final tabUnselectedBg = isDark ? const Color(0xFF1E2733) : Colors.white;
    final tabSelectedText = isDark ? Colors.black : Colors.white;
    final tabUnselectedText = isDark ? Colors.white54 : Colors.black54;

    final unread = notifState.unreadCount;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2733) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, size: 18, color: titleColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread ${isEn ? 'new' : 'nouveau${unread > 1 ? 'x' : ''}'}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  if (notifState.notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        notifState.markAllAsRead();
                        context.read<NotificationState>().clearAll();
                        setState(() {});
                      },
                      child: Text(
                        isEn ? 'Clear all' : 'Tout effacer',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            // ── Titre ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text(
                isEn ? 'Notifications' : 'Notifications',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),

            // ── Filtres tabs ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2733) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicator: BoxDecoration(
                    color: tabSelectedBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: tabSelectedText,
                  unselectedLabelColor: tabUnselectedText,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.notifications_outlined, size: 14, color: _tabController.index == 0 ? tabSelectedText : tabUnselectedText),
                        const SizedBox(width: 4),
                        Text(isEn ? 'All' : 'Tout'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.delivery_dining_outlined, size: 14, color: _tabController.index == 1 ? tabSelectedText : tabUnselectedText),
                        const SizedBox(width: 4),
                        Text(isEn ? 'Delivery' : 'Livraison'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.campaign_outlined, size: 14, color: _tabController.index == 2 ? tabSelectedText : tabUnselectedText),
                        const SizedBox(width: 4),
                        Text(isEn ? 'Promos' : 'Promos'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // ── Liste ────────────────────────────────────────────
            Expanded(
              child: notifState.notifications.isEmpty
                  ? _buildEmpty(isDark, titleColor, subColor, isEn)
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(notifState.notifications, cardBg, titleColor, subColor, isDark, notifState),
                  _buildList(
                    notifState.notifications.where((n) =>
                    n.icon == Icons.location_on || n.icon == Icons.delivery_dining || n.icon == Icons.check_circle_outline).toList(),
                    cardBg, titleColor, subColor, isDark, notifState,
                  ),
                  _buildList(
                    notifState.notifications.where((n) =>
                    n.icon == Icons.local_offer || n.icon == Icons.discount).toList(),
                    cardBg, titleColor, subColor, isDark, notifState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      List<AppNotification> items,
      Color cardBg,
      Color titleColor,
      Color subColor,
      bool isDark,
      NotificationState state,
      ) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 52, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucune notification', style: TextStyle(color: subColor, fontSize: 14)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final n = items[i];
        return _buildCard(n, cardBg, titleColor, subColor, isDark, state);
      },
    );
  }

  Widget _buildCard(
      AppNotification n,
      Color cardBg,
      Color titleColor,
      Color subColor,
      bool isDark,
      NotificationState state,
      ) {
    return Dismissible(
      key: ValueKey(n.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text('Dismiss', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
      onDismissed: (_) => state.remove(n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: !n.isRead ? (isDark ? const Color(0xFF1A2535) : const Color(0xFFFFF8EC)) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: !n.isRead
              ? Border.all(color: AppColors.gold.withOpacity(0.4), width: 1)
              : Border.all(color: Colors.transparent),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: !n.isRead ? AppColors.gold.withOpacity(0.15) : (isDark ? const Color(0xFF1E2733) : Colors.grey.shade100),
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, size: 22, color: !n.isRead ? AppColors.gold : (isDark ? Colors.white54 : Colors.grey)),
          ),
          title: Text(
            n.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: !n.isRead ? FontWeight.bold : FontWeight.w500,
              color: titleColor,
            ),
          ),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 3),
            Text(n.body, style: TextStyle(fontSize: 12, color: subColor, height: 1.4)),
            const SizedBox(height: 6),
            Text(n.timeAgo, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade400)),
          ]),
          onTap: () {
            state.markAsRead(n);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color titleColor, Color subColor, bool isEn) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_outlined, size: 36, color: isDark ? Colors.white24 : Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        Text(isEn ? 'No notifications yet' : 'Aucune notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
        const SizedBox(height: 8),
        Text(isEn ? 'You\'re all caught up!' : 'Tout est à jour !', style: TextStyle(fontSize: 13, color: subColor)),
      ]),
    );
  }
}