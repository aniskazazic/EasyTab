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
  final Widget? sidebar;

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

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
                      if (canPop)
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      if (canPop) const SizedBox(width: 16),
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
