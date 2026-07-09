import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

enum _PermissionState { checking, granted, denied, permanentlyDenied }

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  _PermissionState _permission = _PermissionState.checking;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _requestCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _permission = _PermissionState.granted);
    } else if (status.isPermanentlyDenied) {
      setState(() => _permission = _PermissionState.permanentlyDenied);
    } else {
      setState(() => _permission = _PermissionState.denied);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
      final api = ApiService();
      await api.init();
      final result = await api.qrLogin(token);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(patientData: result)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
      await _controller.start();
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_permission == _PermissionState.granted)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller.toggleTorch(),
            ),
        ],
      ),
      body: switch (_permission) {
        _PermissionState.checking => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        _PermissionState.granted => _buildScanner(),
        _PermissionState.denied => _buildDenied(permanent: false),
        _PermissionState.permanentlyDenied => _buildDenied(permanent: true),
      },
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => Center(
            child: Text(
              'Camera error: ${error.errorCode.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),
        if (_processing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _buildDenied({required bool permanent}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white54, size: 64),
            const SizedBox(height: 20),
            Text(
              permanent
                  ? 'Camera access is blocked.\nPlease enable it in Settings.'
                  : 'Camera permission is required\nto scan the QR code.',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: permanent ? openAppSettings : _requestCamera,
              child: Text(permanent ? 'Open Settings' : 'Allow Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cutoutSize,
      height: cutoutSize,
    );

    final dimPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const bl = 24.0;
    final r = cutoutRect;

    canvas.drawLine(r.topLeft, r.topLeft.translate(bl, 0), bracketPaint);
    canvas.drawLine(r.topLeft, r.topLeft.translate(0, bl), bracketPaint);
    canvas.drawLine(r.topRight, r.topRight.translate(-bl, 0), bracketPaint);
    canvas.drawLine(r.topRight, r.topRight.translate(0, bl), bracketPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(bl, 0), bracketPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(0, -bl), bracketPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(-bl, 0), bracketPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(0, -bl), bracketPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Point at your patient QR code',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, cutoutRect.bottom + 20),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
