import 'package:flutter/material.dart';
import 'package:easytab_desktop/widgets/admin_sidebar.dart';

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
      navigator.pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kao kod owner ekrana: "Nazad" ili zatvara pushani ekran (detalji) ili
    // vodi na dashboard umjesto praznog/crnog ekrana kad nema routea ispod.
    final canPop = Navigator.canPop(context);
    final showBack = canPop || widget.title != 'Dashboard';

    return Scaffold(
      body: Row(
        children: [
          widget.sidebar ?? const AdminSidebar(),
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
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
