import 'package:flutter/material.dart';

class ControllingTab extends StatelessWidget {
  final Function(String) onCommand;

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
        onCommand(cmd);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Perintah '$cmd' dikirim!")));
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
