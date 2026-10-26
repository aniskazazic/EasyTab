import 'package:easytab_mobile/models/notification.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/notification_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationProvider _notificationProvider;
  bool _onlyUnread = false;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _notificationProvider = context.read<NotificationProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    if (AuthProvider.currentUserId != null) {
      await _notificationProvider.getNotifications();
    }
  }

  Future<void> _markRead([int? id]) async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      final success = id == null
          ? await _notificationProvider.markAllAsRead()
          : await _notificationProvider.markAsRead(id);
      if (mounted) {
        showFeedback(
          context,
          success
              ? (id == null
                    ? 'Sve obavijesti su označene kao pročitane.'
                    : 'Obavijest je označena kao pročitana.')
              : _notificationProvider.error ?? 'Označavanje nije uspjelo.',
          error: !success,
        );
      }
    } catch (e) {
      if (mounted) showFeedback(context, userError(e), error: true);
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications
        .where((item) => !_onlyUnread || item.isRead != true)
        .toList();
    final unreadCount = provider.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Obavijesti',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _marking ? null : () => _markRead(),
              child: const Text(
                'Označi sve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          FilterChip(
            label: const Text('Samo nepročitane'),
            selected: _onlyUnread,
            onSelected: (value) => setState(() => _onlyUnread = value),
          ),
          if (_marking) const LinearProgressIndicator(),
          if (provider.error != null && provider.notifications.isNotEmpty)
            ListTile(
              title: Text(provider.error!),
              trailing: TextButton(
                onPressed: _loadNotifications,
                child: const Text('Ponovi'),
              ),
            ),
          Expanded(
            child: provider.isLoading && notifications.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                  )
                : provider.error != null && notifications.isEmpty
                ? _buildErrorView(provider.error!)
                : notifications.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    color: const Color(0xFF1E40AF),
                    onRefresh: _loadNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return _buildNotificationCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    final isUnread = item.isRead == false;
    final dateFormatted = _formatDate(item.createdAt);

    return InkWell(
      onTap: isUnread && item.id != null && !_marking
          ? () => _markRead(item.id!)
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title ?? 'Obavijest',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Text(
              isUnread
                  ? 'Dodirnite za označavanje kao pročitano.'
                  : 'Pročitano',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              item.message ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isUnread
                    ? const Color(0xFF334155)
                    : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateFormatted,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = toLocalDateTime(dt);
    final now = DateTime.now();

    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Upravo sada';
    if (diff.inMinutes < 60) return 'Prije ${diff.inMinutes} min';
    if (DateUtils.isSameDay(now, local)) {
      return 'Danas u ${DateFormat('HH:mm').format(local)}';
    }
    if (DateUtils.isSameDay(
      local,
      DateTime(now.year, now.month, now.day - 1),
    )) {
      return 'Jučer u ${DateFormat('HH:mm').format(local)}';
    }

    return DateFormat('dd.MM.yyyy · HH:mm').format(local);
  }

  Widget _buildEmptyView() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _onlyUnread
                    ? 'Nema obavijesti za odabrane kriterije.'
                    : 'Nemate obavijesti',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sve važne informacije o vašim rezervacijama prikazivat će se ovdje.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 14),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                ),
                child: const Text(
                  'Pokušaj ponovo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
