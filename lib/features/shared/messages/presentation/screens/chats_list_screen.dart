import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/theme/brand_colors.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';

/// Model for a conversation in the chats list
class ConversationItem {
  final String id;
  final String parentName;
  final String studentName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;

  const ConversationItem({
    required this.id,
    required this.parentName,
    required this.studentName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
  });
}

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  // Mock data for conversations
  final List<ConversationItem> _conversations = [
    ConversationItem(
      id: '1',
      parentName: 'أحمد محمد',
      studentName: 'يوسف أحمد',
      lastMessage: 'شكراً لكم على الاهتمام بابني',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    ConversationItem(
      id: '2',
      parentName: 'فاطمة علي',
      studentName: 'سارة علي',
      lastMessage: 'متى ستصل الحافلة؟',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
    ),
    ConversationItem(
      id: '3',
      parentName: 'محمد خالد',
      studentName: 'عمر محمد',
      lastMessage: 'تم الوصول بسلامة',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Platform.isAndroid
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isArabic ? 'المحادثات' : 'Chats',
                      style: TextStyle(
                        height: 1.2,
                        color: isDark ? Colors.white : BrandColors.textPrimary,
                      ),
                    ),
                  )
                : Text(
                    isArabic ? 'المحادثات' : 'Chats',
                    style: TextStyle(
                      color: isDark ? Colors.white : BrandColors.textPrimary,
                    ),
                  ),
            backgroundColor: theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
                width: 0.0,
              ),
            ),
            leading: Material(
              color: Colors.transparent,
              child: BackButton(
                color: isDark ? Colors.white : BrandColors.primary,
              ),
            ),
            trailing: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsFill.plusCircle,
                  color: BrandColors.primary,
                  size: 28,
                ),
                onPressed: () => _showNewChatDialog(context),
              ),
            ),
          ),
          if (_conversations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIconsRegular.chats,
                      size: 64,
                      color: isDark
                          ? Colors.white38
                          : BrandColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isArabic ? 'لا توجد محادثات' : 'No conversations yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? Colors.white54
                            : BrandColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isArabic
                          ? 'اضغط على + لبدء محادثة جديدة'
                          : 'Tap + to start a new conversation',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white38
                            : BrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final conversation = _conversations[index];
                  return _ConversationTile(
                    conversation: conversation,
                    onTap: () => context.push(
                      AppRoutes.messages,
                      extra: conversation.parentName,
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                }, childCount: _conversations.length),
              ),
            ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Mock list of parents to choose from
    final parents = [
      {'name': 'أحمد محمد', 'student': 'يوسف أحمد'},
      {'name': 'فاطمة علي', 'student': 'سارة علي'},
      {'name': 'محمد خالد', 'student': 'عمر محمد'},
      {'name': 'نورة سعيد', 'student': 'خالد سعيد'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isArabic ? 'بدء محادثة جديدة' : 'Start New Chat',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              ...parents.map(
                (parent) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BrandColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      PhosphorIconsRegular.user,
                      color: BrandColors.primary,
                    ),
                  ),
                  title: Text(parent['name']!),
                  subtitle: Text(
                    isArabic
                        ? 'ولي أمر ${parent['student']}'
                        : 'Parent of ${parent['student']}',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.messages, extra: parent['name']);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: hasUnread ? 0.08 : 0.03)
            : (hasUnread
                  ? BrandColors.primary.withValues(alpha: 0.05)
                  : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : (hasUnread
                    ? BrandColors.primary.withValues(alpha: 0.2)
                    : BrandColors.border),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: BrandColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage: conversation.avatarUrl != null
                          ? NetworkImage(conversation.avatarUrl!)
                          : null,
                      child: conversation.avatarUrl == null
                          ? Icon(
                              PhosphorIconsRegular.user,
                              color: BrandColors.primary,
                              size: 28,
                            )
                          : null,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: BrandColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.parentName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageTime, isArabic),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasUnread
                                  ? BrandColors.primary
                                  : (isDark
                                        ? Colors.white54
                                        : BrandColors.textSecondary),
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'ولي أمر ${conversation.studentName}'
                            : 'Parent of ${conversation.studentName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white54
                              : BrandColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasUnread
                              ? (isDark
                                    ? Colors.white
                                    : BrandColors.textPrimary)
                              : (isDark
                                    ? Colors.white54
                                    : BrandColors.textSecondary),
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Now';
    } else if (diff.inMinutes < 60) {
      return isArabic ? '${diff.inMinutes} د' : '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return isArabic ? '${diff.inHours} س' : '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return isArabic ? '${diff.inDays} ي' : '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
