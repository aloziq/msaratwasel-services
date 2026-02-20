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
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class MaintenanceRequestScreen extends StatelessWidget {
  const MaintenanceRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceCubit>(),
      child: const _MaintenanceRequestContent(),
    );
  }
}

class _MaintenanceRequestContent extends StatefulWidget {
  const _MaintenanceRequestContent();

  @override
  State<_MaintenanceRequestContent> createState() =>
      _MaintenanceRequestContentState();
}

class _MaintenanceRequestContentState
    extends State<_MaintenanceRequestContent> {
  final _formKey = GlobalKey<FormState>();
  final _problemDescriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _image;

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    _amountController.dispose();
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

      cubit.submitMaintenanceRequest(
        description: _problemDescriptionController.text,
        date: _selectedDate,
        cost: double.tryParse(_amountController.text),
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
          l10n.maintenanceRequestTitle,
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
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.amount;
                            }
                            if (double.tryParse(value) == null) {
                              return l10n.amount;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppSpacing.lg),

                    // Problem Description Input
                    PremiumTextField(
                          controller: _problemDescriptionController,
                          label: l10n.describeProblem,
                          icon: PhosphorIconsRegular.notebook,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          alignLabelWithHint: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.describeProblem;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppSpacing.xxl),

                    // Submit Button
                    BlocBuilder<MaintenanceCubit, MaintenanceState>(
                      builder: (context, state) {
                        return PremiumButton(
                          text: l10n.submitRequest,
                          onTap: () =>
                              _submit(context.read<MaintenanceCubit>()),
                          isLoading: state is MaintenanceSubmitting,
                          icon: Icons.send_rounded,
                        );
                      },
                    ).animate().fadeIn(delay: 400.ms).scale(),
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
