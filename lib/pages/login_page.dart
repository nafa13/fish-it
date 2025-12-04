import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart'; // Import dashboard

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  // GANTI IP INI SESUAI IP LAPTOP KAMU (JANGAN LOCALHOST)
  final String apiUrl = 'http://192.168.1.XX/fish_api/login.php';

  void login() async {
    // ... (Logika login sama persis seperti di main.dart lama)
    // Saat berhasil:
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
  }

  @override
  Widget build(BuildContext context) {
    // ... (Copy Paste seluruh build method dari LoginPage lama di main.dart)
    return Scaffold(
      // ... kode UI Login ...
    );
  }
}
