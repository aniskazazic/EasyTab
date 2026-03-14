import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:flutter/material.dart';

class LocaleListScreen extends StatefulWidget {
  const LocaleListScreen({super.key});

  @override
  State<LocaleListScreen> createState() => _LocaleListScreenState();
}

class _LocaleListScreenState extends State<LocaleListScreen> {
  @override
  Widget build(BuildContext context) {
    return const MasterScreen(
      title: 'Locale List',
      child: Center(child: Text('Locale List')),
    );
  }
}
