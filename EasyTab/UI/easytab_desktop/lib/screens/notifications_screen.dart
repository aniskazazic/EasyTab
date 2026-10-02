import 'package:easytab_desktop/models/notification.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/notification_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/widgets/admin_sidebar.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        AuthProvider.isAdmin ||
        AuthProvider.accessTokenDecoded?['Role'] == 'Admin';

    return MasterScreen(
      title: 'Obavijesti',
      sidebar: isAdmin ? const AdminSidebar() : const OwnerSidebar(),
      child: DefaultTabController(
        length: isAdmin ? 2 : 1,
        child: Column(
          children: [
            Container(
              child: isAdmin
                  ? const TabBar(
                      labelColor: Color(0xFF1E40AF),
                      unselectedLabelColor: Color(0xFF1E40AF),
                      indicatorColor: Color(0xFF1E40AF),
                      tabs: [
                        Tab(text: 'Moje'),
                        Tab(text: 'Sve'),
                      ],
                    )
                  : const SizedBox(height: 8),
            ),
            Expanded(
              child: isAdmin
                  ? const TabBarView(
                      children: [_MyNotificationsTab(), _AllNotificationsTab()],
                    )
                  : const _MyNotificationsTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyNotificationsTab extends StatefulWidget {
  const _MyNotificationsTab();

  @override
  State<_MyNotificationsTab> createState() => _MyNotificationsTabState();
}

class _MyNotificationsTabState extends State<_MyNotificationsTab> {
  int _page = 0;
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().getMyNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, provider.notifications.length);
    final items = start < provider.notifications.length
        ? provider.notifications.sublist(start, end)
        : <AppNotification>[];

    return Column(
      children: [
        Expanded(
          child: provider.isLoading && provider.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _NotificationList(
                  items: items,
                  readOnly: false,
                  emptyText: 'Nema notifikacija.',
                ),
        ),
        PaginationUtils.buildPageControls(
          currentPage: _page,
          totalCount: provider.notifications.length,
          pageSize: _pageSize,
          onPageChanged: (page) => setState(() => _page = page),
        ),
      ],
    );
  }
}

class _AllNotificationsTab extends StatefulWidget {
  const _AllNotificationsTab();

  @override
  State<_AllNotificationsTab> createState() => _AllNotificationsTabState();
}

class _AllNotificationsTabState extends State<_AllNotificationsTab> {
  int _page = 0;
  int _totalCount = 0;
  bool _isLoading = false;
  List<AppNotification> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  Future<void> _loadPage() async {
    setState(() => _isLoading = true);
    try {
      final result = await context
          .read<NotificationProvider>()
          .getAllNotifications(page: _page);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalCount = result.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Greška pri učitavanju svih notifikacija: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _NotificationList(
                  items: _items,
                  readOnly: true,
                  emptyText: 'Nema notifikacija.',
                ),
        ),
        PaginationUtils.buildPageControls(
          currentPage: _page,
          totalCount: _totalCount,
          pageSize: 10,
          onPageChanged: (page) {
            setState(() => _page = page);
            _loadPage();
          },
        ),
      ],
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final bool readOnly;
  final String emptyText;

  const _NotificationList({
    required this.items,
    required this.readOnly,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyText));

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _NotificationTile(item: item, readOnly: readOnly);
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final bool readOnly;

  const _NotificationTile({required this.item, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final tile = ListTile(
      title: Text(item.title ?? 'Obavijest'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(item.message ?? ''),
          const SizedBox(height: 6),
          Text(
            item.createdAt == null
                ? ''
                : DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(item.createdAt!.toLocal()),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
      trailing: unread
          ? const Icon(Icons.circle, size: 10, color: Colors.blue)
          : null,
    );

    return Card(
      color: unread ? const Color(0xFFEFF6FF) : Colors.white,
      child: readOnly || item.id == null
          ? tile
          : InkWell(
              onTap: () =>
                  context.read<NotificationProvider>().markAsRead(item.id!),
              child: tile,
            ),
    );
  }
}
