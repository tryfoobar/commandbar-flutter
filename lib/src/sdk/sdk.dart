import 'package:flutter/widgets.dart' show Widget;

import './command.dart';

class InstanceAttributes {
  final String? hmac;

  InstanceAttributes({this.hmac});

  Map toJson() => {
        'hmac': hmac,
      };
}

typedef CallbackArguments = Map<String, Object?>;
typedef Context = Map<String, Object?>;
typedef Callback = Function(CallbackArguments args, Context context);

typedef RouterFn = Function(String url);

class CommandBarInstance {
  Widget widget;
  CommandBarSDK commandBar;

  CommandBarInstance({required this.widget, required this.commandBar});
}

abstract class CommandBarSDK {
  Future<void> boot(
      {String? userId,
      Map? userAttributes,
      InstanceAttributes? instanceAttributes});

  Future<void> setTheme(String slug);

  Future<void> addRouter(RouterFn myRouter);

  Future<void> addCallback(String callbackKey, Callback callback);
  Future<void> removeCallback(String callbackKey);

  Future<void> addCommand(Command command);
  Future<void> removeCommand(String commandName);

  Future<void> addRecords(String key, List<dynamic> records);
  Future<void> addRecordAction(String key, Command recordAction);
  Future<void> addMetadata(String key, dynamic value);

  // widget management
  void open();
  void close();
  void toggle();
}
