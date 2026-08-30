import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/presentation/widgets/custom_menu_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/utils/app_snack_bar.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/end_trip_cubit.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/core/services/location_service.dart';

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
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isProcessingFrame = false;
  bool _isStopping = false;
  bool _isQrProcessing = false;
  CameraState? _cameraState;
  String? _currentVideoPath;

  @override
  void dispose() {
    _barcodeScanner.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final hasCustom = await Vibration.hasCustomVibrationsSupport();
        if (hasCustom == true) {
          await Vibration.vibrate(duration: 500, amplitude: 255);
        } else {
          await Vibration.vibrate(duration: 500);
        }
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('Error triggering vibration: $e');
      HapticFeedback.vibrate();
    }
  }

  DateTime? _lastFlashTime;

  void _showFlashMessage(String message) {
    final now = DateTime.now();
    if (_lastFlashTime == null || now.difference(_lastFlashTime!) > const Duration(seconds: 2)) {
      _lastFlashTime = now;
      HapticFeedback.vibrate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  InputImage? _convertImage(AnalysisImage image) {
    try {
      return image.when(
        nv21: (nv21Image) {
          return InputImage.fromBytes(
            bytes: nv21Image.bytes,
            metadata: InputImageMetadata(
              size: nv21Image.size,
              rotation: InputImageRotation.rotation90deg,
              format: InputImageFormat.nv21,
              bytesPerRow: nv21Image.planes.first.bytesPerRow,
            ),
          );
        },
        bgra8888: (bgra8888Image) {
          return InputImage.fromBytes(
            bytes: bgra8888Image.bytes,
            metadata: InputImageMetadata(
              size: bgra8888Image.size,
              rotation: InputImageRotation.rotation90deg,
              format: InputImageFormat.bgra8888,
              bytesPerRow: bgra8888Image.planes.first.bytesPerRow,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Conversion error: $e");
      return null;
    }
  }

  

  Future<void> _startCompressionAndUpload(
    String path,
    EndTripCubit cubit,
  ) async {
    if (path.isEmpty) return;
    
    try {
      // الرفع المباشر للفيديو وتجنب ضغطه برمجياً لمنع انهيار تطبيق الأندرويد بسبب الذاكرة والموارد
      debugPrint('Uploading raw video directly to secure connection: $path');
      await cubit.finalizeUpload(path);
    } catch (e) {
      debugPrint('Direct upload fallback error: $e');
      await cubit.finalizeUpload(path);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              CameraAwesomeBuilder.custom(
                saveConfig: SaveConfig.video(
                  videoOptions: VideoOptions(
                    enableAudio: false,
                    quality: VideoRecordingQuality.sd,
                    android: AndroidVideoOptions(
                      fallbackStrategy: QualityFallbackStrategy.lower,
                    ),
                  ),
                  pathBuilder: (sensors) async {
                    final Directory extDir = await getTemporaryDirectory();
                    final dirPath = '${extDir.path}/camerawesome';
                    await Directory(dirPath).create(recursive: true);
                    final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.mp4';
                    _currentVideoPath = filePath;
                    return SingleCaptureRequest(filePath, sensors.first);
                  },
                ),
                imageAnalysisConfig: AnalysisConfig(
                  androidOptions: const AndroidAnalysisOptions.nv21(
                    width: 1024,
                  ),
                  maxFramesPerSecond: 8, 
                  autoStart: true,
                ),
                onImageForAnalysis: (image) async {
                  if (_isProcessingFrame || _isStopping || _isQrProcessing || !mounted) return;
                  
                  final cubit = context.read<EndTripCubit>();
                  if (cubit.state is EndTripSuccess || cubit.state is EndTripUploading || cubit.state is EndTripCompressing) {
                    return;
                  }

                  _isProcessingFrame = true;
                  try {
                    final inputImage = _convertImage(image);
                    if (inputImage != null) {
                      final barcodes = await _barcodeScanner.processImage(inputImage);
                      if (barcodes.isNotEmpty && mounted) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          final upperCode = code.toUpperCase();
                          
                          // 1. مسح كود البداية FRONT لبدء التسجيل تلقائياً
                          if (cubit.state is EndTripInitial && upperCode.contains('FRONT')) {
                            if (_isQrProcessing) return;
                            _isQrProcessing = true;

                            // ✅ التحقق أولاً من نزول جميع الطلاب قبل السماح ببدء التسجيل
                            try {
                              await cubit.checkTripReadiness();
                            } catch (e) {
                              _isQrProcessing = false;
                              _triggerVibration();
                              if (mounted) {
                                final msg = e.toString().replaceAll('Exception:', '').trim();
                                AppSnackBar.showError(
                                  context,
                                  msg.isNotEmpty ? msg : 'لا يمكن بدء إنهاء الرحلة، يرجى التأكد من نزول جميع الطلاب أولاً.',
                                );
                              }
                              return;
                            }

                            _triggerVibration();
                            _playSuccessSound();
                            if (_cameraState != null && _cameraState is VideoCameraState) {
                              await (_cameraState as VideoCameraState).startRecording();
                              cubit.scanFrontQr(code);
                              _isQrProcessing = false;
                              
                              if (mounted) {
                                final isAr = Localizations.localeOf(context).languageCode == 'ar';
                                AppSnackBar.showInfo(
                                  context,
                                  isAr
                                      ? 'بدأ تسجيل الفيديو، يرجى التوجه ومسح الكود الخلفي للحافلة لإنهاء الرحلة'
                                      : 'Video recording started. Please scan the rear bus code to end the trip',
                                );
                              }
                            } else {
                              _isQrProcessing = false;
                            }
                          }
                          
                          // 2. مسح كود النهاية BACK لإيقاف التسجيل وحفظ الفيديو والرفع تلقائياً فوراً
                          else if (cubit.state is EndTripRecording && upperCode.contains('BACK')) {
                            _isQrProcessing = true;
                            _isStopping = true;
                            _triggerVibration();
                            _playSuccessSound();
                            
                            if (_cameraState != null && _cameraState is VideoRecordingCameraState) {
                              await (_cameraState as VideoRecordingCameraState).stopRecording();
                              await Future.delayed(const Duration(milliseconds: 800));
                              
                              final String videoPath = _currentVideoPath ?? '';
                              if (videoPath.isNotEmpty) {
                                final file = File(videoPath);
                                if (await file.exists() && await file.length() > 1024) {
                                  cubit.prepareScanBack(videoPath);
                                  cubit.scanBackQr(code);
                                  _startCompressionAndUpload(videoPath, cubit);
                                }
                              }
                            }
                            _isStopping = false;
                            _isQrProcessing = false;
                          }
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('ML Kit Frame error: $e');
                  } finally {
                    _isProcessingFrame = false;
                  }
                },
                builder: (cameraState, preview) {
                  // Keep a reference to cameraState to start/stop video recording programmatically
                  _cameraState = cameraState;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildUIOverlay(context, state, l10n),
                      if (state is EndTripInitial || state is EndTripRecording)
                        _buildScanningGuide(),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUIOverlay(
    BuildContext context,
    EndTripState state,
    AppLocalizations l10n,
  ) {
    String title = l10n.scanFrontCode;
    String desc = l10n.scanFrontDesc;
    
    if (state is EndTripRecording) {
      title = l10n.recordVideo;
      desc = l10n.recordVideoDesc;
    } else if (state is EndTripScanningBack) {
      title = "مسح باركود النهاية (BACK)";
      desc = "يرجى مسح باركود الحافلة الخلفي لتوثيق خلو الحافلة وإنهاء الرحلة.";
    } else if (state is EndTripCompressing) {
      title = l10n.processingVideoTitle;
      desc = l10n.processingVideoDesc;
    } else if (state is EndTripUploading) {
      title = l10n.uploadingVerificationTitle;
      desc = l10n.uploadingVerificationDesc;
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
                Row(
                  children: [
                    const CustomMenuButton(),
                    if (_cameraState != null && (state is EndTripInitial || state is EndTripRecording || state is EndTripScanningBack)) ...[
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: StreamBuilder<FlashMode>(
                            stream: _cameraState!.sensorConfig.flashMode$,
                            initialData: _cameraState!.sensorConfig.flashMode,
                            builder: (context, snapshot) {
                              final flashMode = snapshot.data ?? FlashMode.none;
                              return Icon(
                                flashMode == FlashMode.always
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: flashMode == FlashMode.always
                                    ? Colors.yellow
                                    : Colors.white,
                              );
                            },
                          ),
                          onPressed: () async {
                            final config = _cameraState!.sensorConfig;
                            if (config.flashMode == FlashMode.none) {
                              await config.setFlashMode(FlashMode.always);
                            } else {
                              await config.setFlashMode(FlashMode.none);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.verificationSafetySystem,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state is EndTripUploading)
                _buildProgressIndicator(state.progress)
              else if (state is EndTripCompressing)
                const CircularProgressIndicator(color: Colors.blue)
              else if (state is EndTripRecording)
                Column(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 24)
                        .animate(onPlay: (c) => c.repeat())
                        .fadeOut(duration: 500.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 8),
                    const Text(
                      "REC",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms),

              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              if (state is EndTripError)
                PremiumButton(
                  text: l10n.retry,
                  onTap: () => context.read<EndTripCubit>().restart(),
                ),
                
              if (state is EndTripRecording) ...[
                const SizedBox(height: 10),
                PremiumButton(
                  text: "إنهاء الرحلة (يدوياً)",
                  onTap: () async {
                    _triggerVibration();
                    _playSuccessSound();
                    try {
                      if (_cameraState != null && _cameraState is VideoRecordingCameraState) {
                        await (_cameraState as VideoRecordingCameraState).stopRecording();
                        
                        // Wait for file to be written
                        await Future.delayed(const Duration(milliseconds: 800));
                        
                        final String videoPath = _currentVideoPath ?? '';
                        
                        if (videoPath.isEmpty) {
                          _showFlashMessage(l10n.videoSavedError);
                          return;
                        }
                        final file = File(videoPath);
                        if (!await file.exists() || await file.length() < 1024) {
                          _showFlashMessage(l10n.videoFileInvalidError);
                          return;
                        }

                        final cubit = context.read<EndTripCubit>();
                        // إرسال الكود اليدوي مباشرة لإنهاء الرحلة فوراً ودون تعقيد
                        cubit.prepareScanBack(videoPath);
                        cubit.scanBackQr("MANUAL-BACK");
                        _startCompressionAndUpload(videoPath, cubit);
                      }
                    } catch (e) {
                      debugPrint('Manual stop error: $e');
                    }
                  },
                ),
              ],
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
          color: Colors.green,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 10),
        Text(
          "${(progress * 100).toInt()}%",
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
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
            Container(width: double.infinity, height: 2, color: Colors.white)
                .animate(onPlay: (c) => c.repeat())
                .slideY(begin: 0, end: 125, duration: 2.seconds),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndExit(BuildContext context, AppLocalizations l10n) {
    // Stop background location service as trip is finished
    LocationService.stop();
    
    AppSnackBar.showSuccess(
      context,
      "تمت الرحلة بنجاح. تم حفظ وتوثيق حالة الحافلة خالية.",
    );
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.role == UserRole.assistant) {
        context.go(AppRoutes.assistantHome);
      } else {
        context.go(AppRoutes.driverHome);
      }
    } else {
      context.go('/');
    }
  }

  void _showError(BuildContext context, String message) {
    AppSnackBar.showError(context, message);
  }
}
