import 'dart:async';
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
    // ID Unik Client
    String clientId = 'flutter_fish_${DateTime.now().millisecondsSinceEpoch}';

    // --- 1. KONFIGURASI SERVER HIVEMQ ---
    client = MqttBrowserClient(
      'wss://a1386989f7a14008a8acd720db8419ea.s1.eu.hivemq.cloud:8884/mqtt',
      '',
    );

    client.setProtocolV311();

    // --- 2. PENGATURAN KONEKSI ---
    client.logging(on: true);
    client.keepAlivePeriod = 60;

    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;

    client.port = 8884;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
          "hivemq.webclient.1764855566492",
          "2zl8gsSOApYL>C*?a<94",
        )
        .withWillTopic(
          'willtopic',
        ) // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    client.connectionMessage = connMess;

    try {
      print('Sedang menghubungkan ke HiveMQ...');
      await client.connect();
    } catch (e) {
      print('Gagal Konek: $e');
      client.disconnect();
    }

    // --- 3. CEK STATUS & SUBSCRIBE ---
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        isConnected = true;
      });
      print('BERHASIL TERHUBUNG KE HIVEMQ!');

      // Subscribe ke topik (Harus sama dengan Arduino)
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
      print('Koneksi Gagal - Status: ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  void onConnected() {
    print(' Client connection was sucessful');
  }

  void onDisconnected() {
    if (mounted) {
      setState(() {
        isConnected = false;
      });
    }
    print('MQTT Terputus');
  }

  void kirimPerintah(String pesan) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(pesan);

      // Publish perintah ke topik yang didengar Arduino
      client.publishMessage(
        "ikan/pakan/perintah",
        MqttQos.atMostOnce,
        builder.payload!,
      );
      print("Mengirim perintah: $pesan");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("MQTT belum terhubung! Tunggu sebentar..."),
        ),
      );
    }
  }

  Future<void> simpanKeDatabase(double suhu) async {
    // SAYA SAMAKAN IP DENGAN HALAMAN LOGIN KAMU (172.20.10.2)
    // Dan folder 'fish_api' agar konsisten
    final String url =
        "https://9ae1dbd1801a.ngrok-free.app/fish_api/insert_suhu.php";

    try {
      await http.post(Uri.parse(url), body: {"suhu": suhu.toString()});
      print("Data tersimpan ke database: $suhu");
    } catch (e) {
      print("Gagal simpan DB: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Text(
                  isConnected ? "ONLINE (HiveMQ)" : "OFFLINE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 6,
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                ),
              ],
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
