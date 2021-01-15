// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static m0(name) => "确定删除${name}圈子吗？";

  static m1(date) => "${date}加入";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("关于"),
    "appearance" : MessageLookupByLibrary.simpleMessage("显示偏好"),
    "bots" : MessageLookupByLibrary.simpleMessage("机器人"),
    "cancel" : MessageLookupByLibrary.simpleMessage("取消"),
    "chatBackup" : MessageLookupByLibrary.simpleMessage("聊天记录备份"),
    "circle" : MessageLookupByLibrary.simpleMessage("圈子"),
    "contacts" : MessageLookupByLibrary.simpleMessage("联系人"),
    "copy" : MessageLookupByLibrary.simpleMessage("复制"),
    "dataAndStorageUsage" : MessageLookupByLibrary.simpleMessage("数据和存储使用情况"),
    "delete" : MessageLookupByLibrary.simpleMessage("删除"),
    "deleteChat" : MessageLookupByLibrary.simpleMessage("删除对话"),
    "deleteCircle" : MessageLookupByLibrary.simpleMessage("删除圈子"),
    "editCircleName" : MessageLookupByLibrary.simpleMessage("编辑圈子名称"),
    "editConversations" : MessageLookupByLibrary.simpleMessage("编辑会话"),
    "editProfile" : MessageLookupByLibrary.simpleMessage("编辑资料"),
    "forward" : MessageLookupByLibrary.simpleMessage("转发"),
    "group" : MessageLookupByLibrary.simpleMessage("群组"),
    "initializing" : MessageLookupByLibrary.simpleMessage("初始化"),
    "introduction" : MessageLookupByLibrary.simpleMessage("介绍"),
    "mute" : MessageLookupByLibrary.simpleMessage("静音"),
    "name" : MessageLookupByLibrary.simpleMessage("名字"),
    "noData" : MessageLookupByLibrary.simpleMessage("没有数据"),
    "notification" : MessageLookupByLibrary.simpleMessage("通知"),
    "pageDeleteCircle" : m0,
    "pageEditProfileJoin" : m1,
    "pageLandingClickToReload" : MessageLookupByLibrary.simpleMessage("点击重新加载 QrCode"),
    "pageLandingLoginMessage" : MessageLookupByLibrary.simpleMessage("打开手机上的 Mixin Messenger，扫描屏幕上的 QrCode，确认登录。"),
    "pageLandingLoginTitle" : MessageLookupByLibrary.simpleMessage("通过 QrCode 登录 Mixin Messenger"),
    "pageRightEmptyMessage" : MessageLookupByLibrary.simpleMessage("选择一个对话，开始发送信息"),
    "phoneNumber" : MessageLookupByLibrary.simpleMessage("手机号"),
    "pin" : MessageLookupByLibrary.simpleMessage("置顶"),
    "pleaseWait" : MessageLookupByLibrary.simpleMessage("请稍等一下"),
    "provisioning" : MessageLookupByLibrary.simpleMessage("处理中"),
    "reply" : MessageLookupByLibrary.simpleMessage("回复"),
    "save" : MessageLookupByLibrary.simpleMessage("保存"),
    "search" : MessageLookupByLibrary.simpleMessage("搜索"),
    "signOut" : MessageLookupByLibrary.simpleMessage("登出"),
    "strangers" : MessageLookupByLibrary.simpleMessage("陌生人"),
    "unMute" : MessageLookupByLibrary.simpleMessage("取消静音"),
    "unPin" : MessageLookupByLibrary.simpleMessage("取消置顶")
  };
}