import 'package:flutter/material.dart';
import 'package:msaratwasel_services/core/presentation/widgets/main_shell.dart';
import 'package:msaratwasel_services/core/presentation/widgets/adaptive_sliver_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_services/config/theme/app_spacing.dart';
import 'package:msaratwasel_services/config/routes/app_routes.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/messages_repository.dart';
import 'package:get_it/get_it.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  List<ConversationEntity> _conversations = [];
  bool _isLoading = true;
  String? _error;
  final MessagesRepository _messagesRepository = GetIt.instance<MessagesRepository>();

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final conversations = await _messagesRepository.getConversations();
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطأ: $_error', style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: _fetchConversations,
                      child: const Text('إعادة المحاولة'),
                    )
                  ],
                ),
              ),
            )
          else if (_conversations.isEmpty)
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
                          onTap: () {
                            setState(() {
                              conversation.unreadCount = 0;
                            });
                            context.push(
                              AppRoutes.messages,
                              extra: {
                                'id': conversation.id,
                                'name': conversation.parentName,
                              },
                            ).then((_) => _fetchConversations());
                          },
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NewChatDialog(messagesRepository: _messagesRepository),
    );
  }
}

class _NewChatDialog extends StatefulWidget {
  final MessagesRepository messagesRepository;
  const _NewChatDialog({required this.messagesRepository});

  @override
  State<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  List<ContactEntity> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final contacts = await widget.messagesRepository.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('خطأ: $_error', style: const TextStyle(color: Colors.red)))
                      : _contacts.isEmpty
                          ? Center(child: Text(isArabic ? 'لا توجد جهات اتصال' : 'No contacts available'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _contacts.length,
                              itemBuilder: (context, index) {
                                final contact = _contacts[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    backgroundImage: contact.avatarUrl != null ? NetworkImage(contact.avatarUrl!) : null,
                                    child: contact.avatarUrl == null
                                        ? Icon(PhosphorIconsRegular.user, color: theme.colorScheme.primary)
                                        : null,
                                  ),
                                  title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    contact.description,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.push(
                                      AppRoutes.messages,
                                      extra: {
                                        'id': null, // New chat
                                        'name': contact.name,
                                        'receiverId': contact.id, // We need to pass receiverId
                                      },
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
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
