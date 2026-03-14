import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  XFile? _videoFile;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleQrScan(
    BarcodeCapture capture,
    EndTripCubit cubit,
    int currentStep,
  ) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && _isScanning) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
        }); // Stop showing scanner locally

        if (currentStep == 0) {
          cubit.scanFrontQr(code);
        } else if (currentStep == 2) {
          cubit.scanBackQr(code);
        }
      }
    }
  }

  Future<void> _recordVideo(EndTripCubit cubit) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      if (video != null) {
        setState(() {
          _videoFile = video;
        });
        cubit.recordVideo(video.path);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error recording video: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.endTripTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CustomMenuButton(),
        ),
      ),
      body: BlocConsumer<EndTripCubit, EndTripState>(
        listener: (context, state) {
          if (state is EndTripSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.tripEndedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.driverHome);
          } else if (state is EndTripError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          int currentStep = 0;
          if (state is EndTripRecording) currentStep = 1;
          if (state is EndTripScanningBack) currentStep = 2;
          if (state is EndTripSubmitting || state is EndTripSuccess) {
            currentStep = 3;
          }

          final cubit = context.read<EndTripCubit>();

          if (_isScanning) {
            return Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) =>
                      _handleQrScan(capture, cubit, currentStep),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 150,
                      child: PremiumButton(
                        text: l10n.cancel,
                        onTap: () => setState(() => _isScanning = false),
                      ),
                    ),
                  ),
                ),
                // Overlay guide
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Progress Steps
                Row(
                  children: [
                    _StepIndicator(
                      isActive: currentStep >= 0,
                      isCompleted: currentStep > 0,
                      label: '1',
                    ),
                    const _StepLine(),
                    _StepIndicator(
                      isActive: currentStep >= 1,
                      isCompleted: currentStep > 1,
                      label: '2',
                    ),
                    const _StepLine(),
                    _StepIndicator(
                      isActive: currentStep >= 2,
                      isCompleted: currentStep == 3,
                      label: '3',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Content based on step
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: currentStep == 0
                        ? _StepContent(
                            key: const ValueKey(0),
                            title: l10n.scanFrontCode,
                            description: l10n.scanFrontDesc,
                            icon: PhosphorIconsRegular.qrCode,
                            buttonText: l10n.scanFrontCode,
                            onTap: () {
                              setState(() {
                                _isScanning = true;
                              });
                            },
                          )
                        : currentStep == 1
                        ? _StepContent(
                            key: const ValueKey(1),
                            title: l10n.recordVideo,
                            description: l10n.recordVideoDesc,
                            icon: PhosphorIconsRegular.videoCamera,
                            buttonText: _videoFile != null
                                ? l10n.reRecord
                                : l10n.recordVideo,
                            onTap: () => _recordVideo(cubit),
                            extraContent: _videoFile != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.videoRecorded,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          )
                        : _StepContent(
                            key: const ValueKey(2),
                            title: l10n.scanBackCode,
                            description: l10n.scanBackDesc,
                            icon: PhosphorIconsRegular.qrCode,
                            buttonText: l10n.scanBackCode,
                            onTap: () {
                              setState(() {
                                _isScanning = true;
                              });
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.isActive,
    required this.isCompleted,
    required this.label,
  });

  final bool isActive;
  final bool isCompleted;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green
            : isActive
            ? Colors.blue
            : Colors.grey.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white)
          : Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
    ).animate().scale(duration: 300.ms);
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3)),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    this.extraContent,
  });

  final String title;
  final String description;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 80,
          color: theme.colorScheme.primary,
        ).animate().fadeIn().scale(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PremiumButton(text: buttonText, onTap: onTap, icon: icon),
        if (extraContent != null) ...[
          const SizedBox(height: AppSpacing.md),
          extraContent!,
        ],
      ],
    );
  }
}
