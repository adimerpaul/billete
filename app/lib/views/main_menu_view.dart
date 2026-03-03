import 'package:flutter/material.dart';

import 'banknote_scanner_view.dart';

class MainMenuView extends StatelessWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu principal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar captura'),
                subtitle: const Text('Captura un billete y extrae su serie'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BanknoteScannerView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
