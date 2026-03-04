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
  const MessagesScreen({super.key, this.conversationId, this.recipientName});

  final String? conversationId;
  final String? recipientName;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer; // Added for polling
  bool _isSending = false; // Added to prevent polling during send

  bool _isLoading = true; // Changed initial value from false to true
  String? _error;
  final MessagesRepository _messagesRepository = GetIt.instance<MessagesRepository>();

  List<MessageEntity> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _loadMessages();
      _startPolling(); // Start polling
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isSending) { // Only poll if not currently sending a message
        _loadMessages(isPolling: true);
      }
    });
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    if (!isPolling) { // Only show loading indicator and clear error if not polling
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final msgs = await _messagesRepository.getMessages(widget.conversationId!);
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
      }
    } catch(e) {
      if (mounted && !isPolling) { // Only show error if not polling
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الرسائل: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); // Cancel the timer
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {String? mediaUrl}) async {
    if (text.trim().isEmpty && mediaUrl == null) return;
    
    // Optimistic UI update
    final newMessage = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      sender: 'أنا',
      time: DateTime.now(),
      incoming: false,
      mediaUrl: mediaUrl,
    );

    setState(() {
      _messages.insert(0, newMessage);
    });
    _controller.clear();
    FocusScope.of(context).unfocus();

    if (widget.conversationId != null) {
      try {
        await _messagesRepository.sendMessage(widget.conversationId!, text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإرسال: $e'), backgroundColor: Colors.red));
          // Rollback could be added here
        }
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
                ? Center(child: Text('خطأ: $_error', style: const TextStyle(color: Colors.red)))
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _sendMessage(_controller.text),
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 18,
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
    final alignment = isParent ? Alignment.centerRight : Alignment.centerLeft;
    final theme = Theme.of(context);

    final bubbleColor = isParent
        ? AppColors.primary
        : (isDark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.85));

    final textColor = isParent
        ? Colors.white
        : (isDark ? Colors.white : theme.colorScheme.onSurface);

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isParent ? 18 : 4),
      topRight: Radius.circular(isParent ? 4 : 18),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
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
