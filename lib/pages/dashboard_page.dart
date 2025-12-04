import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

// Import Tab yang sudah dipisah tadi
import 'monitoring_tab.dart';
import 'controlling_tab.dart';
import 'schedule_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late MqttBrowserClient client;
  bool isConnected = false;
  double suhuAir = 0;
  List<FlSpot> dataGrafik = [];
  double waktuGrafik = 0;

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  // ... (Copy fungsi connectMQTT, simpanKeDatabase, dan kirimPerintah dari main.dart lama ke sini) ...

  @override
  Widget build(BuildContext context) {
    // List halaman dipanggil di sini
    final List<Widget> pages = [
      // Tab 1: Monitoring (Kirim data suhu ke widget anak)
      MonitoringTab(suhuAir: suhuAir, dataGrafik: dataGrafik),

      // Tab 2: Controlling (Kirim fungsi kirimPerintah ke widget anak)
      ControllingTab(onCommand: (cmd) => kirimPerintah(cmd)),

      // Tab 3: Jadwal
      const ScheduleTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fish It Dashboard"),
        actions: [
          // ... (Indikator Online/Offline) ...
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: pages[_selectedIndex], // Tampilkan halaman sesuai index
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: "Monitoring",
          ),
          NavigationDestination(
            icon: Icon(Icons.gamepad),
            label: "Controlling",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: "Jadwal",
          ),
        ],
      ),
    );
  }
}
