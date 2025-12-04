import 'package:flutter/material.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  List<Map<String, String>> jadwalList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: jadwalList.isEmpty
          ? const Center(
              child: Text(
                "Belum ada jadwal",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              // ... (Copy logika ListView dari main.dart lama)
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text("Tambah"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.cyanAccent,
      ),
    );
  }

  void _showAddDialog() {
    // ... (Copy logika showDialog dari main.dart lama)
  }
}
