import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/bloc/slide_category_cubit.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';
import 'package:flutter_app/utils/message_optimize.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import 'account_server.dart';

class NotificationService extends WidgetsBindingObserver {
  NotificationService({
    required BuildContext context,
  }) {
    assert(WidgetsBinding.instance != null);
    WidgetsBinding.instance!.addObserver(this);
    streamSubscriptions
      ..add(context
          .read<AccountServer>()
          .database
          .messagesDao
          .notificationMessageStream
          .where((event) {
            if (active) {
              final conversationState = context.read<ConversationCubit>().state;
              return event.conversationId !=
                  (conversationState?.conversationId ??
                      conversationState?.conversation?.conversationId);
            }
            return true;
          })
          .where(
              (event) => event.userId != context.read<AccountServer>().userId)
          .where((event) => event.muteUntil?.isAfter(DateTime.now()) != true)
          .asyncMap((event) async {
            final name = conversationValidName(
              event.groupName,
              event.userFullName,
            );

            String? body;
            if (context.read<MultiAuthCubit>().state.currentMessagePreview)
              body = (await messageOptimize(
                event.status,
                event.type,
                event.content,
                false,
              ))
                  .item2;

            await LocalNotificationCenter.showNotification(
              title: name,
              body: body,
              uri: Uri(
                scheme: EnumToString.convertToString(
                    NotificationScheme.conversation),
                host: event.conversationId,
                path: event.messageId,
              ),
            );
          })
          .listen((_) {}))
      ..add(
        LocalNotificationCenter.notificationSelectEvent(
                NotificationScheme.conversation)
            .listen(
          (event) {
            final slideCategoryCubit = context.read<SlideCategoryCubit>();
            if (slideCategoryCubit.state.type == SlideCategoryType.setting)
              slideCategoryCubit.select(SlideCategoryType.chats);
            context
                .read<ConversationCubit>()
                .selectConversation(event.host, event.path);
          },
        ),
      );
  }

  List<StreamSubscription> streamSubscriptions = [];
  bool active = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
  }

  Future<void> close() async {
    await Future.wait(streamSubscriptions.map((e) => e.cancel()));
    WidgetsBinding.instance!.removeObserver(this);
  }
}