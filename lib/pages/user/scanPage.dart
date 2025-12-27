// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // EKLENDİ
import 'resultPage.dart';
import 'notFoundPage.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.qrCode],
  );

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
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

  // --- AKIŞKAN GEÇİŞ İÇİN ÖZEL ROTA (Fade Effect) ---
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(
        milliseconds: 300,
      ), // Yumuşak geçiş hızı
    );
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    String? scannedCode;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        scannedCode = barcode.rawValue!;
        break;
      }
    }

    if (scannedCode != null) {
      // 1. Kilidi Kapat ve UI güncelle
      _isProcessing = true;
      if (mounted) setState(() {});

      debugPrint('Barkod Okundu: $scannedCode');

      try {
        // 2. Kamerayı Durdur
        await _controller.stop();

        // 3. --- PRE-CHECK (ÖN KONTROL) ---
        // Sayfa değiştirmeden önce veritabanına burada bakıyoruz.
        // Bu sayede "Git-Gel" titremesi engelleniyor.
        var doc =
            await FirebaseFirestore.instance
                .collection('products')
                .doc(scannedCode)
                .get();

        if (!mounted) return;

        if (doc.exists) {
          // Ürün VARSA -> ResultPage'e git
          await Navigator.push(
            context,
            _createRoute(ResultPage(barcode: scannedCode)),
          );
        } else {
          // Ürün YOKSA -> Direkt NotFoundPage'e git
          // ResultPage hiç açılmaz, titreme olmaz.
          await Navigator.push(context, _createRoute(const NotFoundPage()));
        }
      } catch (e) {
        debugPrint("Hata: $e");
      } finally {
        // 4. Geri dönüldüğünde (Sayfalar kapandığında)
        if (mounted) {
          debugPrint("Tarama ekranına dönüldü, kamera hazırlanıyor...");
          // Kullanıcı elini çekebilsin diye bekleme süresi
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            await _controller.start();
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tasarım kodları aynı
    final scanWindowWidth = MediaQuery.of(context).size.width * 0.8;
    final scanWindowHeight = 300.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder:
                (context, error) => const Center(
                  child: Text(
                    "Kamera Hatası",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ),
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
                        // İşlem sırasındaysa SARI, değilse KIRMIZI (Yeşil yerine Sarı kullandım, 'Bekleyin' anlamında)
                        color: _isProcessing ? Colors.amber : Colors.redAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // SİYAH PERDE YERİNE SADECE LOADING
          // Ekranın tamamını karartmak yerine ortada şık bir loading gösterelim
          if (_isProcessing)
            Container(
              color: Colors.black54, // Hafif karartma
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator(color: Colors.green)],
                ),
              ),
            ),

          // ÜST BAR
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
                    "Scan Barcode",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // ALT KONTROLLER
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
        bool isActive = isFlash ? state.torchState == TorchState.on : false;
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

// CustomPainter Sınıfları (Aynı)
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
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerSize), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerSize, 0), paint);
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
  bool shouldRepaint(covariant LaserLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
