import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Pastikan import ini

class MonitoringTab extends StatelessWidget {
  final double suhuAir;
  final List<FlSpot> dataGrafik;

  const MonitoringTab({
    super.key,
    required this.suhuAir,
    required this.dataGrafik,
  });

  @override
  Widget build(BuildContext context) {
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
              ),
              child: LineChart(
                // ... (Copy Paste konfigurasi LineChartData dari main.dart lama)
                // Pastikan menggunakan variabel widget.dataGrafik atau this.dataGrafik
                LineChartData(
                  // ... gunakan dataGrafik di sini ...
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataGrafik.isEmpty
                          ? [const FlSpot(0, 0)]
                          : dataGrafik,
                      // ... style lainnya ...
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
    // ... (Copy method _cardSensor ke sini)
    return Container(
      // ... kode UI Card ...
    );
  }
}
