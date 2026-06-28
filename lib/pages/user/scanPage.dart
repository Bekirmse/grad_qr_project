// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../user/resultPage.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.qrCode],
  );

  late AnimationController _scanAnimController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder:
          (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    String? scannedCode;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        scannedCode = barcode.rawValue!;
        break;
      }
    }
    if (scannedCode == null) return;

    _isProcessing = true;
    if (mounted) setState(() {});

    try {
      await _controller.stop();
      if (!mounted) return;
      await Navigator.push(
        context,
        _createRoute(ResultPage(barcode: scannedCode.trim())),
      );
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          await _controller.start();
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder:
                (_, __) => Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      'Camera Error',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
          ),

          CustomPaint(
            size: size,
            painter: _OverlayPainter(
              scanSize: scanSize,
              center: Offset(size.width / 2, size.height / 2 - 40),
            ),
          ),

          Positioned(
            left: (size.width - scanSize) / 2,
            top: size.height / 2 - scanSize / 2 - 40,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder:
                  (_, __) => Transform.scale(
                    scale: _isProcessing ? 1.0 : _pulseAnim.value,
                    child: SizedBox(
                      width: scanSize,
                      height: scanSize,
                      child: CustomPaint(
                        painter: _CornerPainter(
                          color:
                              _isProcessing
                                  ? const Color(0xFF2E7D32)
                                  : Colors.white,
                        ),
                      ),
                    ),
                  ),
            ),
          ),

          if (!_isProcessing)
            Positioned(
              left: (size.width - scanSize) / 2,
              top: size.height / 2 - scanSize / 2 - 40,
              child: SizedBox(
                width: scanSize,
                height: scanSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _scanAnim,
                    builder:
                        (_, __) => CustomPaint(
                          painter: _LaserPainter(progress: _scanAnim.value),
                        ),
                  ),
                ),
              ),
            ),

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Searching prices...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Scan Barcode',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, state, __) {
                      final isOn = state.torchState == TorchState.on;
                      return GestureDetector(
                        onTap: () => _controller.toggleTorch(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isOn
                                    ? Colors.yellow.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isOn
                                      ? Colors.yellow.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isOn ? Icons.flash_on : Icons.flash_off,
                            color: isOn ? Colors.yellow : Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Point camera at a barcode',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We\'ll compare prices across all markets instantly',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoChip(icon: Icons.qr_code_rounded, label: 'EAN-8'),
                      const SizedBox(width: 10),
                      _InfoChip(icon: Icons.qr_code_2_rounded, label: 'EAN-13'),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'QR Code',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanSize;
  final Offset center;

  _OverlayPainter({required this.scanSize, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: center,
                width: scanSize,
                height: scanSize,
              ),
              const Radius.circular(16),
            ),
          );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

    const r = 16.0;
    const len = 28.0;

    canvas.drawLine(const Offset(r, 0), const Offset(r + len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, r + len), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, r * 2, r * 2),
      3.14159,
      3.14159 / 2,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(size.width - r - len, 0),
      Offset(size.width - r, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      -3.14159 / 2,
      3.14159 / 2,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height - r - len),
      Offset(0, size.height - r),
      paint,
    );
    canvas.drawLine(
      Offset(r, size.height),
      Offset(r + len, size.height),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      3.14159 / 2,
      3.14159 / 2,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(size.width - r - len, size.height),
      Offset(size.width - r, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - r - len),
      Offset(size.width, size.height - r),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0,
      3.14159 / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}

class _LaserPainter extends CustomPainter {
  final double progress;
  _LaserPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF2E7D32).withValues(alpha: 0.8),
            const Color(0xFF66BB6A),
            const Color(0xFF2E7D32).withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1))
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _LaserPainter old) => old.progress != progress;
}
