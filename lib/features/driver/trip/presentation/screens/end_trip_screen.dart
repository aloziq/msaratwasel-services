import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:video_compress/video_compress.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/end_trip_cubit.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class EndTripScreen extends StatelessWidget {
  const EndTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EndTripCubit>(),
      child: const _EndTripContent(),
    );
  }
}

class _EndTripContent extends StatefulWidget {
  const _EndTripContent();

  @override
  State<_EndTripContent> createState() => _EndTripContentState();
}

class _EndTripContentState extends State<_EndTripContent> {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  int _processCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      
      setState(() => _isCameraInitialized = true);
      
      // Start processing frames for QR detection
      _cameraController!.startImageStream(_processImageFrame);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _processImageFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    
    // We only process every 30th frame to save battery/CPU, unless we are scanning
    _processCount++;
    if (_processCount % 10 != 0) return;

    final cubit = context.read<EndTripCubit>();
    if (cubit.state is EndTripSuccess || cubit.state is EndTripUploading) return;

    _isProcessingFrame = true;

    try {
      final inputImage = _convertImage(image);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted) {
        final String? code = barcodes.first.rawValue;
        if (code != null) {
          _handleBarcodeDetection(code, cubit);
        }
      }
    } catch (e) {
      debugPrint('ML Kit Frame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage _convertImage(CameraImage image) {
    // Basic conversion for ML Kit
    // In real app, we use complex coordinate conversion, but ML Kit handles standard cases
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg, // Adjust based on platform
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _handleBarcodeDetection(String code, EndTripCubit cubit) async {
    if (cubit.state is EndTripInitial) {
      if (code.startsWith('FRONT-')) {
        cubit.scanFrontQr(code);
        await _cameraController!.startVideoRecording();
      }
    } else if (cubit.state is EndTripRecording) {
      if (code.startsWith('BACK-')) {
        final video = await _cameraController!.stopVideoRecording();
        cubit.scanBackQr(code, video.path);
        _startCompressionAndUpload(video.path, cubit);
      }
    }
  }

  Future<void> _startCompressionAndUpload(String path, EndTripCubit cubit) async {
    // 1. Compression
    final MediaInfo? info = await VideoCompress.compressVideo(
      path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: true,
    );

    if (info?.path != null) {
      await cubit.finalizeUpload(info!.path!);
    } else {
      // Fallback to original if compression failed
      await cubit.finalizeUpload(path);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<EndTripCubit, EndTripState>(
        listener: (context, state) {
          if (state is EndTripSuccess) {
            _showSuccessAndExit(context, l10n);
          } else if (state is EndTripError) {
            _showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              if (_isCameraInitialized)
                CameraPreview(_cameraController!)
              else
                const Center(child: CircularProgressIndicator()),

              // Overlays
              _buildUIOverlay(context, state, l10n),
              
              // Scanning Indicator
              if (state is EndTripInitial || state is EndTripRecording)
                _buildScanningGuide(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUIOverlay(BuildContext context, EndTripState state, AppLocalizations l10n) {
    String title = "قم بمسح الكود الأمامي";
    String desc = "ابدأ بمسح كود QR الموجود في مقدمة الحافلة";
    Color overlayColor = Colors.black45;

    if (state is EndTripRecording) {
      title = "جاري تسجيل التحقق...";
      desc = "توجه إلى خلف الحافلة لضمان خلو المقاعد وامسح الكود الخلفي";
      overlayColor = Colors.red.withOpacity(0.2);
    } else if (state is EndTripCompressing) {
      title = "جاري معالجة الفديو...";
      desc = "يرجى الانتظار، نقوم بضغط الفديو لتقليل الحجم";
    } else if (state is EndTripUploading) {
      title = "جاري رفع التوثيق...";
      desc = "نقوم الآن بنقل العمل للوحة التحكم";
    }

    return Column(
      children: [
        // Top Header
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomMenuButton(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, py: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.emerald, size: 16),
                      const SizedBox(width: 6),
                      Text("نظام التوثيق الآمن", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Bottom Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state is EndTripUploading)
                 _buildProgressIndicator(state.progress)
              else if (state is EndTripCompressing)
                 const CircularProgressIndicator(color: Colors.blue)
              else
                 Icon(
                   state is EndTripRecording ? Icons.videocam : Icons.qr_code_scanner, 
                   color: Colors.white, 
                   size: 32
                 ).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms),
              
              const SizedBox(height: 20),
              Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              if (state is EndTripError)
                PremiumButton(
                  text: "إعادة المحاولة", 
                  onTap: () => context.read<EndTripCubit>().restart()
                ),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 500.ms),
      ],
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          color: Colors.emerald,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 10),
        Text(
          "${(progress * 100).toInt()}%",
          style: const TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildScanningGuide() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Scanning line animation
            Container(
              width: double.infinity,
              height: 2,
              color: Colors.white,
            ).animate(onPlay: (c) => c.repeat()).slideY(begin: 0, end: 125, duration: 2.seconds),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndExit(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إنهاء الرحلة بنجاح"), backgroundColor: Colors.green),
    );
    context.go(AppRoutes.driverHome);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
