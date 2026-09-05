import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:msaratwasel_services/core/services/reverb_service.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/entities/contact_entity.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/entities/conversation_entity.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/entities/message_entity.dart';
import 'package:msaratwasel_services/features/shared/messages/domain/repositories/messages_repository.dart';
import 'package:msaratwasel_services/features/shared/messages/presentation/screens/chats_list_screen.dart';
import 'package:msaratwasel_services/features/shared/messages/presentation/screens/messages_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  FakeAuthCubit() : super(AuthInitial());

  @override
  ReverbService? get reverbService => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMessagesRepository implements MessagesRepository {
  List<ConversationEntity> conversations = [];
  List<MessageEntity> messages = [];
  List<ContactEntity> contacts = [];
  bool shouldThrowConversations = false;
  bool shouldThrowMessages = false;
  String? lastSentText;
  String? lastSentConversationId;
  String? lastMarkedReadId;
  String? lastStartedReceiverId;

  @override
  Future<List<ConversationEntity>> getConversations() async {
    if (shouldThrowConversations) throw Exception('Failed to load conversations');
    return conversations;
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    if (shouldThrowMessages) throw Exception('Failed to load messages');
    return messages;
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    lastSentConversationId = conversationId;
    lastSentText = text;
  }

  @override
  Future<List<ContactEntity>> getContacts() async {
    return contacts;
  }

  @override
  Future<ConversationEntity> startConversation(String receiverId) async {
    lastStartedReceiverId = receiverId;
    return ConversationEntity(
      id: 'conv_started_10',
      parentName: 'ولي الأمر الجديد',
      studentName: 'الطالب الجديد',
      lastMessage: 'أهلاً بك',
      lastMessageTime: DateTime.now(),
    );
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    lastMarkedReadId = conversationId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMessagesRepository fakeRepository;
  late FakeAuthCubit fakeAuthCubit;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    fakeRepository = FakeMessagesRepository();
    fakeAuthCubit = FakeAuthCubit();

    if (GetIt.I.isRegistered<MessagesRepository>()) {
      GetIt.I.unregister<MessagesRepository>();
    }
    GetIt.I.registerSingleton<MessagesRepository>(fakeRepository);
  });

  tearDown(() async {
    await fakeAuthCubit.close();
    await GetIt.I.reset();
  });

  Widget wrapWithProviders(Widget child) {
    return BlocProvider<AuthCubit>.value(
      value: fakeAuthCubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('ChatsListScreen Suite', () {
    testWidgets('1. Renders conversations list with unread badges', (tester) async {
      fakeRepository.conversations = [
        ConversationEntity(
          id: 'c1',
          parentName: 'خالد النبهاني',
          studentName: 'محمد خالد',
          lastMessage: 'هل الباص في الطريق؟',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: 3,
        ),
        ConversationEntity(
          id: 'c2',
          parentName: 'سعود المعولي',
          studentName: 'فيصل سعود',
          lastMessage: 'شكراً جزيلاً',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
          unreadCount: 0,
        ),
      ];

      await tester.pumpWidget(wrapWithProviders(const ChatsListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('خالد النبهاني'), findsOneWidget);
      expect(find.text('هل الباص في الطريق؟'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      expect(find.text('سعود المعولي'), findsOneWidget);
      expect(find.text('شكراً جزيلاً'), findsOneWidget);
    });

    testWidgets('2. Renders empty state when conversations is empty', (tester) async {
      fakeRepository.conversations = [];

      await tester.pumpWidget(wrapWithProviders(const ChatsListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد محادثات'), findsOneWidget);
    });

    testWidgets('3. Renders error state and allows retry', (tester) async {
      fakeRepository.shouldThrowConversations = true;

      await tester.pumpWidget(wrapWithProviders(const ChatsListScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('خطأ'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      // Now fix error and retry
      fakeRepository.shouldThrowConversations = false;
      fakeRepository.conversations = [
        ConversationEntity(
          id: 'c_retry',
          parentName: 'أم مريم',
          studentName: 'مريم',
          lastMessage: 'مرحباً',
          lastMessageTime: DateTime.now(),
        ),
      ];

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();

      expect(find.text('أم مريم'), findsOneWidget);
    });

    testWidgets('4. Tapping new chat button opens contacts modal', (tester) async {
      fakeRepository.conversations = [];
      fakeRepository.contacts = [
        ContactEntity(
          id: 'contact_1',
          name: 'أبو أحمد',
          description: 'ولي أمر - الصف الثاني',
        ),
      ];

      await tester.pumpWidget(wrapWithProviders(const ChatsListScreen()));
      await tester.pumpAndSettle();

      // Tap pencil icon (new chat)
      final fallbackPencil = find.byType(IconButton).last;
      await tester.tap(fallbackPencil);
      await tester.pumpAndSettle();

      expect(find.text('بدء محادثة جديدة'), findsOneWidget);
      expect(find.text('أبو أحمد'), findsOneWidget);
    });
  });

  group('MessagesScreen Suite', () {
    testWidgets('1. Loads and renders incoming and outgoing messages and sends message', (tester) async {
      fakeRepository.messages = [
        MessageEntity(
          id: 'm1',
          text: 'صباح الخير، متى سيصل الباص؟',
          sender: 'ولي الأمر',
          time: DateTime.now().subtract(const Duration(minutes: 10)),
          incoming: true,
        ),
        MessageEntity(
          id: 'm2',
          text: 'خلال خمس دقائق إن شاء الله',
          sender: 'المشرفة',
          time: DateTime.now().subtract(const Duration(minutes: 8)),
          incoming: false,
        ),
      ];

      await tester.pumpWidget(
        wrapWithProviders(
          const MessagesScreen(
            conversationId: 'conv_1',
            recipientName: 'ولي أمر الطالب أحمد',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ولي أمر الطالب أحمد'), findsOneWidget);
      expect(find.text('صباح الخير، متى سيصل الباص؟'), findsOneWidget);
      expect(find.text('خلال خمس دقائق إن شاء الله'), findsOneWidget);
      expect(fakeRepository.lastMarkedReadId, 'conv_1');

      // Send a new message
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, 'وصلنا للمحطة القادمة');
      await tester.pumpAndSettle();

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.lastSentText, 'وصلنا للمحطة القادمة');
      expect(find.text('وصلنا للمحطة القادمة'), findsOneWidget);
    });

    testWidgets('2. Starts new conversation when only receiverId is provided', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const MessagesScreen(
            receiverId: 'parent_user_99',
            recipientName: 'أم سالم',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeRepository.lastStartedReceiverId, 'parent_user_99');
    });

    testWidgets('3. Displays error message when conversationId and receiverId are missing', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const MessagesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('بيانات المحادثة غير مكتملة'), findsOneWidget);
    });
  });
}
