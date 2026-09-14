import 'package:easytab_mobile/screens/settings_user_screen.dart';
import 'package:easytab_mobile/screens/worker_home_screen.dart';
import 'package:flutter/material.dart';

class WorkerMasterScreen extends StatefulWidget {
  const WorkerMasterScreen({super.key});

  @override
  State<WorkerMasterScreen> createState() => _WorkerMasterScreenState();
}

class _WorkerMasterScreenState extends State<WorkerMasterScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1E40AF),
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 8,
              16,
              12,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EasyTab',
                      style: TextStyle(fontSize: 26, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.table_restaurant, color: Colors.white, size: 30),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [WorkerHomeScreen(), SettingsUserScreen()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1E40AF),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Rezervacije',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Postavke',
          ),
        ],
      ),
    );
  }
}
