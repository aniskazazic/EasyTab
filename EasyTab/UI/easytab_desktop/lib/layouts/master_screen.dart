import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/widgets/admin_sidebar.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:easytab_desktop/providers/notification_provider.dart';
import 'package:easytab_desktop/screens/notifications_screen.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({
    super.key,
    required this.child,
    required this.title,
    this.padding = const EdgeInsets.all(24.0),
    this.sidebar,
  });
  final Widget child;
  final String title;
  final EdgeInsets padding;

  /// Ako je null, u admin shellu se sidebar ne crta (jedan sidebar u [AdminShellScreen]).
  final Widget? sidebar;

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  Future<void> _onBackPressed() async {
    final navigator = Navigator.of(context);
    final didPop = await navigator.maybePop();
    if (!didPop && mounted && widget.title != 'Dashboard') {
      // ← provjeri rolu pa navigiraj na pravi dashboard
      final destination = AuthProvider.accessTokenDecoded?['Role'] == 'Admin'
          ? '/dashboard'
          : '/owner-dashboard';
      navigator.pushReplacementNamed(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    // Kao kod owner ekrana: "Nazad" ili zatvara pushani ekran (detalji) ili
    // vodi na dashboard umjesto praznog/crnog ekrana kad nema routea ispod.
    final canPop = Navigator.canPop(context);
    final showBack = canPop || widget.title != 'Dashboard';

    return Scaffold(
      body: Row(
        children: [
          widget.sidebar ??
              (AuthProvider.accessTokenDecoded?['Role'] == 'Admin'
                  ? const AdminSidebar()
                  : const OwnerSidebar()),
          Expanded(
            child: Padding(
              padding: widget.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nazad dugme + naslov u istom redu
                  Row(
                    children: [
                      if (showBack)
                        TextButton.icon(
                          onPressed: _onBackPressed,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      if (showBack) const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.title == 'Postavke')
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              tooltip: 'Obavijesti',
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
