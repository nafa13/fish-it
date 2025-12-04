import 'package:flutter/material.dart';
import 'pages/login_page.dart'; // Import halaman login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fish It',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
        // ... (Sisa konfigurasi tema dari main.dart lama) ...
      ),
      home: const LoginPage(),
    );
  }
}
