import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/conversation/mute_dialog.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/more_extended_text.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../../widgets/user_selector/conversation_selector.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/message_bloc.dart';
import '../chat/chat_bar.dart';
import '../chat/chat_page.dart';
import 'shared_apps_page.dart';

class ChatInfoPage extends HookWidget {
  const ChatInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });

    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) =>
          state?.isLoaded == true && state?.conversationId == conversationId,
    )!;

    final accountServer = context.accountServer;

    final userParticipant = conversation.participant;

    useEffect(() {
      accountServer.refreshConversation(conversationId);
    }, [conversationId]);

    final userId = conversation.userId;

    useEffect(() {
      if (conversation.isGroup == true) return;
      if (userId == null) return;

      accountServer.refreshUsers([userId], force: true);
    }, [userId]);

    final announcement = useStream<String?>(
      useMemoized(() => context.database.conversationDao
          .announcement(conversationId)
          .watchSingleThrottle(kVerySlowThrottleDuration)),
    ).data;
    if (!conversation.isLoaded) return const SizedBox();

    final isGroupConversation = conversation.isGroup ?? false;
    final muting = conversation.conversation?.isMute == true;
    final isOwnerOrAdmin = userParticipant?.role == ParticipantRole.owner ||
        userParticipant?.role == ParticipantRole.admin;

    final expireIn = conversation.conversation?.expireDuration ?? Duration.zero;

    final canModifyExpireIn =
        !isGroupConversation || (isGroupConversation && isOwnerOrAdmin);

    final isExited = userParticipant == null;
    return Scaffold(
      appBar: MixinAppBar(
        actions: [
          if (ModalRoute.of(context)?.canPop != true)
            ActionButton(
              name: Resources.assetsImagesIcCloseSvg,
              color: context.theme.icon,
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
        backgroundColor: context.theme.popUp,
      ),
      backgroundColor: context.theme.popUp,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ConversationAvatar(
              conversationState: conversation,
              size: 90,
            ),
            const SizedBox(height: 10),
            ConversationName(
              conversationState: conversation,
              fontSize: 18,
              overflow: false,
            ),
            const SizedBox(height: 4),
            ConversationIDOrCount(
              conversationState: conversation,
              fontSize: 12,
            ),
            _AddToContactsButton(conversation),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              child: ConversationBio(
                conversationId: conversationId,
                userId: conversation.userId,
                isGroup: conversation.isGroup!,
              ),
            ),
            const SizedBox(height: 32),
            if (isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(
                    context.l10n.groupParticipants,
                  ),
                  onTap: () => context
                      .read<ChatSideCubit>()
                      .pushPage(ChatSideCubit.participants),
                ),
              ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.shareContact),
                  onTap: () async {
                    final result = await showConversationSelector(
                      context: context,
                      singleSelect: true,
                      title: context.l10n.shareContact,
                      onlyContact: false,
                    );

                    if (result == null || result.isEmpty) return;
                    final conversationId = result.first.conversationId;

                    await runFutureWithToast(
                        context,
                        accountServer.sendContactMessage(
                          conversation.userId!,
                          conversation.name,
                          result.first.encryptCategory!,
                          conversationId: conversationId,
                          recipientId: result.first.userId,
                        ));
                  },
                ),
              ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CellItem(
                    title: Text(context.l10n.sharedMedia),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.sharedMedia),
                  ),
                  if (conversation.userId != null)
                    _SharedApps(userId: conversation.userId!),
                  CellItem(
                    title: Text(
                      context.l10n.searchConversation,
                      maxLines: 1,
                    ),
                    onTap: () => context
                        .read<ChatSideCubit>()
                        .pushPage(ChatSideCubit.searchMessageHistory),
                  ),
                ],
              ),
            ),
            if (!(isGroupConversation && isExited))
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.disappearingMessage),
                  description: Text(
                    expireIn.formatAsConversationExpireIn(
                      localization: context.l10n,
                    ),
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  trailing: canModifyExpireIn ? const Arrow() : null,
                  onTap: !canModifyExpireIn
                      ? null
                      : () => context
                          .read<ChatSideCubit>()
                          .pushPage(ChatSideCubit.disappearMessages),
                ),
              ),
            if (isGroupConversation && isOwnerOrAdmin)
              CellGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final announcementTitle = announcement?.isEmpty ?? true
                          ? context.l10n.addGroupDescription
                          : context.l10n.editGroupDescription;
                      return CellItem(
                        title: Text(announcementTitle),
                        onTap: () async {
                          final result = await showMixinDialog<String>(
                            context: context,
                            child: EditDialog(
                              title: Text(announcementTitle),
                              editText: announcement ?? '',
                              maxLines: 7,
                            ),
                          );
                          if (result == null) return;

                          await runFutureWithToast(
                            context,
                            context.accountServer.editGroup(
                              conversationId,
                              announcement: result,
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            CellGroup(
              child: Column(
                children: [
                  if (!(isGroupConversation && isExited))
                    CellItem(
                      title: Text(
                          muting ? context.l10n.unmute : context.l10n.mute),
                      description: muting
                          ? Text(
                              DateFormat('yyyy/MM/dd, hh:mm a').format(
                                  conversation.conversation!.validMuteUntil!
                                      .toLocal()),
                              style: TextStyle(
                                color: context.theme.secondaryText,
                                fontSize: 14,
                              ),
                            )
                          : null,
                      trailing: null,
                      onTap: () async {
                        if (muting) {
                          await runFutureWithToast(
                            context,
                            context.accountServer.unMuteConversation(
                              conversationId:
                                  isGroupConversation ? conversationId : null,
                              userId: isGroupConversation
                                  ? null
                                  : conversation.userId,
                            ),
                          );
                          return;
                        }

                        final result = await showMixinDialog<int?>(
                            context: context, child: const MuteDialog());
                        if (result == null) return;

                        await runFutureWithToast(
                            context,
                            context.accountServer.muteConversation(
                              result,
                              conversationId:
                                  isGroupConversation ? conversationId : null,
                              userId: isGroupConversation
                                  ? null
                                  : conversation.userId,
                            ));
                      },
                    ),
                  if (!isGroupConversation ||
                      (isGroupConversation && isOwnerOrAdmin))
                    CellItem(
                      title: Text(context.l10n.editName),
                      trailing: null,
                      onTap: () async {
                        final name = await showMixinDialog<String>(
                          context: context,
                          child: EditDialog(
                            editText: conversation.name ?? '',
                            title: Text(context.l10n.editName),
                            hintText: context.l10n.groupName,
                            positiveAction: context.l10n.change,
                          ),
                        );
                        if (name?.isEmpty ?? true) return;

                        await runFutureWithToast(
                          context,
                          isGroupConversation
                              ? accountServer.editGroup(
                                  conversation.conversationId,
                                  name: name,
                                )
                              : accountServer.editContactName(
                                  conversation.userId!, name!),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.groupsInCommon),
                  onTap: () => context
                      .read<ChatSideCubit>()
                      .pushPage(ChatSideCubit.groupsInCommon),
                ),
              ),
            if (conversation.app?.creatorId != null)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.developer),
                  trailing: null,
                  onTap: () =>
                      showUserDialog(context, conversation.app?.creatorId),
                ),
              ),
            CellGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conversation.relationship == UserRelationship.blocking)
                    CellItem(
                      title: Text(context.l10n.unblock),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.unblock,
                        );
                        if (!result) return;

                        await runFutureWithToast(
                          context,
                          accountServer.unblockUser(conversation.userId!),
                        );
                      },
                    ),
                  if (!isGroupConversation && !conversation.isStranger!)
                    Builder(builder: (context) {
                      final title = conversation.isBot!
                          ? context.l10n.removeBot
                          : context.l10n.removeContact;
                      return CellItem(
                        title: Text(title),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            title,
                          );
                          if (!result) return;

                          await runFutureWithToast(
                            context,
                            accountServer.removeUser(conversation.userId!),
                          );
                        },
                      );
                    }),
                  if (conversation.isStranger!)
                    CellItem(
                      title: Text(context.l10n.block),
                      color: context.theme.red,
                      trailing: null,
                      onTap: () async {
                        final result = await showConfirmMixinDialog(
                          context,
                          context.l10n.block,
                        );
                        if (!result) return;

                        await runFutureWithToast(
                          context,
                          accountServer.blockUser(conversation.userId!),
                        );
                      },
                    ),
                  CellItem(
                    title: Text(context.l10n.clearChat),
                    color: context.theme.red,
                    trailing: null,
                    onTap: () async {
                      final result = await showConfirmMixinDialog(
                        context,
                        context.l10n.clearChat,
                      );
                      if (!result) return;

                      await accountServer.database.messageDao
                          .deleteMessageByConversationId(conversationId);
                      context.read<MessageBloc>().reload();
                    },
                  ),
                  if (isGroupConversation)
                    if (!isExited)
                      CellItem(
                        title: Text(context.l10n.exitGroup),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            context.l10n.exitGroup,
                          );
                          if (!result) return;

                          await runFutureWithToast(
                            context,
                            accountServer.exitGroup(conversationId),
                          );

                          await ConversationCubit.selectConversation(
                            context,
                            conversationId,
                          );
                        },
                      )
                    else
                      CellItem(
                        title: Text(context.l10n.deleteGroup),
                        color: context.theme.red,
                        trailing: null,
                        onTap: () async {
                          final result = await showConfirmMixinDialog(
                            context,
                            context.l10n.deleteGroup,
                          );
                          if (!result) return;

                          await context.database.messageDao
                              .deleteMessageByConversationId(conversationId);
                          await context.database.conversationDao
                              .deleteConversation(
                            conversationId,
                          );
                          if (context
                                  .read<ConversationCubit>()
                                  .state
                                  ?.conversationId ==
                              conversationId) {
                            context.read<ConversationCubit>().unselected();
                          }
                        },
                      ),
                ],
              ),
            ),
            if (!isGroupConversation)
              CellGroup(
                child: CellItem(
                  title: Text(context.l10n.report),
                  color: context.theme.red,
                  trailing: null,
                  onTap: () async {
                    final result = await showConfirmMixinDialog(
                      context,
                      context.l10n.reportAndBlock,
                    );
                    if (!result) return;
                    final userId = conversation.userId;
                    if (userId == null) return;

                    await runFutureWithToast(
                      context,
                      accountServer.report(userId),
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

class ConversationBio extends HookWidget {
  const ConversationBio({
    super.key,
    this.fontSize = 14,
    required this.conversationId,
    required this.userId,
    required this.isGroup,
  });

  final double fontSize;
  final String conversationId;
  final String? userId;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final textStream = useMemoized(() {
      final database = context.database;
      if (isGroup) {
        return database.conversationDao
            .announcement(conversationId)
            .watchSingleThrottle(kVerySlowThrottleDuration);
      }
      return database.userDao
          .biography(userId!)
          .watchSingleThrottle(kVerySlowThrottleDuration);
    }, [
      conversationId,
      userId,
      isGroup,
    ]);

    final text = useStream(textStream, initialData: '').data!;
    if (text.isEmpty) return const SizedBox();

    return MoreExtendedText(
      text,
      style: TextStyle(
        color: context.theme.text,
        fontSize: fontSize,
      ),
    );
  }
}

/// Button to add strange to contacts.
///
/// if conversation is not stranger, show nothing.
class _AddToContactsButton extends StatelessWidget {
  _AddToContactsButton(
    this.conversation,
  ) : assert(conversation.isLoaded);
  final ConversationState conversation;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: conversation.isStranger!
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.theme.statusBackground,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                  onPressed: () {
                    final username = conversation.user?.fullName ??
                        conversation.conversation?.validName;
                    assert(username != null,
                        'ContactsAdd: username should not be null.');
                    assert(conversation.isGroup != true,
                        'ContactsAdd conversation should not be a group.');
                    runFutureWithToast(
                        context,
                        context.accountServer.addUser(
                          conversation.userId!,
                          username,
                        ));
                  },
                  child: Text(
                    conversation.isBot!
                        ? context.l10n.addBotWithPlus
                        : context.l10n.addContactWithPlus,
                    style: TextStyle(fontSize: 12, color: context.theme.accent),
                  ),
                ),
              )
            : const SizedBox(height: 0),
      );
}

class _SharedApps extends HookWidget {
  const _SharedApps({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      context.accountServer.loadFavoriteApps(userId);
    }, [userId]);

    final apps = useMemoizedStream(
        () => context.database.favoriteAppDao
            .getFavoriteAppsByUserId(userId)
            .watch(),
        keys: [userId]);

    final data = apps.data ?? const [];
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: data.isEmpty
          ? const SizedBox()
          : CellItem(
              title: Text(context.l10n.shareApps),
              trailing: OverlappedAppIcons(apps: data),
              onTap: () => context
                  .read<ChatSideCubit>()
                  .pushPage(ChatSideCubit.sharedApps),
            ),
    );
  }
}
