import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/presentation/widgets/background_widget.dart';
import 'package:msaratwasel_services/core/presentation/widgets/date_picker_field.dart';
import 'package:msaratwasel_services/core/presentation/widgets/image_picker_widget.dart';
import 'package:msaratwasel_services/core/presentation/widgets/omani_rial_icon.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_button.dart';
import 'package:msaratwasel_services/core/presentation/widgets/premium_text_field.dart';
import 'package:msaratwasel_services/features/driver/maintenance/presentation/manager/maintenance_cubit.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class FuelRefillScreen extends StatelessWidget {
  const FuelRefillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceCubit>(),
      child: const _FuelRefillContent(),
    );
  }
}

class _FuelRefillContent extends StatefulWidget {
  const _FuelRefillContent();

  @override
  State<_FuelRefillContent> createState() => _FuelRefillContentState();
}

class _FuelRefillContentState extends State<_FuelRefillContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _odometerController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _image;

  @override
  void dispose() {
    _amountController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _submit(MaintenanceCubit cubit) {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseAttachPhoto),
          ),
        );
        return;
      }

      cubit.submitFuelRefill(
        amount: double.parse(_amountController.text),
        odometer: int.parse(_odometerController.text),
        date: _selectedDate,
        photoPath: _image?.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.fuelRefillTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.driverMaintenanceLogs),
            icon: Icon(PhosphorIconsRegular.clipboardText, color: theme.colorScheme.onSurface),
            tooltip: l10n.recentLogs,
          ),
        ],
      ),
      body: BlocListener<MaintenanceCubit, MaintenanceState>(
        listener: (context, state) {
          if (state is MaintenanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.dataSavedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is MaintenanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            const BackgroundWidget(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                130,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Upload Section
                    ImagePickerWidget(
                      image: _image,
                      onImageSelected: (file) {
                        setState(() {
                          _image = file;
                        });
                      },
                      isDark: isDark,
                      label: l10n.attachReceipt,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Date Picker
                    DatePickerField(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Amount Input
                    PremiumTextField(
                          controller: _amountController,
                          label: l10n.amount,
                          prefixWidget: !isArabic
                              ? OmaniRialIcon(
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                )
                              : null,
                          suffixWidget: isArabic
                              ? OmaniRialIcon(
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                )
                              : null,
                          textAlign: TextAlign.left,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterAmount;
                            }
                            if (double.tryParse(value) == null) {
                              return l10n.enterValidNumber;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppSpacing.lg),

                    // Odometer Reading Input
                    PremiumTextField(
                          controller: _odometerController,
                          label: l10n.odometerReading,
                          icon: PhosphorIconsRegular.speedometer,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterOdometer;
                            }
                            if (int.tryParse(value) == null) {
                              return l10n.enterValidNumber;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppSpacing.xxl),

                    // Submit Button
                    BlocBuilder<MaintenanceCubit, MaintenanceState>(
                      builder: (context, state) {
                        return PremiumButton(
                          text: l10n.save,
                          onTap: () =>
                              _submit(context.read<MaintenanceCubit>()),
                          isLoading: state is MaintenanceSubmitting,
                          icon: Icons.check_circle_outline_rounded,
                        );
                      },
                    ).animate().fadeIn(delay: 500.ms).scale(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
