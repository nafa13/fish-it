import 'package:flutter/material.dart';

class ControllingTab extends StatelessWidget {
  final Function(String) onCommand; // Callback fungsi

  const ControllingTab({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            context,
            "BERI MAKAN",
            Icons.set_meal,
            Colors.orangeAccent,
            "FEED",
          ),
          const SizedBox(height: 30),
          _controlButton(
            context,
            "KURAS AIR",
            Icons.waves,
            Colors.blueAccent,
            "DRAIN",
          ),
        ],
      ),
    );
  }

  Widget _controlButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String cmd,
  ) {
    return GestureDetector(
      onTap: () {
        onCommand(cmd); // Panggil fungsi di parent
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Perintah '$cmd' dikirim!")));
      },
      child: Container(
        // ... (Copy styling container tombol dari main.dart lama)
        child: Row(
          // ... isi tombol ...
        ),
      ),
    );
  }
}
