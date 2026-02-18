import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
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
          AdaptiveSliverAppBar(
            title: isArabic ? 'المحادثات' : 'Chats',
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
            trailing: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  PhosphorIconsRegular.pencilSimple,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                onPressed: () => _showNewChatDialog(context),
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
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
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isArabic ? 'لا توجد محادثات' : 'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark
                            ? Colors.white54
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isArabic
                          ? 'اضغط على ✏️ لبدء محادثة جديدة'
                          : 'Tap ✏️ to start a new conversation',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white38
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final conversation = _conversations[index];
                return Column(
                  children: [
                    _ConversationTile(
                          conversation: conversation,
                          onTap: () => context.push(
                            AppRoutes.messages,
                            extra: conversation.parentName,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.05),
                    if (index < _conversations.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 76,
                        endIndent: 16,
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }, childCount: _conversations.length),
            ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    // ... items ...
    _mockShowDialog(context); // Helper for brevity, keeping existing logic
  }

  void _mockShowDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              ...parents.map((parent) {
                final theme = Theme.of(ctx);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.user,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(parent['name']!, style: TextStyle()),
                  subtitle: Text(
                    isArabic
                        ? 'ولي أمر ${parent['student']}'
                        : 'Parent of ${parent['student']}',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.messages, extra: parent['name']);
                  },
                );
              }),
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
    // final isDark = theme.brightness == Brightness.dark; // Unused in new design
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: conversation.avatarUrl != null
                        ? NetworkImage(conversation.avatarUrl!)
                        : null,
                    child: conversation.avatarUrl == null
                        ? Text(
                            conversation.parentName.characters.first,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.parentName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conversation.lastMessageTime, isArabic),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

  String _formatTime(DateTime time, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final isYesterday = now.day - time.day == 1;

    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Now';
    } else if (diff.inHours < 1 && diff.inMinutes > 0) {
      // Just time "10:30" style usually better for today
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inHours < 24 && now.day == time.day) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return isArabic ? 'أمس' : 'Yesterday';
    } else if (diff.inDays < 7) {
      // Day name
      return isArabic
          ? '${diff.inDays} يوم'
          : '${diff.inDays}d'; // Simplified for now
    } else {
      return '${time.day}/${time.month}/${time.year % 100}';
    }
  }
}
