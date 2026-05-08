import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import 'package:msaratwasel_services/core/utils/date_utils.dart' as date_utils;

import '../../domain/repositories/messages_repository.dart';
import 'package:get_it/get_it.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.conversationId,
    this.recipientName,
    this.receiverId,
  });

  final String? conversationId;
  final String? recipientName;
  final String? receiverId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;

  bool _isLoading = true;
  String? _error;
  final MessagesRepository _messagesRepository =
      GetIt.instance<MessagesRepository>();

  List<MessageEntity> _messages = [];
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    debugPrint('--- MessagesScreen Init ---');
    debugPrint('conversationId: ${widget.conversationId}');
    debugPrint('receiverId: ${widget.receiverId}');
    debugPrint('recipientName: ${widget.recipientName}');

    _currentConversationId = widget.conversationId;

    if (_currentConversationId != null && _currentConversationId!.isNotEmpty) {
      _loadMessages();
      _startPolling();
    } else if (widget.receiverId != null && widget.receiverId!.isNotEmpty) {
      _startNewConversation();
    } else {
      debugPrint('Error: Missing conversationId and receiverId');
      setState(() {
        _isLoading = false;
        _error = 'بيانات المحادثة غير مكتملة';
      });
    }
  }

  Future<void> _startNewConversation() async {
    try {
      final conv = await _messagesRepository.startConversation(
        widget.receiverId!,
      );
      if (mounted) {
        setState(() {
          _currentConversationId = conv.id;
        });
        _loadMessages();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل إنشاء محادثة: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isSending && _currentConversationId != null) {
        _loadMessages(isPolling: true);
      }
    });
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    if (!isPolling) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      if (_currentConversationId == null) return;
      final msgs = await _messagesRepository.getMessages(
        _currentConversationId!,
      );
      if (mounted) {
        final hadNewMessages = msgs.length > _messages.length;
        setState(() {
          _messages = List<MessageEntity>.from(msgs);
          _isLoading = false;
        });

        // Mark as read if we just loaded messages normally OR if polling found new ones
        if (_currentConversationId != null && (!isPolling || hadNewMessages)) {
          _messagesRepository.markAsRead(_currentConversationId!);
        }
      }
    } catch (e) {
      if (mounted && !isPolling) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الرسائل: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {String? mediaUrl}) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && mediaUrl == null) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    // Optimistic UI update
    final newMessage = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmedText,
      sender: 'أنا',
      time: DateTime.now(),
      incoming: false,
      mediaUrl: mediaUrl,
    );

    setState(() {
      _messages.insert(0, newMessage);
    });
    _controller.clear();
    // FocusScope.of(context).unfocus(); // Keep focus for better UX unless it's a small screen

    try {
      if (_currentConversationId == null && widget.receiverId != null) {
        // Wait a bit if it's still initializing, or try to initialize now
        final conv = await _messagesRepository.startConversation(
          widget.receiverId!,
        );
        _currentConversationId = conv.id;
      }

      if (_currentConversationId != null) {
        await _messagesRepository.sendMessage(
          _currentConversationId!,
          trimmedText,
        );
      } else {
        throw Exception('لم يتم العثور على محادثة');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Optional: Remove the optimistically added message on failure
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text(isArabic ? 'الكاميرا' : 'Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(isArabic ? 'معرض الصور' : 'Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        _sendMessage('', mediaUrl: image.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = widget.recipientName ?? (isArabic ? 'المشرفة' : 'Supervisor');

    final messages = _messages;
    final hasMessages = messages.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : AppColors.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        'خطأ: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : hasMessages
                  ? ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.lg,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final previous = index + 1 < messages.length
                            ? messages[index + 1]
                            : null;
                        final showDateSeparator =
                            previous == null ||
                            msg.time.day != previous.time.day ||
                            msg.time.month != previous.time.month ||
                            msg.time.year != previous.time.year;

                        final widgets = <Widget>[];

                        if (showDateSeparator) {
                          widgets.add(
                            _DateSeparator(date: msg.time, isArabic: isArabic),
                          );
                        }

                        widgets.add(
                          _MessageBubble(
                            message: msg,
                            isArabic: isArabic,
                            isParent: !msg.incoming,
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widgets,
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            matchTextDirection: true,
                            size: 48,
                            color: isDark
                                ? Colors.white38
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isArabic
                                ? 'ابدأ المراسلة مع المشرفة'
                                : 'Start chatting with the supervisor',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.white54
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
                top: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_outlined),
                    color: isDark
                        ? Colors.white54
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'اكتب رسالتك…'
                            : 'Type your message…',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              onPressed: () => _sendMessage(_controller.text),
                              icon: const Icon(
                                Icons.send_rounded,
                                matchTextDirection: true,
                                size: 22, // Increased size
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date, required this.isArabic});

  final DateTime date;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isDark = theme.brightness == Brightness.dark;
    String label;

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = isArabic ? 'اليوم' : 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = isArabic ? 'أمس' : 'Yesterday';
    } else {
      label = date_utils.formatDate(date, locale: isArabic ? 'ar' : 'en');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isArabic,
    required this.isParent,
  });

  final MessageEntity message;
  final bool isArabic;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment = isParent
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final theme = Theme.of(context);

    final bubbleColor = isParent
        ? AppColors.primary
        : (isDark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.85));

    final textColor = isParent
        ? Colors.white
        : (isDark ? Colors.white : theme.colorScheme.onSurface);

    final radius = BorderRadiusDirectional.only(
      topStart: Radius.circular(isParent ? 18 : 4),
      topEnd: Radius.circular(isParent ? 4 : 18),
      bottomStart: const Radius.circular(18),
      bottomEnd: const Radius.circular(18),
    );

    final statusIcon = isParent ? Icons.done_all_rounded : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isParent)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.28),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                  border: isParent
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isParent)
                      Text(
                        message.sender,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (!isParent) const SizedBox(height: AppSpacing.xs),
                    if (message.mediaUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: File(message.mediaUrl!).existsSync()
                              ? Image.file(
                                  File(message.mediaUrl!),
                                  height: 150,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image_rounded,
                                        size: 50,
                                        color: Colors.white70,
                                      ),
                                )
                              : const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 50,
                                  color: Colors.white70,
                                ),
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textColor),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date_utils.formatTime(
                            message.time,
                            locale: isArabic ? 'ar' : 'en',
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isParent
                                    ? Colors.white70
                                    : (isDark
                                          ? Colors.white54
                                          : theme.colorScheme.onSurfaceVariant),
                              ),
                        ),
                        if (statusIcon != null) ...[
                          const SizedBox(width: 4),
                          Icon(statusIcon, size: 14, color: Colors.white70),
                        ],
                      ],
                    ),
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
