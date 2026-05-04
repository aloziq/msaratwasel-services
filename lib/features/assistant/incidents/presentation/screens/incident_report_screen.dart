import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_services/core/network/api_client.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';
import '../../../../../core/presentation/widgets/adaptive_sliver_app_bar.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';
import 'package:dio/dio.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? _selectedTypeKey;
  final TextEditingController _descriptionController = TextEditingController();

  // Bus / driver / assistant info loaded from SharedPreferences
  int? _busId;
  String? _busCode;
  String? _driverName;
  String? _assistantName;

  // Student selection (for behavioral)
  List<Map<String, dynamic>> _busStudents = [];
  final List<dynamic> _selectedStudentIds = [];

  // Photo

  File? _attachedPhoto;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _selectedTypeKey = 'behavioral';
    _loadBusInfo();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Load bus ID/code and driver info from SharedPreferences and API.
  Future<void> _loadBusInfo() async {
    setState(() => _isLoadingInfo = true);
    try {
      final prefs = GetIt.instance<SharedPreferences>();
      final busIdStr = prefs.getString('USER_BUS_ID');
      final busCode = prefs.getString('USER_BUS_CODE');
      final driverName = prefs.getString('USER_DRIVER_NAME');
      final assistantName =
          prefs.getString('USER_NAME') ?? prefs.getString('user_name');

      if (busIdStr != null) {
        final busId = int.tryParse(busIdStr);
        setState(() {
          _busId = busId;
          _busCode = busCode;
          _driverName = driverName;
          _assistantName = assistantName;
        });

        // Load students from this bus
        if (busId != null) {
          await _loadStudents(busId);
        }
      }
    } catch (e) {
      debugPrint('[AssistantIncident] Error loading bus info: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInfo = false);
    }
  }

  Future<void> _loadStudents(int busId) async {
    try {
      final response = await ApiClient.instance.get(
        '/bus/$busId/passengers',
        queryParameters: {'trip_type': 'all'},
      );
      if (response.statusCode == 200) {
        final passengers = response.data['passengers'] as List? ?? [];
        if (mounted) {
          setState(() {
            _busStudents = passengers
                .map<Map<String, dynamic>>(
                  (p) => {
                    'id': p['student_id'] ?? p['id'],
                    'name': p['student_name'] ?? p['name'] ?? '',
                    'uuid': p['uuid'] ?? '',
                    'photoUrl':
                        p['photoUrl'] ??
                        p['student_photo'] ??
                        p['photo_url'] ??
                        p['photo'],
                  },
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('[AssistantIncident] Error loading students: $e');
    }
  }

  void _showStudentSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اختيار الطلاب المعنيين',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك اختيار أكثر من طالب',
                  style: theme.textTheme.bodySmall,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _busStudents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final student = _busStudents[index];
                      final String studentId = (student['id'] ?? '').toString();
                      final bool isSelected = _selectedStudentIds.contains(
                        studentId,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          student['name'] ?? '',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        secondary: SizedBox(
                          width: 44,
                          height: 44,
                          child: ClipOval(
                            child: _StudentAvatar(
                              photoUrl: student['photoUrl'],
                              name: student['name'] ?? '',
                              isSelected: isSelected,
                              theme: theme,
                            ),
                          ),
                        ),
                        subtitle: null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        activeColor: theme.colorScheme.primary,
                        onChanged: (bool? val) {
                          setModalState(() {
                            if (val == true) {
                              if (!_selectedStudentIds.contains(studentId)) {
                                _selectedStudentIds.add(studentId);
                              }
                            } else {
                              _selectedStudentIds.remove(studentId);
                            }
                          });
                          // تحديث الشاشة الرئيسية أيضاً
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('تم'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('المعرض'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _attachedPhoto = File(picked.path));
    }
  }

  Future<void> _submitReport() async {
    if (_busId == null) {
      _showSnack('لم يتم العثور على حافلة مرتبطة بحسابك', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('يرجى كتابة وصف البلاغ', isError: true);
      return;
    }
    if (_selectedTypeKey == 'behavioral' && _selectedStudentIds.isEmpty) {
      _showSnack(
        'يرجى اختيار طالب واحد على الأقل للبلاغ السلوكي',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // تجهيز الحقول الأساسية
      final Map<String, dynamic> dataMap = {
        'bus_id': _busId,
        'type': _selectedTypeKey,
        'severity': _selectedTypeKey == 'sos' ? 'critical' : 'medium',
        'description': _descriptionController.text.trim(),
        'location_lat': null, // يمكن إضافة خدمة الموقع لاحقاً
        'location_lng': null,
      };

      // إضافة قائمة الطلاب بالتنسيق الذي يفضله Laravel
      if (_selectedTypeKey == 'behavioral' && _selectedStudentIds.isNotEmpty) {
        for (int i = 0; i < _selectedStudentIds.length; i++) {
          dataMap['student_ids[$i]'] = _selectedStudentIds[i];
        }
      }

      // إضافة الصورة إن وجدت
      if (_attachedPhoto != null) {
        dataMap['photos[0]'] = await MultipartFile.fromFile(
          _attachedPhoto!.path,
          filename: 'incident_photo.jpg',
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await ApiClient.instance.post(
        'field/incidents',
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        if (mounted) {
          _showSnack('تم إرسال البلاغ بنجاح ✅');
          Navigator.pop(context);
        }
      } else {
        final msg = response.data['message'] ?? 'فشل في إرسال البلاغ';
        _showSnack(msg, isError: true);
      }
    } catch (e) {
      _showSnack('حدث خطأ أثناء الإرسال: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Map<String, String> _getTypes(AppLocalizations l10n) {
    return {
      'behavioral': l10n.incidentTypeBehavioral,
      'health': l10n.incidentTypeHealth,
      'technical': l10n.incidentTypeTechnical,
      'traffic': l10n.incidentTypeTraffic,
      'other': l10n.incidentTypeOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final typesMap = _getTypes(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          AdaptiveSliverAppBar(
            title: l10n.incidentReportTitle,
            leading: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => MainShell.of(context)?.openDrawer(),
              ),
            ),
            backgroundColor: Colors.transparent,
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: _isLoadingInfo
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Bus Info Card ──
                        if (_busCode != null) ...[
                          _BusInfoCard(
                            busCode: _busCode!,
                            driverName: _driverName,
                            assistantName: _assistantName,
                            isDark: isDark,
                            theme: theme,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Incident Type ──
                        Text(
                          l10n.incidentType,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: typesMap.entries.map((entry) {
                            final isSelected = _selectedTypeKey == entry.key;
                            return ChoiceChip(
                              label: Text(entry.value),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedTypeKey = entry.key;
                                    _selectedStudentIds.clear();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Student Selection (behavioral only) ──
                        if (_selectedTypeKey == 'behavioral') ...[
                          Text(
                            'الطلاب المعنيين بالمخالفة السلوكية',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _busStudents.isEmpty
                                ? null
                                : _showStudentSelectionSheet,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsFill.users,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedStudentIds.isEmpty
                                          ? 'اختر الطلاب المعنيين بالبلاغ...'
                                          : 'تم اختيار ${_selectedStudentIds.length} طلاب',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: _selectedStudentIds.isEmpty
                                                ? theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Description ──
                        Text(
                          l10n.problemDescription,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        PremiumTextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          label: l10n.reportDetailsPlaceholder,
                          keyboardType: TextInputType.multiline,
                          alignLabelWithHint: true,
                          icon: PhosphorIconsRegular.pencilSimple,
                        ),
                        const SizedBox(height: 24),

                        // ── Photo Attachment ──
                        Text(
                          l10n.attachPhotoOptional,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        if (_attachedPhoto != null) ...[
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickPhoto,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _attachedPhoto!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _attachedPhoto = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تغيير الصورة'),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            icon: const Icon(PhosphorIconsRegular.camera),
                            label: Text(l10n.attachPhotoOptional),
                            onPressed: _pickPhoto,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                              foregroundColor: isDark
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(PhosphorIconsFill.warningCircle, size: 24),
                label: Text(
                  l10n.sendUrgentReport,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: Colors.red.withOpacity(0.4),
                ),
              ),
      ),
    );
  }
}

/// Card showing bus, driver, and assistant info
class _BusInfoCard extends StatelessWidget {
  final String busCode;
  final String? driverName;
  final String? assistantName;
  final bool isDark;
  final ThemeData theme;

  const _BusInfoCard({
    required this.busCode,
    this.driverName,
    this.assistantName,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.bus,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حافلة $busCode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'سيتم رفع البلاغ على هذه الحافلة تلقائياً',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (driverName != null || assistantName != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (driverName != null)
                  Expanded(
                    child: _InfoRow(
                      icon: PhosphorIconsRegular.steeringWheel,
                      label: 'السائق',
                      value: driverName!,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                if (assistantName != null)
                  Expanded(
                    child: _InfoRow(
                      icon: PhosphorIconsRegular.user,
                      label: 'المشرفة',
                      value: assistantName!,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget لعرض صورة الطالب من الـ Backend مع loading وerror fallback
class _StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final bool isSelected;
  final ThemeData theme;

  const _StudentAvatar({
    required this.photoUrl,
    required this.name,
    required this.isSelected,
    required this.theme,
  });

  String get _initial {
    if (name.isEmpty) return 'ط';
    // صح للأسماء العربية والإنجليزية
    final runes = name.runes.toList();
    if (runes.isEmpty) return 'ط';
    return String.fromCharCode(runes.first);
  }

  Widget _buildFallback() {
    return Container(
      color: isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = photoUrl != null
        ? ApiConfig.getImageUrl(photoUrl)
        : null;

    if (resolvedUrl == null) return _buildFallback();

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: theme.colorScheme.primaryContainer,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
