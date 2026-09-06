import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'package:video_compress/video_compress.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/services/location_service.dart';
import 'package:msaratwasel_services/core/utils/app_snack_bar.dart';
import 'package:msaratwasel_services/features/driver/trip/presentation/manager/end_trip_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';

class ManualEndTripScreen extends StatelessWidget {
  const ManualEndTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EndTripCubit>(),
      child: const _ManualEndTripContent(),
    );
  }
}

class _ManualEndTripContent extends StatefulWidget {
  const _ManualEndTripContent();

  @override
  State<_ManualEndTripContent> createState() => _ManualEndTripContentState();
}

class _ManualEndTripContentState extends State<_ManualEndTripContent> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  CameraState? _cameraState;
  String? _currentVideoPath;

  bool _isCheckingSecurity = false;
  bool _isRecording = false;
  bool _isCompressing = false;
  int _secondsRecorded = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    VideoCompress.cancelCompression();
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

  Future<void> _playErrorSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('Error playing error sound: $e');
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 400);
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (e) {
      HapticFeedback.vibrate();
    }
  }

  void _startTimer() {
    _secondsRecorded = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRecorded++;
      });

      // إيقاف إجباري إذا وصل التسجيل إلى 30 ثانية
      if (_secondsRecorded >= 30) {
        _stopRecordingAndFinalize();
      }
    });
  }

  /// المرحلة 2: الفحص الأمني ثم بدء التسجيل
  Future<void> _startSecurityCheckAndRecording(EndTripCubit cubit) async {
    if (_isCheckingSecurity || _isRecording) return;

    setState(() {
      _isCheckingSecurity = true;
    });

    try {
      // التحقق من السيرفر (نفس فحص الـ QR الدقيق)
      await cubit.checkTripReadiness();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingSecurity = false;
      });
      _triggerVibration();
      _playErrorSound();
      final msg = e.toString().replaceAll('Exception:', '').trim();
      AppSnackBar.showError(
        context,
        msg.isNotEmpty ? msg : 'لا يمكن بدء إنهاء الرحلة، يرجى التأكد من نزول جميع الطلاب أولاً.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCheckingSecurity = false;
    });

    // اجتياز الفحص الأمني ⬅️ بدء تسجيل الفيديو (المرحلة 3)
    try {
      if (_cameraState != null && _cameraState is VideoCameraState) {
        await (_cameraState as VideoCameraState).startRecording();
        _triggerVibration();
        _playSuccessSound();

        cubit.scanFrontQr('MANUAL-FRONT');

        setState(() {
          _isRecording = true;
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'تعذر بدء تسجيل الفيديو، يرجى المحاولة مجدداً.');
      }
    }
  }

  /// المرحلة 4: إيقاف التسجيل وضغط الفيديو ورفعه
  Future<void> _stopRecordingAndFinalize() async {
    if (!_isRecording) return;

    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });

    _triggerVibration();
    _playSuccessSound();

    try {
      if (_cameraState != null && _cameraState is VideoRecordingCameraState) {
        await (_cameraState as VideoRecordingCameraState).stopRecording();
        await Future.delayed(const Duration(milliseconds: 600));

        final String rawPath = _currentVideoPath ?? '';
        if (rawPath.isEmpty || !await File(rawPath).exists()) {
          if (mounted) {
            AppSnackBar.showError(context, 'فشل حفظ ملف الفيديو.');
          }
          return;
        }

        if (!mounted) return;
        final cubit = context.read<EndTripCubit>();
        setState(() {
          _isCompressing = true;
        });

        // ضغط الفيديو قبل الرفع (أقل من 5 ميجا وبدون صوت)
        String uploadPath = rawPath;
        try {
          debugPrint('Starting video compression on: $rawPath');
          final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
            rawPath,
            quality: VideoQuality.LowQuality,
            deleteOrigin: false,
            includeAudio: true,
          );

          if (compressedInfo != null && compressedInfo.path != null) {
            final compressedFile = File(compressedInfo.path!);
            if (await compressedFile.exists()) {
              final sizeInMb = (await compressedFile.length()) / (1024 * 1024);
              debugPrint('Compressed video size: ${sizeInMb.toStringAsFixed(2)} MB');
              uploadPath = compressedInfo.path!;
            }
          }
        } catch (compErr) {
          debugPrint('Video compression warning, proceeding with original: $compErr');
        } finally {
          if (mounted) {
            setState(() {
              _isCompressing = false;
            });
          }
        }

        // إرسال كود النهاية اليدوي وبدء الرفع
        cubit.prepareScanBack(uploadPath);
        cubit.scanBackQr('MANUAL-BACK');
        await cubit.finalizeUpload(uploadPath);
      }
    } catch (e) {
      debugPrint('Error finalizing manual video: $e');
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
        AppSnackBar.showError(context, 'حدث خطأ أثناء معالجة الفيديو: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<EndTripCubit, EndTripState>(
        listener: (context, state) {
          if (state is EndTripSuccess) {
            _showSuccessAndExit(context);
          } else if (state is EndTripError) {
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // الكاميرا بدقة SD ومع تسجيل الصوت
              CameraAwesomeBuilder.custom(
                saveConfig: SaveConfig.video(
                  videoOptions: VideoOptions(
                    enableAudio: true,
                    quality: VideoRecordingQuality.sd,
                    android: AndroidVideoOptions(
                      fallbackStrategy: QualityFallbackStrategy.lower,
                    ),
                  ),
                  pathBuilder: (sensors) async {
                    final Directory extDir = await getTemporaryDirectory();
                    final dirPath = '${extDir.path}/camerawesome';
                    await Directory(dirPath).create(recursive: true);
                    final String filePath = '$dirPath/manual_${DateTime.now().millisecondsSinceEpoch}.mp4';
                    _currentVideoPath = filePath;
                    return SingleCaptureRequest(filePath, sensors.first);
                  },
                ),
                builder: (cameraState, preview) {
                  _cameraState = cameraState;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // الرأس العلوي (أزرار التحكم)
                      _buildTopHeader(),

                      // أثناء التسجيل: عداد الـ REC والوقت في الأعلى
                      if (_isRecording) _buildRecordingTimerHeader(),

                      // المحتوى السفلي (المرحلة 1 أو المرحلة 3 أو مرحلة الرفع)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomControls(state),
                      ),
                    ],
                  );
                },
              ),

              // المرحلة 2: شاشة الفحص الأمني (Overlay)
              if (_isCheckingSecurity) _buildSecurityCheckOverlay(),

              // معالجة وضغط الفيديو
              if (_isCompressing) _buildCompressingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () {
                    if (_isRecording) {
                      _timer?.cancel();
                    }
                    context.pop();
                  },
                ),
                if (_cameraState != null) ...[
                  const SizedBox(width: 8),
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
                            flashMode == FlashMode.always ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: flashMode == FlashMode.always ? Colors.yellow : Colors.white,
                            size: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'نظام التحقق والأمان',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingTimerHeader() {
    final String minutes = (_secondsRecorded ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_secondsRecorded % 60).toString().padLeft(2, '0');

    return Positioned(
      top: 65,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 500.ms),
              const SizedBox(width: 8),
              Text(
                'REC',
                style: GoogleFonts.roboto(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Text(
                '$minutes:$seconds / 00:30',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(EndTripState state) {
    final cubit = context.read<EndTripCubit>();

    // المرحلة 4: شاشة الرفع
    if (state is EndTripUploading) {
      return _buildUploadCard(state.progress);
    }

    // المرحلة 3: أثناء التسجيل (زر إيقاف التسجيل وإنهاء الرحلة)
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تسجيل تفقد الحافلة جاري الآن',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'يرجى السير وتصوير مقاعد الحافلة حتى المقعد الأخير',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _stopRecordingAndFinalize,
                icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 26),
                label: Text(
                  'إيقاف التسجيل وإنهاء الرحلة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // المرحلة 1: الواجهة قبل البدء (زر بدء تسجيل تفقد الحافلة)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'توثيق تفقد الحافلة يدوياً',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'اضغط على زر البدء لتصوير مقاعد الحافلة والتأكد من خلوها (حد أقصى 30 ثانية)',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _startSecurityCheckAndRecording(cubit),
              icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
              label: Text(
                'بدء تسجيل تفقد الحافلة',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// المرحلة 2: واجهة الفحص الأمني المطابقة للصورة
  Widget _buildSecurityCheckOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF10B981),
                  size: 50,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 800.ms),
              const SizedBox(height: 24),
              Text(
                'جاري التأكد من نزول جميع الطلاب أولاً',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'يرجى التأكد من عدم وجود أي طالب داخل الحافلة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Color(0xFF10B981),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompressingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compress_rounded, color: Color(0xFF38BDF8), size: 54),
              const SizedBox(height: 16),
              Text(
                'جاري معالجة وضغط الفيديو...',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تقليل حجم الفيديو لتسريع الرفع وحفظ باقة الإنترنت',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFF38BDF8)),
            ],
          ),
        ),
      ),
    );
  }

  /// المرحلة 4: واجهة الرفع المطابقة للصورة
  Widget _buildUploadCard(double progress) {
    final int percent = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري حفظ الفيديو ورفعه تلقائياً...',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              color: const Color(0xFF10B981),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percent%',
            style: GoogleFonts.roboto(color: const Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'سيتم إغلاق الرحلة تلقائياً بعد اكتمال الرفع',
            style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndExit(BuildContext context) {
    LocationService.stop();
    _playSuccessSound();

    AppSnackBar.showSuccess(
      context,
      'تمت الرحلة بنجاح. تم توثيق خلو الحافلة وحفظ الفيديو.',
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
}
