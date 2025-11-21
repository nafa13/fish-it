import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:fl_chart/fl_chart.dart'; // Library Grafik
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LoginPage(),
    );
  }
}

// --- 1. HALAMAN LOGIN (Sama seperti sebelumnya) ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ... (Kode Login sama seperti sebelumnya, singkatnya:)
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  // Ganti URL sesuai setup Anda
  final String apiUrl = 'http://localhost/fish_api/login.php';

  // --- GANTI FUNGSI LOGIN INI ---
  void login() async {
    // Cek input kosong
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi username dan password!")),
      );
      return;
    }

    // Tampilkan loading (opsional, bisa tambah variabel bool isLoading)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sedang memeriksa...")));

    try {
      // Kirim data ke PHP
      final response = await http.post(
        Uri.parse(apiUrl), // Pastikan apiUrl sudah benar (localhost/10.0.2.2)
        body: {"username": _user.text, "password": _pass.text},
      );

      // Baca jawaban dari PHP
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // JIKA SUKSES: Masuk ke Dashboard
        if (mounted) {
          // Cek apakah halaman masih aktif
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Berhasil! Halo ${data['data']['username']}"),
            ),
          );
        }
      } else {
        // JIKA GAGAL: Tampilkan pesan error dari PHP
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
        }
      }
    } catch (e) {
      // Jika server mati / error koneksi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Koneksi ke Server Database")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.waves, size: 80, color: Colors.teal),
              const Text(
                "Smart Pond Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _user,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: login, child: const Text("MASUK")),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. HALAMAN DASHBOARD UTAMA ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Setup MQTT Global
  late MqttBrowserClient client;
  final String broker = 'broker.emqx.io';
  bool isConnected = false;

  // Data Sensor (Dummy awal)
  double suhuAir = 0;
  double kelembaban = 0;
  List<FlSpot> dataGrafik = [];
  double waktuGrafik = 0;

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  Future<void> connectMQTT() async {
    client = MqttBrowserClient(
      'ws://$broker/mqtt',
      'flutter_client_${Random().nextInt(1000)}',
    );
    client.port = 8083;
    client.keepAlivePeriod = 60;
    client.onDisconnected = () => setState(() => isConnected = false);

    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        setState(() => isConnected = true);
        client.subscribe('ikan/monitor/suhu', MqttQos.atLeastOnce);

        // Listener Pesan Masuk
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
          final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
          final String message = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );

          // Parsing Data (Format JSON misal: {"t": 28.5, "h": 70})
          // Untuk simpel, kita anggap pesan raw angka suhu
          if (c[0].topic == 'ikan/monitor/suhu') {
            double val = double.tryParse(message) ?? 0;
            setState(() {
              suhuAir = val;
              // Update Grafik (geser waktu)
              if (dataGrafik.length > 10) dataGrafik.removeAt(0);
              dataGrafik.add(FlSpot(waktuGrafik++, val));
            });
          }
        });
      }
    } catch (e) {
      print('MQTT Error: $e');
    }
  }

  void kirimPerintah(String pesan) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(pesan);
    client.publishMessage(
      'ikan/pakan/perintah',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List Halaman berdasarkan Tab
    final List<Widget> pages = [
      _buildMonitoringTab(),
      _buildControllingTab(),
      _buildJadwalTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Pond Monitor"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(
              Icons.circle,
              color: isConnected ? Colors.greenAccent : Colors.red,
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Monitoring",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: "Controlling",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Jadwal",
          ),
        ],
      ),
    );
  }

  // --- TAB 1: MONITORING (GRAFIK & SENSOR) ---
  Widget _buildMonitoringTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _cardSensor(
                  "Suhu Air",
                  "$suhuAir °C",
                  Icons.thermostat,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cardSensor(
                  "Kelembaban",
                  "70 %",
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Grafik Suhu Real-time",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataGrafik.isEmpty
                        ? [const FlSpot(0, 0)]
                        : dataGrafik,
                    isCurved: true,
                    color: Colors.teal,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.teal.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSensor(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: CONTROLLING (BUTTONS) ---
  Widget _buildControllingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton("BERI MAKAN", Icons.set_meal, Colors.orange, "FEED"),
          const SizedBox(height: 30),
          _controlButton("KURAS AIR", Icons.waves, Colors.blue, "DRAIN"),
          const SizedBox(height: 50),
          const Text(
            "Status: Siap Menerima Perintah",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(String label, IconData icon, Color color, String cmd) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () {
          kirimPerintah(cmd);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Perintah '$cmd' dikirim!")));
        },
        icon: Icon(icon, size: 30),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // --- TAB 3: CRUD JADWAL ---
  // Note: Untuk demo ini kita simpan di list lokal variable.
  // Untuk produksi, Anda harus menghubungkan fungsi _addJadwal ke API PHP.
  List<Map<String, String>> jadwalList = [];

  Widget _buildJadwalTab() {
    return Scaffold(
      body: ListView.builder(
        itemCount: jadwalList.length,
        itemBuilder: (context, index) {
          final item = jadwalList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(
                item['type'] == 'PAKAN' ? Icons.restaurant : Icons.water_damage,
                color: item['type'] == 'PAKAN' ? Colors.orange : Colors.blue,
              ),
              title: Text("${item['type']} - ${item['time']}"),
              subtitle: const Text("Status: Aktif"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    jadwalList.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'PAKAN';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Butuh ini agar Dropdown bisa update state dalam Dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Tambah Jadwal"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Jam: ${selectedTime.format(context)}"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null)
                        setStateDialog(() => selectedTime = picked);
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "PAKAN",
                        child: Text("Beri Pakan"),
                      ),
                      DropdownMenuItem(
                        value: "KURAS",
                        child: Text("Kuras Air"),
                      ),
                    ],
                    onChanged: (val) =>
                        setStateDialog(() => selectedType = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Simpan ke List (atau kirim ke API PHP di sini)
                    setState(() {
                      jadwalList.add({
                        'time':
                            "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                        'type': selectedType,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
