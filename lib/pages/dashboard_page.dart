import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import Halaman Lain
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

  // Variabel MQTT
  late MqttClient client;
  bool isConnected = false;

  // Data Sensor
  double suhuAir = 0;
  List<FlSpot> dataGrafik = [];
  double waktuGrafik = 0;

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  Future<void> connectMQTT() async {
    // Setup Client sesuai platform (Web atau HP)
    if (kIsWeb) {
      client = MqttBrowserClient(
        'ws://broker.emqx.io/mqtt',
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      );
      (client as MqttBrowserClient).port = 8083;
    } else {
      client = MqttServerClient(
        'broker.emqx.io',
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      );
      client.port = 1883;
    }

    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_fish_it_id')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        isConnected = true;
      });
      print('MQTT Connected');

      // Subscribe ke topik suhu
      client.subscribe("ikan/monitor/suhu", MqttQos.atMostOnce);

      // Mendengarkan pesan masuk
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        print('Topik: ${c[0].topic}, Pesan: $pt');

        if (c[0].topic == "ikan/monitor/suhu") {
          double? suhuBaru = double.tryParse(pt);
          if (suhuBaru != null) {
            setState(() {
              suhuAir = suhuBaru;

              // Update Grafik
              waktuGrafik++;
              if (dataGrafik.length > 10) {
                dataGrafik.removeAt(0);
              }
              dataGrafik.add(FlSpot(waktuGrafik, suhuAir));
            });

            // Simpan ke Database
            simpanKeDatabase(suhuBaru);
          }
        }
      });
    } else {
      print('MQTT Connection Failed');
      client.disconnect();
    }
  }

  void onDisconnected() {
    setState(() {
      isConnected = false;
    });
    print('MQTT Disconnected');
  }

  void kirimPerintah(String pesan) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(pesan);
      client.publishMessage(
        "ikan/pakan/perintah",
        MqttQos.atMostOnce,
        builder.payload!,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("MQTT belum terhubung!")));
    }
  }

  Future<void> simpanKeDatabase(double suhu) async {
    // GANTI IP INI DENGAN IP LAPTOP KAMU
    final String url = "http://172.20.10.2/fish_api/insert_suhu.php";
    try {
      await http.post(Uri.parse(url), body: {"suhu": suhu.toString()});
      print("Data tersimpan ke database");
    } catch (e) {
      print("Gagal simpan DB: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // List halaman untuk navigasi bawah
    final List<Widget> pages = [
      MonitoringTab(suhuAir: suhuAir, dataGrafik: dataGrafik),
      ControllingTab(onCommand: (cmd) => kirimPerintah(cmd)),
      const ScheduleTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fish It Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 8,
              backgroundColor: isConnected ? Colors.green : Colors.red,
            ),
          ),
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
        child: pages[_selectedIndex],
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
