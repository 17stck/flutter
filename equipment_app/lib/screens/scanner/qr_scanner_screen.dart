// lib/screens/scanner/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/app_theme.dart';
import '../equipment/equipment_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final eq = await context.read<EquipmentProvider>().findByCode(code);

    if (!mounted) return;

    if (eq != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EquipmentDetailScreen(equipment: eq)),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('ไม่พบครุภัณฑ์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text('ไม่พบรหัสครุภัณฑ์: $code', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }

    setState(() => _isProcessing = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // ─── Scanner Overlay ──────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      ..._buildCorners(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'นำกล้องไปยัง QR Code ของครุภัณฑ์',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // ─── Processing Indicator ─────────────────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // ─── Manual Search ────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () => _showManualSearch(context),
              icon: const Icon(Icons.search),
              label: const Text('ค้นหาด้วยรหัสด้วยตนเอง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const len = 24.0;
    const thick = 3.0;
    final color = Colors.white;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(len, thick, color, true, true),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(len, thick, color, true, false),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(len, thick, color, false, true),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(len, thick, color, false, false),
      ),
    ];
  }

  void _showManualSearch(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ค้นหาด้วยรหัสครุภัณฑ์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'กรอกรหัสครุภัณฑ์ เช่น EQ-2024-001',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final code = ctrl.text.trim().toUpperCase();
                  if (code.isEmpty) return;
                  Navigator.pop(context);
                  final eq = await context.read<EquipmentProvider>().findByCode(
                    code,
                  );
                  if (!mounted) return;
                  if (eq != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentDetailScreen(equipment: eq),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ไม่พบรหัส: $code'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
                child: const Text('ค้นหา'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final double len, thick;
  final Color color;
  final bool top, left;
  const _Corner(this.len, this.thick, this.color, this.top, this.left);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len,
      height: len,
      child: CustomPaint(painter: _CornerPainter(color, thick, top, left)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top, left;
  _CornerPainter(this.color, this.thick, this.top, this.left);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
