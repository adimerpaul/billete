import 'package:flutter/material.dart';

import '../models/serial_validation_result.dart';
import '../viewmodels/banknote_validator_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'banknote_scanner_view.dart';

class BanknoteValidatorHomeView extends StatefulWidget {
  const BanknoteValidatorHomeView({required this.themeViewModel, super.key});

  final ThemeViewModel themeViewModel;

  @override
  State<BanknoteValidatorHomeView> createState() =>
      _BanknoteValidatorHomeViewState();
}

class _BanknoteValidatorHomeViewState extends State<BanknoteValidatorHomeView> {
  late final BanknoteValidatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BanknoteValidatorViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<SerialValidationResult?>(
      MaterialPageRoute<SerialValidationResult?>(
        builder: (_) => const BanknoteScannerView(),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _viewModel.applyCameraResult(result);
  }

  Future<void> _openManualDialog() async {
    final controller = TextEditingController();
    final serial = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Colocar serie'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Ejemplo: 22588538 A',
              labelText: 'Numero de serie',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Validar'),
            ),
          ],
        );
      },
    );

    if (serial == null || serial.trim().isEmpty) {
      return;
    }
    _viewModel.validateManual(serial);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, widget.themeViewModel]),
      builder: (context, _) {
        final isDark = widget.themeViewModel.isDark;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Validador de Billetes'),
            actions: [
              IconButton(
                tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                onPressed: widget.themeViewModel.toggleTheme,
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0xFF0B1C20), Color(0xFF101728)]
                    : const [Color(0xFFE8F6F0), Color(0xFFF3F8FF)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(isDark: isDark),
                const SizedBox(height: 12),
                _buildMainButtons(),
                const SizedBox(height: 12),
                _buildResultCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainButtons() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ir a camara'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openManualDialog,
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Colocar serie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _viewModel.validationResult;
    final isError = _viewModel.status == ValidatorStatus.error;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (isError)
              Text(
                _viewModel.errorMessage ?? 'Error de validacion.',
                style: const TextStyle(color: Colors.red),
              )
            else if (result != null)
              _buildValidatedResult(result)
            else
              const Text('Escanea o coloca una serie manualmente.'),
            if (result != null) const SizedBox(height: 8),
            if (result != null)
              TextButton(
                onPressed: _viewModel.clear,
                child: const Text('Limpiar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatedResult(SerialValidationResult result) {
    final color = result.isValid ? Colors.green : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Serie: ${result.serial}'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            result.isValid ? 'VALIDO' : 'INVALIDO',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Text(result.message),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF13414A), Color(0xFF205A57)]
              : const [Color(0xFF0F7A54), Color(0xFF3FA88A)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control de Series',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Detecta en tiempo real si el billete esta inhabilitado o valido.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
