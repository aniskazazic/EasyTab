import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart';

class LocaleDetailsScreen extends StatefulWidget {
  final Locale? locale;

  const LocaleDetailsScreen({super.key, this.locale});

  @override
  State<LocaleDetailsScreen> createState() => _LocaleDetailsScreen();
}

class _LocaleDetailsScreen extends State<LocaleDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Locale Details",
      child: Center(
        child: Text(widget.locale?.name ?? ""),
      )
    );
  }
}
