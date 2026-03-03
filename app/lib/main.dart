import 'package:flutter/material.dart';

import 'views/main_menu_view.dart';

void main() {
  runApp(const BilleteApp());
}

class BilleteApp extends StatelessWidget {
  const BilleteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lector de Billetes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166D4B)),
        useMaterial3: true,
      ),
      home: const MainMenuView(),
    );
  }
}
