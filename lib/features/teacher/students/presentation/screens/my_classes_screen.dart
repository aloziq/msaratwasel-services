import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';

import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import '../cubit/my_classes_cubit.dart';
import '../cubit/my_classes_state.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MyClassesCubit>().loadClasses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<MyClassesCubit, MyClassesState>(
        builder: (context, state) {
          if (state is MyClassesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MyClassesError) {
            return Center(child: Text(state.message));
          } else if (state is MyClassesLoaded) {
            final l10n = AppLocalizations.of(context)!;
            final classrooms = state.classrooms;
            return CustomScrollView(
              slivers: [
                AdaptiveSliverAppBar(
                  title: l10n.myClasses,
                  leading: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        PhosphorIconsRegular.list,
                        color: theme.colorScheme.onSurface,
                        size: 32,
                      ),
                      onPressed: () {
                        MainShell.of(context)?.openDrawer();
                      },
                    ),
                  ),
                  backgroundColor: theme.scaffoldBackgroundColor.withValues(
                    alpha: 0.9,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final classroom = classrooms[index];
                      return _ClassCard(classroom: classroom, index: index);
                    }, childCount: classrooms.length),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassroomEntity classroom;
  final int index;

  const _ClassCard({required this.classroom, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhosphorIconsFill.chalkboardTeacher,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          classroom.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('عدد الطلاب: ${classroom.studentCount}'),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        onTap: () {
          context.push(
            AppRoutes.classDetailsPath(classroom.id),
            extra: classroom,
          );
        },
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
  }
}
