import 'package:flutter/material.dart';

import 'viewmodels/theme_viewmodel.dart';
import 'views/banknote_validator_home_view.dart';

void main() {
  runApp(const BilleteApp());
}

class BilleteApp extends StatefulWidget {
  const BilleteApp({super.key});

  @override
  State<BilleteApp> createState() => _BilleteAppState();
}

class _BilleteAppState extends State<BilleteApp> {
  late final ThemeViewModel _themeViewModel;

  @override
  void initState() {
    super.initState();
    _themeViewModel = ThemeViewModel();
  }

  @override
  void dispose() {
    _themeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeViewModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'Lector de Billetes',
          // debugShowCheckedModeBanner: false,
          themeMode: _themeViewModel.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F7A54),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF30C08A),
              brightness: Brightness.dark,
            ),
          ),
          home: BanknoteValidatorHomeView(themeViewModel: _themeViewModel),
        );
      },
    );
  }
}
