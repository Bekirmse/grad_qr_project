// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'resultPage.dart'; // ResultPage dosyanızın yolu buraya gelecek

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  // Kamera kontrolcüsü
  final MobileScannerController _controller = MobileScannerController();

  // Animasyon kontrolcüsü (Lazer çizgisi için)
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Barkod okunduktan sonra tekrar tekrar tetiklenmemesi için kontrol
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    // Lazer animasyonu ayarları (2 saniyede inip çıkacak)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // GÜNCELLENEN KISIM BURASI:
  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        // Taramayı durdur (tekrar tetiklenmemesi için)
        setState(() {
          _isScanned = true;
        });

        final String code = barcode.rawValue!;
        debugPrint('Barkod Bulundu ve Yönlendiriliyor: $code');

        // ResultPage'e git ve barkodu gönder
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResultPage(barcode: code)),
        ).then((_) {
          // Geri dönüldüğünde tekrar taramaya izin ver
          if (mounted) {
            setState(() {
              _isScanned = false;
            });
          }
        });

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowWidth = MediaQuery.of(context).size.width * 0.8;
    final scanWindowHeight = 300.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA KATMANI
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  'Kamera hatası: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          // 2. KARARTMA VE ÇERÇEVE KATMANI
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanWindow: Rect.fromCenter(
                center: MediaQuery.of(context).size.center(Offset.zero),
                width: scanWindowWidth,
                height: scanWindowHeight,
              ),
              borderRadius: 20.0,
            ),
            child: Container(),
          ),

          // 3. LAZER ANİMASYONU
          Center(
            child: Container(
              width: scanWindowWidth,
              height: scanWindowHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: LaserLinePainter(
                        progress: _animation.value,
                        color: Colors.redAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 4. ÜST BİLGİ ALANI
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Barkodu Hizalayın",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 5. ALT KONTROL PANELİ
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      controller: _controller,
                      iconOn: Icons.flash_on,
                      iconOff: Icons.flash_off,
                      onTap: () => _controller.toggleTorch(),
                      isFlash: true,
                    ),
                    const SizedBox(width: 30),
                    _buildControlButton(
                      controller: _controller,
                      iconOn: Icons.cameraswitch_rounded,
                      iconOff: Icons.cameraswitch_rounded,
                      onTap: () => _controller.switchCamera(),
                      isFlash: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required MobileScannerController controller,
    required IconData iconOn,
    required IconData iconOff,
    required VoidCallback onTap,
    required bool isFlash,
  }) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        bool isActive = false;
        if (isFlash) {
          isActive = state.torchState == TorchState.on;
        }

        return IconButton(
          onPressed: onTap,
          iconSize: 32,
          color: isActive ? Colors.yellow : Colors.white,
          icon: Icon(isFlash ? (isActive ? iconOn : iconOff) : iconOn),
        );
      },
    );
  }
}

// --- CUSTOM PAINTER SINIFLARI ---
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({required this.scanWindow, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
        );

    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.srcOver;

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    _drawCorners(canvas, scanWindow, borderPaint);
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    double cornerSize = 30.0;
    // Sol Üst
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerSize), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerSize, 0), paint);
    // Sağ Üst
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerSize),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight - Offset(cornerSize, 0),
      paint,
    );
    // Sol Alt
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft - Offset(0, cornerSize),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerSize, 0),
      paint,
    );
    // Sağ Alt
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(0, cornerSize),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight - Offset(cornerSize, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LaserLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  LaserLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final shadowPaint =
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final yPos = size.height * progress;

    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), shadowPaint);
    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paint);
  }

  @override
  bool shouldRepaint(covariant LaserLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
