import 'dart:math'; // Tambahan untuk acak ID
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FishFeederPage(),
    );
  }
}

class FishFeederPage extends StatefulWidget {
  const FishFeederPage({super.key});

  @override
  State<FishFeederPage> createState() => _FishFeederPageState();
}

class _FishFeederPageState extends State<FishFeederPage> {
  // --- KONFIGURASI BARU (LEBIH STABIL) ---
  // Kita ganti ke broker EMQX yang lebih ramah WebSocket
  final String broker = 'broker.emqx.io';
  final int port = 8083; // Port WebSocket standar EMQX
  final String topic = 'ikan/pakan/perintah';

  // Membuat ID acak agar tidak ditendang server
  final String clientIdentifier = 'fish_user_${Random().nextInt(1000)}';

  late MqttBrowserClient client;
  String statusText = "Siap Terhubung";
  bool isConnected = false;
  Color statusColor = Colors.grey;

  Future<void> connectToMQTT() async {
    setState(() {
      statusText = "Menghubungkan ke EMQX...";
      statusColor = Colors.orange;
    });

    // Setup Client khusus Web (Format URL harus pas)
    // Perhatikan: 'ws://' karena port 8083 biasanya non-SSL, lebih mudah tembus firewall
    client = MqttBrowserClient('ws://$broker/mqtt', clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = onDisconnected;

    // Opsi tambahan agar koneksi web lebih lancar
    client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;

    try {
      await client.connect();
    } catch (e) {
      print('Error: $e');
      client.disconnect();
      return; // Stop jika error
    }

    // Cek status akhir
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        statusText = "TERHUBUNG (ONLINE)";
        isConnected = true;
        statusColor = Colors.green;
      });
      print('Berhasil terhubung ke $broker');
    } else {
      client.disconnect();
    }
  }

  void onDisconnected() {
    setState(() {
      statusText = "Koneksi Terputus";
      isConnected = false;
      statusColor = Colors.red;
    });
    print('MQTT Terputus');
  }

  void feedNow() {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Klik tombol Sambungkan dulu!")),
      );
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString("FEED");
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sinyal Pakan Dikirim! 🐟"),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fish IT v2")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indikator Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Connect (Hanya muncul jika belum connect)
            if (!isConnected)
              ElevatedButton.icon(
                onPressed: connectToMQTT,
                icon: const Icon(Icons.link),
                label: const Text("Sambungkan Server"),
              ),

            const SizedBox(height: 50),

            // Tombol Pakan
            ElevatedButton(
              onPressed: feedNow,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(60),
                backgroundColor: isConnected ? Colors.blue : Colors.grey,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 50, color: Colors.white),
                  Text("MAKAN", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
