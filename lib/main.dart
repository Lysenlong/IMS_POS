import 'package:flutter/material.dart';
import 'package:ims_pos/sale_screen_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khmer Angkor',
      home: const LoginPage(),
      // home: const SaleScreenPage(),
    );
  }
}
