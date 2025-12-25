import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  // Barkod algılandığında çalışacak fonksiyon
  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
        });

        final String code = barcode.rawValue!;
        debugPrint('Barkod Bulundu: $code');

        // Kullanıcıya sonucu göster
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent closing by clicking outside
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Modern rounded corners
                ),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon with subtle background
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner, // More relevant icon
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      "Product Detected",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle/Description
                    const Text(
                      "The barcode has been successfully scanned.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Barcode Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 10),
                          SelectableText(
                            // Allows user to copy text
                            code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.only(
                  bottom: 24,
                  left: 24,
                  right: 24,
                ),
                actions: [
                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isScanned = false; // Resume scanning
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black, // Professional dark button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Scan Next Item",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        );
        break; // İlk barkodu al ve çık
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu alıyoruz
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
            // Hata durumunda gösterilecek widget
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  'Kamera hatası: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          // 2. KARARTMA VE ÇERÇEVE KATMANI (CustomPainter)
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
                // Sadece sınırları belli olsun diye boş bırakıyoruz,
                // veya köşe çizgileri eklenebilir.
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
                        color: Colors.redAccent, // Lazer rengi
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 4. ÜST BİLGİ ALANI (Geri Dön ve Başlık)
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
                const SizedBox(width: 48), // Dengelemek için boşluk
              ],
            ),
          ),

          // 5. ALT KONTROL PANELİ (Flaş ve Kamera Değiştirme)
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
                    // Flaş Butonu
                    _buildControlButton(
                      controller: _controller,
                      iconOn: Icons.flash_on,
                      iconOff: Icons.flash_off,
                      onTap: () => _controller.toggleTorch(),
                      isFlash: true,
                    ),
                    const SizedBox(width: 30),
                    // Kamera Değiştir Butonu
                    _buildControlButton(
                      controller: _controller,
                      iconOn: Icons.cameraswitch_rounded, // Sabit ikon
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

  // Kontrol butonları için yardımcı widget
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
          icon: Icon(
            isFlash ? (isActive ? iconOn : iconOff) : iconOn,
          ), // Kamera değişiminde ikon sabit
        );
      },
    );
  }
}

// --- CUSTOM PAINTER SINIFLARI (Görsellik İçin) ---

// 1. Karartma ve Delik Açma (Overlay)
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({required this.scanWindow, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Tüm ekranı yarı saydam siyah yap
    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Ortadaki tarama alanını (Scan Window) tanımla
    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
        );

    // 3. Arka plandan orta alanı çıkar (Delik aç)
    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.srcOver;

    // Path.combine ile delik açma işlemi
    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, backgroundPaint);

    // 4. Çerçevenin kenarlarına beyaz/renkli çizgiler çiz (Opsiyonel: Köşeler)
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Sadece köşeleri çizmek için (basit tam çerçeve yerine)
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

// 2. Hareket Eden Lazer Çizgisi
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

    // Efekt için gölge (Shadow) ekle
    final shadowPaint =
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final yPos = size.height * progress;

    // Gölgeyi çiz
    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), shadowPaint);
    // Ana çizgiyi çiz
    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paint);
  }

  @override
  bool shouldRepaint(covariant LaserLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
