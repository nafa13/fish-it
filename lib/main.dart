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
      theme: ThemeData.dark().copyWith(
        // Menggunakan Tema Gelap
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Hitam Elegan (Material Dark)
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E), // Warna Kartu
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.cyanAccent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent.withOpacity(0.8),
            foregroundColor: Colors.black, // Teks tombol hitam agar kontras
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: Colors.cyanAccent,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// --- 1. HALAMAN LOGIN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final String apiUrl = 'http://localhost/fish_api/login.php';

  void login() async {
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi username dan password!")),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sedang memeriksa...")));

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"username": _user.text, "password": _pass.text},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
        }
      }
    } catch (e) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ], // Gradasi Gelap Biru
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              // Kartu Login agar lebih rapi
              color: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.waves, size: 80, color: Colors.cyanAccent),
                    const SizedBox(height: 20),
                    const Text(
                      "Fish It",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _user,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: login,
                        child: const Text(
                          "MASUK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  late MqttBrowserClient client;
  final String broker = 'broker.emqx.io';
  bool isConnected = false;
  double suhuAir = 0;
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

        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
          final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
          final String message = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );

          if (c[0].topic == 'ikan/monitor/suhu') {
            double val = double.tryParse(message) ?? 0;
            setState(() {
              suhuAir = val;
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
    final List<Widget> pages = [
      _buildMonitoringTab(),
      _buildControllingTab(),
      _buildJadwalTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fish It Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? "ONLINE" : "OFFLINE",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        // Background Gradient Halus
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
        // Menggunakan NavigationBar Material 3
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF1F1F1F),
        indicatorColor: Colors.cyanAccent.withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: Colors.cyanAccent),
            label: "Monitoring",
          ),
          NavigationDestination(
            icon: Icon(Icons.gamepad_outlined),
            selectedIcon: Icon(Icons.gamepad, color: Colors.cyanAccent),
            label: "Controlling",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.cyanAccent),
            label: "Jadwal",
          ),
        ],
      ),
    );
  }

  // --- TAB 1: MONITORING ---
  Widget _buildMonitoringTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status Kolam",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _cardSensor(
                  "Suhu Air",
                  "$suhuAir °C",
                  Icons.thermostat,
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cardSensor(
                  "Kelembaban",
                  "70 %",
                  Icons.water_drop,
                  Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Grafik Real-time",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.white10, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataGrafik.isEmpty
                          ? [const FlSpot(0, 0)]
                          : dataGrafik,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                      ),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.3),
                            Colors.blueAccent.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSensor(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CONTROLLING ---
  Widget _buildControllingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            "BERI MAKAN",
            Icons.set_meal,
            Colors.orangeAccent,
            "FEED",
          ),
          const SizedBox(height: 30),
          _controlButton("KURAS AIR", Icons.waves, Colors.blueAccent, "DRAIN"),
          const SizedBox(height: 50),
          const Text(
            "Panel Kontrol Manual",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(String label, IconData icon, Color color, String cmd) {
    return GestureDetector(
      onTap: () {
        kirimPerintah(cmd);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF333333),
            content: Text(
              "Perintah '$cmd' dikirim!",
              style: const TextStyle(color: Colors.cyanAccent),
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: JADWAL ---
  List<Map<String, String>> jadwalList = [];

  Widget _buildJadwalTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: jadwalList.isEmpty
          ? Center(
              child: Text(
                "Belum ada jadwal",
                style: TextStyle(color: Colors.grey[700]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jadwalList.length,
              itemBuilder: (context, index) {
                final item = jadwalList[index];
                final isPakan = item['type'] == 'PAKAN';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                        color: isPakan
                            ? Colors.orangeAccent
                            : Colors.blueAccent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Icon(
                      isPakan ? Icons.restaurant : Icons.water_damage,
                      color: isPakan ? Colors.orangeAccent : Colors.blueAccent,
                    ),
                    title: Text(
                      "${item['type']} - ${item['time']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Jadwal Harian",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
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
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252525),
              title: const Text(
                "Tambah Jadwal Baru",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      "Jam: ${selectedTime.format(context)}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.access_time,
                      color: Colors.cyanAccent,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.cyanAccent,
                                onPrimary: Colors.black,
                                surface: Color(0xFF303030),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null)
                        setStateDialog(() => selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF303030),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Tipe Aksi",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
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
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
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
