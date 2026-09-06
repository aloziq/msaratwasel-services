import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';
import 'package:msaratwasel_services/core/di/injection.dart';
import 'package:msaratwasel_services/core/utils/app_snack_bar.dart';
import 'package:msaratwasel_services/features/driver/trip/domain/repositories/trip_repository.dart';

class EndTripChoiceScreen extends StatefulWidget {
  const EndTripChoiceScreen({super.key});

  @override
  State<EndTripChoiceScreen> createState() => _EndTripChoiceScreenState();
}

class _EndTripChoiceScreenState extends State<EndTripChoiceScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
  }

  Future<void> _checkActiveTrip() async {
    try {
      final tripRepo = getIt<TripRepository>();
      await tripRepo.checkTripReadiness();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception:', '').trim();
      
      // إذا لم تكن هناك رحلة نشطة نهائياً أو لم يتم تعيين حافلة للسائق
      if (errorMsg.contains('لا توجد رحلة') ||
          errorMsg.contains('لم يتم تعيين حافلة') ||
          errorMsg.contains('No bus') ||
          errorMsg.contains('404')) {
        if (mounted) {
          context.go(AppRoutes.driverHome);
          AppSnackBar.showError(
            context,
            errorMsg.isNotEmpty ? errorMsg : 'عذراً، لا توجد رحلة نشطة حالياً يمكن إنهاؤها.',
          );
        }
        return;
      }

      // إذا كانت الرحلة موجودة ونشطة (حتى لو كان هناك طلاب لم ينزلوا بعد 422)، نسمح بفتح الشاشة
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0284C7)),
              const SizedBox(height: 16),
              Text(
                'جاري التحقق من حالة الرحلة...',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'إنهاء الرحلة',
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF1E293B)),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top Bus Illustration Header
              _buildTopIllustration(),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'اختر طريقة إنهاء الرحلة',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'اختر الطريقة المناسبة لك لتسجيل تفقد الحافلة وإنهاء الرحلة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Two Cards Side-by-Side (or stacked on very small screens)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBarcodeCard(context)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildManualCard(context)),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBarcodeCard(context)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildManualCard(context)),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E8F0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIllustration() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Clouds
          Positioned(
            top: 25,
            left: 10,
            child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.8), size: 26),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.8), size: 22),
          ),
          // Bus Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          // Green Verified Check Badge
          Positioned(
            bottom: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBarcodeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Icon
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),

          Text(
            'الطريقة التلقائية',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF065F46),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '(عبر الباركود فقط)',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: const Color(0xFF047857),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Illustration Preview Box
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 2),
                      Container(width: 24, height: 1.5, color: Colors.red),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FRONT',
                      style: GoogleFonts.roboto(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Check Items
          _buildCheckItem('مخصصة للباركود فقط', const Color(0xFF10B981)),
          const SizedBox(height: 6),
          _buildCheckItem('مسح كود FRONT يبدأ التسجيل تلقائياً', const Color(0xFF10B981)),
          const SizedBox(height: 6),
          _buildCheckItem('مسح كود BACK يتوقف التسجيل ويرفع تلقائياً', const Color(0xFF10B981)),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.driverEndTripBarcode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'اختيار الطريقة التلقائية',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildManualCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Icon
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),

          Text(
            'الطريقة اليدوية',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E40AF),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '(شاشة متكاملة مستقلة)',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: const Color(0xFF2563EB),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Illustration Preview Box
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Interior bus aisle illustration
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(width: 14, height: 26, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(3))),
                        Container(width: 16, height: 1, color: Colors.white24),
                        Container(width: 14, height: 26, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.circle, color: Colors.white, size: 10),
                    ),
                  ],
                ),
                // Top REC and 00:00 badges
                Positioned(
                  top: 6,
                  left: 8,
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Text('REC', style: GoogleFonts.roboto(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 8,
                  child: Text('00:00', style: GoogleFonts.roboto(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Check Items
          _buildCheckItem('تسجيل فيديو بدون باركود إطلاقاً', const Color(0xFF2563EB)),
          const SizedBox(height: 6),
          _buildCheckItem('التأكد من نزول جميع الطلاب أولاً', const Color(0xFF2563EB)),
          const SizedBox(height: 6),
          _buildCheckItem('واجهة متكاملة للتسجيل والإنهاء', const Color(0xFF2563EB)),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.driverEndTripManual);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'اختيار الطريقة اليدوية',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCheckItem(String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: iconColor, size: 15),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تعليمات إنهاء الرحلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'يمكنك إنهاء الرحلة عبر الطريقة التلقائية بمسح ملصقات الباركود في الحافلة (المقدمة ثم النهاية)، أو اختيار الطريقة اليدوية لتسجيل فيديو تفقد المقاعد بضغطة زر دون الحاجة للباركود.',
          style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
