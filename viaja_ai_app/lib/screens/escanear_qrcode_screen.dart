import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants.dart';

/// Tela de leitura do QR Code impresso numa nota fiscal (NFC-e).
///
/// Diferença importante em relação ao "Escanear nota" por foto: aqui não
/// tiramos uma foto para a IA analisar — a câmera decodifica o QR Code
/// localmente, no próprio aparelho (via CameraX/ML Kit no Android e
/// AVFoundation/Vision no iOS), sem precisar de rede nem de IA nesse
/// passo. Só o conteúdo já decodificado (uma URL curta) é enviado ao
/// servidor, na Edge Function extrair-nota-qrcode.
///
/// Devolve (via Navigator.pop) o conteúdo bruto do QR Code lido, ou null
/// se o usuário cancelar.
class EscanearQrcodeScreen extends StatefulWidget {
  const EscanearQrcodeScreen({super.key});

  @override
  State<EscanearQrcodeScreen> createState() => _EscanearQrcodeScreenState();
}

class _EscanearQrcodeScreenState extends State<EscanearQrcodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _jaLeu = false;

  void _aoDetectar(BarcodeCapture captura) {
    if (_jaLeu) return;
    final valor = captura.barcodes.isNotEmpty
        ? captura.barcodes.first.rawValue
        : null;
    if (valor == null || valor.isEmpty) return;
    _jaLeu = true;
    _controller.stop();
    Navigator.of(context).pop(valor);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ler QR Code da nota',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final ligado = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(ligado ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
            errorBuilder: (context, error) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography,
                      color: Colors.white54, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Não foi possível acessar a câmera.\n${error.errorDetails?.message ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          // Moldura simples indicando a área de leitura.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: kAccentGold, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aponte a câmera para o QR Code impresso na nota fiscal. '
                'No momento, a leitura por QR Code funciona apenas para '
                'notas emitidas na Paraíba (PB) — para outros estados, '
                'use a opção de escanear por foto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
