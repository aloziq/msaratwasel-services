import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../core/domain/entities/bus_student_entity.dart';
import '../../../core/presentation/cubit/bus_trip_cubit.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/network/api_config.dart';
import 'dart:async';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';



class BusStudentsScreen extends StatefulWidget {
  const BusStudentsScreen({super.key});

  @override
  State<BusStudentsScreen> createState() => _BusStudentsScreenState();
}

class _BusStudentsScreenState extends State<BusStudentsScreen> {
  String _searchQuery = '';
  BusStudentStatus? _selectedStatus;
  final Set<String> _selectedStudentIds = {};
  bool _isSelectionMode = false;
  Timer? _pollingTimer;
  ReverbService? _reverbService;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _initReverb();
  }

  void _initReverb() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final busId = user.busId;
      
      if (busId != null) {
        _reverbService = ReverbService(
          userId: int.tryParse(user.id) ?? 0,
          dio: ApiClient.instance,
          onMessageReceived: (data) {
            debugPrint('🔄 Trip status updated via Reverb inside StudentsScreen: $data');
            if (mounted) {
              context.read<BusTripCubit>().loadTrip(silent: true);
            }
          },
        );
        
        await _reverbService!.connect();
        await _reverbService!.subscribe('private-bus.$busId');
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        final cubit = context.read<BusTripCubit>();
        if (cubit.state is BusTripLoaded) {
          final trip = (cubit.state as BusTripLoaded).trip;
          if (trip.tripStatus == 'in_progress' ||
              trip.tripStatus == 'awaiting_video' ||
              trip.tripStatus == 'awaiting_confirmation') {
            cubit.loadTrip(silent: true);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reverbService?.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }


  void _openQrScanner(BuildContext context) {
    // ✅ استخدام شاشة المسح الذكي المتصلة بالـ API بدلاً من المنطق المحلي
    context.push(
      AppRoutes.qrScan,
      extra: {'isTripMode': true},
    ).then((_) {
      // تحديث البيانات بعد العودة من شاشة المسح
      if (context.mounted) {
        context.read<BusTripCubit>().loadTrip(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;
    final isDriver = authState is AuthAuthenticated && authState.user.role == UserRole.driver;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A), // Midnight Blue
                    const Color(0xFF1E293B), // Slate 800
                  ]
                : [
                    const Color(0xFFF8FAFC), // Slate 50
                    const Color(0xFFE2E8F0), // Slate 200
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocConsumer<BusTripCubit, BusTripState>(
          listenWhen: (previous, current) => 
              current is BusTripUpdateSuccess || 
              current is BusTripUpdateError || 
              current is BusTripLoaded || 
              current is BusTripError,
          listener: (context, state) {
            if (state is BusTripUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is BusTripUpdateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is BusTripLoaded) {
              if (state.trip.tripStatus == 'finished' || state.trip.tripStatus == 'idle' || state.trip.tripStatus == null) {
                // Remove the forced navigation to assistantHome so the supervisor can view the students list even if the trip is closed.
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //     content: Text('✅ تم إنهاء الرحلة من قبل السائق. يتم الآن عرض الحالة النهائية للطلاب.'),
                //     backgroundColor: Colors.blueGrey,
                //     duration: Duration(seconds: 3),
                //   ),
                // );
              }
            }
          },
          buildWhen: (previous, current) => 
              current is BusTripLoading || current is BusTripError || current is BusTripLoaded,
          builder: (context, state) {
            if (state is BusTripLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BusTripError) {
              return Center(child: Text(state.message));
            }

            if (state is BusTripLoaded) {
              final trip = state.trip;
              final isTripActive = trip.tripStatus == 'in_progress' ||
                  trip.tripStatus == 'awaiting_video' ||
                  trip.tripStatus == 'awaiting_confirmation';
              final filteredStudents = trip.students.where((student) {
                final matchesSearch =
                    student.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (student.nameEn?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ?? false) ||
                    student.schoolId.contains(_searchQuery);
                final matchesStatus =
                    _selectedStatus == null ||
                    student.status == _selectedStatus;
                return matchesSearch && matchesStatus;
              }).toList();

              return CustomScrollView(
                slivers: [
                  AdaptiveSliverAppBar(
                    title: _isSelectionMode 
                      ? 'تم اختيار ${_selectedStudentIds.length}'
                      : l10n.studentsList,
                    leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _isSelectionMode = false;
                            _selectedStudentIds.clear();
                          }),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Icon(
                              Icons.menu_rounded,
                              color: theme.colorScheme.onSurface,
                            ),
                            onPressed: () => MainShell.of(context)?.openDrawer(),
                          ),
                        ),
                    actions: [
                      if (!_isSelectionMode && isTripActive && trip.tripStatus == 'in_progress' && isDriver)
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                          onPressed: () => context.push(AppRoutes.driverEndTrip),
                        ),
                      if (!_isSelectionMode)
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.qrCode),
                          onPressed: () => _openQrScanner(context),
                        ),
                      if (_isSelectionMode)
                        IconButton(
                          icon: const Icon(Icons.select_all_rounded),
                          onPressed: () {
                            setState(() {
                              final allIds = trip.students.map((e) => e.id).toSet();
                              if (_selectedStudentIds.length == allIds.length) {
                                _selectedStudentIds.clear();
                                _isSelectionMode = false;
                              } else {
                                _selectedStudentIds.addAll(allIds);
                              }
                            });
                          },
                        ),
                    ],
                    backgroundColor: Colors.transparent,
                    stretch: true,
                  ),
                  SliverToBoxAdapter(
                    child: _buildTripSummary(context, trip),
                  ),
                  if (_isSelectionMode && isTripActive)
                   SliverToBoxAdapter(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                       child: Row(
                         children: [
                           Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 if (_selectedStudentIds.isNotEmpty) {
                                   context.read<BusTripCubit>().groupBoard(
                                     _selectedStudentIds.toList(),
                                     trip.suggestedDirection ?? 'to_school',
                                   );
                                   setState(() {
                                     _isSelectionMode = false;
                                     _selectedStudentIds.clear();
                                   });
                                 }
                               },
                               icon: const Icon(Icons.arrow_circle_up_rounded, size: 20),
                               label: const Text('ركوب للكل', style: TextStyle(fontSize: 13)),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.blue,
                                 foregroundColor: Colors.white,
                                 minimumSize: const Size(double.infinity, 45),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               ),
                             ),
                           ),
                           const SizedBox(width: AppSpacing.sm),
                           Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 if (_selectedStudentIds.isNotEmpty) {
                                   context.read<BusTripCubit>().groupAlight(
                                     _selectedStudentIds.toList(),
                                     trip.suggestedDirection ?? 'to_school',
                                   );
                                   setState(() {
                                     _isSelectionMode = false;
                                     _selectedStudentIds.clear();
                                   });
                                 }
                               },
                               icon: const Icon(PhosphorIconsFill.checkCircle, size: 20),
                               label: const Text('نزول للكل', style: TextStyle(fontSize: 13)),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.green,
                                 foregroundColor: Colors.white,
                                 minimumSize: const Size(double.infinity, 45),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               ),
                             ),
                           ),
                         ],
                       ),
                     ).animate().fadeIn().slideY(begin: -0.2),
                   ),
                  SliverToBoxAdapter(
                    child: _buildSearchAndFilter(context, isDark),
                  ),
                  if (filteredStudents.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('لا يوجد طلاب يطابقون البحث')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = filteredStudents[index];
                          final isSelected = _selectedStudentIds.contains(student.id);
                          return _StudentCard(
                                student: student,
                                isSelected: isSelected,
                                isSelectionMode: _isSelectionMode && isTripActive,
                                isTripActive: isTripActive,
                                onLongPress: () {
                                  if (!isTripActive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('لا يمكن تعديل حالة الطلاب لعدم وجود رحلة نشطة حالياً.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  final cubitState = context.read<BusTripCubit>().state;
                                  final direction = (cubitState is BusTripLoaded)
                                      ? cubitState.trip.suggestedTripType
                                      : 'to_school';
                                  if (direction == 'to_school') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          Localizations.localeOf(context).languageCode == 'ar'
                                              ? 'الحافلة لم تصل بعد الى منزل الطالب ولم يتم تشغيل عداد الوقت بعد'
                                              : 'The bus has not yet arrived at the student\'s home and the timer has not started yet',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedStudentIds.add(student.id);
                                  });
                                },
                                onTap: () {
                                  if (_isSelectionMode && isTripActive) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedStudentIds.remove(student.id);
                                        if (_selectedStudentIds.isEmpty) {
                                          _isSelectionMode = false;
                                        }
                                      } else {
                                        _selectedStudentIds.add(student.id);
                                      }
                                    });
                                  }
                                },
                                onCall: () =>
                                    _makePhoneCall(student.parentPhone),
                              )
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.1);
                        }, childCount: filteredStudents.length),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final cubitState = context.read<BusTripCubit>().state;
    final direction = (cubitState is BusTripLoaded)
        ? cubitState.trip.suggestedDirection
        : 'to_school';
    final isToSchool = direction == 'to_school';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, l10n.all),
                const SizedBox(width: AppSpacing.xs),
                if (isToSchool)
                  _buildFilterChip(BusStudentStatus.atHome, l10n.atHome)
                else
                  _buildFilterChip(BusStudentStatus.atSchool, l10n.atSchool),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.onBus, l10n.onBus),
                const SizedBox(width: AppSpacing.xs),
                if (isToSchool)
                  _buildFilterChip(BusStudentStatus.atSchool, l10n.atSchool)
                else
                  _buildFilterChip(BusStudentStatus.atHome, l10n.atHome),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(BusStudentStatus.absent, l10n.absent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BusStudentStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTripSummary(BuildContext context, dynamic trip) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = trip.students.length;
    final atSchool = trip.students
        .where((s) => s.status == BusStudentStatus.atSchool)
        .length;
    final onBus = trip.students
        .where((s) => s.status == BusStudentStatus.onBus)
        .length;
    final progress = total > 0 ? atSchool / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tripProgress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.deliveredStudentsCount(atSchool, total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.bus,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatInfo(l10n.onBus, onBus.toString()),
              _buildStatInfo(
                l10n.remaining,
                (total - atSchool - onBus).toString(),
              ),
              _buildStatInfo(
                l10n.percentage,
                '${(progress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final BusStudentEntity student;
  final VoidCallback? onCall;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isTripActive;

  const _StudentCard({
    required this.student,
    this.onCall,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    required this.isTripActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(student.status);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      backgroundImage: NetworkImage(
                        ApiConfig.getImageUrl(student.photoUrl),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.getLocalizedName(Localizations.localeOf(context).languageCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.graduationCap,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.getLocalizedGrade(Localizations.localeOf(context).languageCode),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIconsRegular.identificationCard,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.schoolId,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (student.status == BusStudentStatus.waiting)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _WaitingTimer(
                              since: student.waitingSince,
                              elapsed: student.waitingElapsedSeconds,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: student.status),
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8.0),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (val) => onTap?.call(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildIconButton(
                        context,
                        PhosphorIconsFill.phone,
                        Colors.green,
                        onCall ?? () {},
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        context,
                        PhosphorIconsFill.chatCircleText,
                        student.parentUserId != null ? Colors.blue : Colors.grey,
                        () {
                          final receiverId = student.parentUserId;
                          if (receiverId != null && receiverId.isNotEmpty) {
                            final localeCode = Localizations.localeOf(context).languageCode;
                            context.push(
                              AppRoutes.messages,
                              extra: {
                                'id': null,
                                'name': localeCode == 'ar'
                                    ? 'ولي أمر ${student.getLocalizedName('ar')}'
                                    : 'Parent of ${student.getLocalizedName('en')}',
                                'receiverId': receiverId,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('بيانات التواصل مع ولي الأمر غير متوفرة حالياً'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildActionButton(context),
                      const SizedBox(width: 4),
                      _buildMoreButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!isTripActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          student.status.labelAr,
          style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final cubitState = context.read<BusTripCubit>().state;
    final direction = (cubitState is BusTripLoaded)
        ? cubitState.trip.suggestedTripType
        : 'to_school';

    final isToSchool = direction == 'to_school';

    // ═══════════════════════════════════════════════════════════
    // State Machine — الأزرار تتغير حسب الاتجاه والحالة الحالية
    // ═══════════════════════════════════════════════════════════

    // حالة مكتملة: وصل وجهته النهائية
    final isCompleted = (isToSchool && student.status == BusStudentStatus.atSchool)
        || (!isToSchool && student.status == BusStudentStatus.atHome);

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(PhosphorIconsFill.checkCircle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.arrivedSafely,
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // الطالب على الباص → زر النزول (وصل المدرسة / وصل المنزل)
    if (student.status == BusStudentStatus.onBus) {
      final label = isToSchool ? l10n.reachedSchool : 'وصل المنزل';
      final icon = isToSchool ? PhosphorIconsFill.buildings : PhosphorIconsFill.house;
      return ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 36),
        ),
        onPressed: () => context.read<BusTripCubit>().updateStudentStatus(
          student.id,
          isToSchool ? BusStudentStatus.atSchool : BusStudentStatus.atHome,
        ),
      );
    }

    if (isToSchool && (student.status == BusStudentStatus.atHome || student.status == BusStudentStatus.unknown)) {
      return ElevatedButton.icon(
        icon: const Icon(PhosphorIconsFill.bus, size: 16),
        label: Text(l10n.boardedBus),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 36),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الحافلة لم تصل بعد الى منزل الطالب ولم يتم تشغيل عداد الوقت بعد'
                    : 'The bus has not yet arrived at the student\'s home and the timer has not started yet',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    }

    // الطالب في نقطة البداية → زر الركوب
    final canBoard = (isToSchool && student.status == BusStudentStatus.waiting)
        || (!isToSchool && student.status == BusStudentStatus.atSchool);

    if (canBoard) {
      return ElevatedButton.icon(
        icon: const Icon(PhosphorIconsFill.bus, size: 16),
        label: Text(l10n.boardedBus),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 36),
        ),
        onPressed: () => context.read<BusTripCubit>().updateStudentStatus(
          student.id,
          BusStudentStatus.onBus,
        ),
      );
    }

    // حالة غير معروفة أو غائب
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        student.status.labelAr,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    if (!isTripActive) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final cubitState = context.read<BusTripCubit>().state;
    final direction = (cubitState is BusTripLoaded)
        ? cubitState.trip.suggestedTripType
        : 'to_school';
    final isToSchool = direction == 'to_school';

    if (isToSchool && (student.status == BusStudentStatus.atHome || student.status == BusStudentStatus.unknown)) {
      return IconButton(
        icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الحافلة لم تصل بعد الى منزل الطالب ولم يتم تشغيل عداد الوقت بعد'
                    : 'The bus has not yet arrived at the student\'s home and the timer has not started yet',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    }

    return PopupMenuButton<BusStudentStatus>(
      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (status) {
        context.read<BusTripCubit>().updateStudentStatus(student.id, status);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: BusStudentStatus.onBus, child: Text(l10n.onBus)),
        if (isToSchool)
          PopupMenuItem(value: BusStudentStatus.atSchool, child: Text(l10n.atSchool)),
        if (!isToSchool)
          PopupMenuItem(value: BusStudentStatus.atHome, child: Text(l10n.atHome)),
        PopupMenuItem(value: BusStudentStatus.absent, child: Text(l10n.absent)),
      ],
    );
  }

  Color _getStatusColor(BusStudentStatus status) {
    switch (status) {
      case BusStudentStatus.atHome:
        return Colors.blue;
      case BusStudentStatus.onBus:
        return Colors.orange;
      case BusStudentStatus.atSchool:
        return Colors.green;
      case BusStudentStatus.absent:
        return Colors.red;
      case BusStudentStatus.waiting:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BusStudentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BusStudentStatus.atHome:
        color = Colors.blue;
        break;
      case BusStudentStatus.onBus:
        color = Colors.orange;
        break;
      case BusStudentStatus.atSchool:
        color = Colors.green;
        break;
      case BusStudentStatus.absent:
        color = Colors.red;
        break;
      case BusStudentStatus.waiting:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(context, status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BuildContext context, BusStudentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case BusStudentStatus.atHome:
        return l10n.atHome;
      case BusStudentStatus.onBus:
        return l10n.onBus;
      case BusStudentStatus.atSchool:
        return l10n.atSchool;
      case BusStudentStatus.absent:
        return l10n.absent;
      case BusStudentStatus.waiting:
        return 'انتظار';
      default:
        return '';
    }
  }
}

class _WaitingTimer extends StatefulWidget {
  final DateTime? since;
  final int elapsed;
  const _WaitingTimer({required this.since, required this.elapsed});

  @override
  State<_WaitingTimer> createState() => _WaitingTimerState();
}

class _WaitingTimerState extends State<_WaitingTimer> {
  Timer? _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = 120 - widget.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _WaitingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsed != widget.elapsed) {
      setState(() {
        _secondsRemaining = 120 - widget.elapsed;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOvertime = _secondsRemaining < 0;
    final displaySeconds = _secondsRemaining.abs();
    final minutes = displaySeconds ~/ 60;
    final seconds = displaySeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOvertime 
            ? Colors.red.withValues(alpha: 0.1) 
            : Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOvertime 
              ? Colors.red.withValues(alpha: 0.3) 
              : Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsFill.timer, 
            size: 12, 
            color: isOvertime ? Colors.red : Colors.purple,
          ),
          const SizedBox(width: 4),
          Text(
            isOvertime ? 'انتظار إضافي +$timeStr' : 'متبقي $timeStr',
            style: TextStyle(
              color: isOvertime ? Colors.red : Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

