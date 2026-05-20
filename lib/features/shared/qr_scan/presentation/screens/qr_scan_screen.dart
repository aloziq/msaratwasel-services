import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../cubit/qr_scan_cubit.dart';
import '../cubit/qr_scan_state.dart';

import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class QRScanScreen extends StatefulWidget {
  final String? classId;
  final bool isTripMode;
  
  const QRScanScreen({super.key, this.classId, this.isTripMode = false});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Color? overlayColor;
  bool isProcessing = false;
  String lastScannedCode = '';
  Timer? cooldownTimer;

  @override
  void dispose() {
    controller.dispose();
    cooldownTimer?.cancel();
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

  Future<void> _playErrorSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('Error playing error sound: $e');
    }
  }

  void _showOverlayColor(Color color) {
    setState(() {
      overlayColor = color;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          overlayColor = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<QRScanCubit>(),
      child: BlocListener<QRScanCubit, QRScanState>(
        listener: (context, state) {
          if (state is QRScanLoading) {
            isProcessing = true;
          } else if (state is QRScanSuccess) {
            isProcessing = false;
            if (widget.classId != null) {
              // Direct attendance marking mode
              context.read<QRScanCubit>().markAttendanceViaQr(
                    state.code,
                    widget.classId ?? '',
                  );
            } else if (!widget.isTripMode) {
              // General purpose mode (pop with code)
              _playSuccessSound();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: ${state.code}')));
              Future.delayed(const Duration(seconds: 1), () {
                if (!context.mounted) return;
                context.pop(state.code);
              });
            }
          } else if (state is QRScanAttendanceSuccess) {
            isProcessing = true; // Pause scanning
            controller.stop(); // ⏸ إيقاف الكاميرا مؤقتاً
            _playSuccessSound();
            HapticFeedback.heavyImpact();
            _showOverlayColor(const Color(0xFF10B981).withValues(alpha: 0.6));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${l10n.attendanceMarked}: ${state.studentId}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            final cubit = context.read<QRScanCubit>();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  isProcessing = false;
                  lastScannedCode = '';
                });
                cubit.reset();
                controller.start(); // ▶ إعادة تشغيل الكاميرا
              }
            });
          } else if (state is QRScanTripSuccess) {
            isProcessing = true; // Pause scanning
            _playSuccessSound();
            HapticFeedback.heavyImpact();
            _showOverlayColor(const Color(0xFF10B981).withValues(alpha: 0.7));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.studentName} (${state.newStatus}) - ${state.message}',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            final cubit = context.read<QRScanCubit>();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  isProcessing = false;
                  lastScannedCode = '';
                });
                cubit.reset();
              }
            });
          } else if (state is QRScanTripError) {
            isProcessing = true; // Pause scanning
            _playErrorSound();
            HapticFeedback.vibrate();
            _showOverlayColor(Colors.red.withValues(alpha: 0.7));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.cairo()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            final cubit = context.read<QRScanCubit>();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  isProcessing = false;
                  lastScannedCode = '';
                });
                cubit.reset();
              }
            });
          } else if (state is QRScanError) {
            isProcessing = true; // Pause scanning
            _playErrorSound();
            _showOverlayColor(Colors.red.withValues(alpha: 0.7));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.cairo()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            final cubit = context.read<QRScanCubit>();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  isProcessing = false;
                  lastScannedCode = '';
                });
                cubit.reset();
              }
            });
          }
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(l10n.scanAttendance),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Stack(
                children: [
                  // Scanner
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (isProcessing) return;
                      
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                          final String code = barcode.rawValue!;
                          
                          // Debounce consecutive same-code scans to prevent spam
                          if (code == lastScannedCode) return;
                          lastScannedCode = code;
                          
                          cooldownTimer?.cancel();
                          cooldownTimer = Timer(const Duration(seconds: 3), () {
                            lastScannedCode = '';
                          });

                          HapticFeedback.mediumImpact();

                          debugPrint('[QRScan] 📷 Code scanned: "$code" | classId: ${widget.classId} | isTripMode: ${widget.isTripMode}');

                          if (widget.isTripMode) {
                            // فلترة أكواد الحافلة (FRONT/BACK) — هذه خاصة بإنهاء الرحلة فقط
                            final upperCode = code.toUpperCase();
                            if (upperCode.contains('FRONT') || upperCode.contains('BACK')) {
                              _playErrorSound();
                              HapticFeedback.vibrate();
                              _showOverlayColor(Colors.orange.withValues(alpha: 0.7));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'هذا كود الحافلة وليس كود طالب.',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            context.read<QRScanCubit>().markSmartTripAttendanceViaQr(code);
                          } else if (widget.classId != null) {
                            debugPrint('[QRScan] 🚀 Calling markAttendanceViaQr with code: $code, classId: ${widget.classId}');
                            context.read<QRScanCubit>().markAttendanceViaQr(
                                  code,
                                  widget.classId ?? '',
                                );
                          } else {
                            context.read<QRScanCubit>().onCodeScanned(code);
                          }
                        }
                      }
                    },
                  ),

                  // Overlay
                  _buildOverlay(context),

                  // Success/Error Color Flash Overlay
                  if (overlayColor != null)
                    Positioned.fill(
                      child: Container(
                        color: overlayColor,
                      ),
                    ),

                  // Controls
                  _buildControls(context),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: overlayColor ?? Colors.white, width: overlayColor != null ? 6 : 2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ControlButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.blue);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.red);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: icon,
        color: Colors.white,
        iconSize: 32,
        onPressed: onPressed,
      ),
    );
  }
}

