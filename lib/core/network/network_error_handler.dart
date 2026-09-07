// **************************************************************************
// NetworkErrorHandler — معالجة مركزية لأخطاء الشبكة
// يحوّل كل خطأ تقني إلى رسالة عربية مفهومة للمستخدم
// **************************************************************************

import 'package:dio/dio.dart';

class NetworkErrorHandler {
  NetworkErrorHandler._();

  /// يُعيد رسالة عربية مناسبة لأي نوع من الأخطاء
  static String getMessage(Object error) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    // أخطاء Exception العادية — نخفي التفاصيل التقنية
    final msg = error.toString().replaceFirst('Exception: ', '');

    // إذا كانت الرسالة من السيرفر (بدون تفاصيل تقنية) نُعيدها كما هي
    if (_isUserFriendlyMessage(msg)) return msg;

    // وإلا نُعيد رسالة افتراضية
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  /// يُعيد رسالة عربية مناسبة لـ DioException
  static String _handleDioException(DioException e) {
    switch (e.type) {
      // لا يوجد اتصال بالإنترنت أو DNS فشل
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة.';

      // انتهت مهلة الاتصال
      case DioExceptionType.connectionTimeout:
        return 'استغرق الاتصال وقتاً طويلاً. تحقق من سرعة الإنترنت وأعد المحاولة.';

      // انتهت مهلة الإرسال
      case DioExceptionType.sendTimeout:
        return 'فشل إرسال البيانات. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';

      // انتهت مهلة الاستقبال
      case DioExceptionType.receiveTimeout:
        return 'استغرق الرد وقتاً طويلاً. يرجى المحاولة مرة أخرى.';

      // الاتصال انقطع في المنتصف
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب. يرجى المحاولة مرة أخرى.';

      // خطأ من السيرفر (response موجود)
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);

      // أخطاء متفرقة (null، connection abort، إلخ)
      case DioExceptionType.unknown:
      default:
        // محاولة استخراج السبب الحقيقي
        final innerMsg = e.message ?? '';
        if (innerMsg.contains('Failed host lookup') ||
            innerMsg.contains('No address associated') ||
            innerMsg.contains('SocketException')) {
          return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة.';
        }
        if (innerMsg.contains('connection abort') ||
            innerMsg.contains('Software caused') ||
            innerMsg.contains('Connection reset')) {
          return 'انقطع الاتصال بالسيرفر. سيتم إعادة المحاولة تلقائياً.';
        }
        return 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.';
    }
  }

  /// معالجة ردود السيرفر بأكواد الخطأ
  static String _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    // نحاول استخراج رسالة السيرفر أولاً
    final serverMsg = e.response?.data?['message']?.toString();
    if (serverMsg != null && serverMsg.isNotEmpty) {
      return serverMsg;
    }

    switch (statusCode) {
      case 401:
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
      case 403:
        return 'غير مصرح لك بتنفيذ هذا الإجراء.';
      case 404:
        return 'لم يتم العثور على البيانات المطلوبة.';
      case 422:
        return 'البيانات المدخلة غير صحيحة. يرجى المراجعة.';
      case 429:
        return 'تم إرسال الطلب مسبقاً. يرجى الانتظار قليلاً.';
      case 500:
      case 502:
      case 503:
        return 'هناك مشكلة مؤقتة في الخادم. يرجى المحاولة لاحقاً.';
      default:
        return 'حدث خطأ من الخادم (${statusCode ?? "unknown"}). يرجى المحاولة مرة أخرى.';
    }
  }

  /// التحقق مما إذا كانت الرسالة مفهومة للمستخدم (بدون تفاصيل تقنية)
  static bool _isUserFriendlyMessage(String msg) {
    // رسائل تقنية لا يجب إظهارها
    final technicalPatterns = [
      'DioException',
      'SocketException',
      'HttpException',
      'FormatException',
      'OS Error',
      'errno =',
      'Software caused',
      'Failed host lookup',
      'Connection refused',
      'Connection reset',
      'host lookup',
      'null',
      'Exception:',
      'Unexpected error',
      'Network error',
      'Error:',
    ];

    for (final pattern in technicalPatterns) {
      if (msg.toLowerCase().contains(pattern.toLowerCase())) return false;
    }

    // رسالة قصيرة ومفهومة
    return msg.isNotEmpty && msg.length < 200;
  }

  /// التحقق مما إذا كان الخطأ بسبب انقطاع الاتصال
  static bool isConnectionError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return true;
      }
      final msg = error.message ?? '';
      return msg.contains('Failed host lookup') ||
          msg.contains('SocketException') ||
          msg.contains('No address associated') ||
          msg.contains('connection abort');
    }
    return false;
  }
}
