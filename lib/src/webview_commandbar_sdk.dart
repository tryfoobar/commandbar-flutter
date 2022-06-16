import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'callback_message.dart';
import 'sdk/command.dart';
import 'sdk/sdk.dart';

class JavascriptExpressionLiteral {
  String js;

  JavascriptExpressionLiteral(this.js);
}

class WebViewCommandBarSDK extends CommandBarSDK {
  final log = Logger('WebViewCommandBarSDK');

  final Future<WebViewController> cbWebViewController;
  final PanelController cbPanelController;

  Map<String, Function> callbackMap = {};
  Map<String, Command> commandMap = {};
  RouterFn? router;
  Map<String, Command> recordsActionMap = {};

  WebViewCommandBarSDK(this.cbWebViewController, this.cbPanelController);

  Future<void> runJavascript(String js) async {
    log.fine("About to run JS in WebView:");
    log.fine(js);
    return (await cbWebViewController).runJavascript(js);
  }

  Future<void> _call(String method, List<Object?> arguments) {
    var argumentsJsonEncoded = (arguments.map((argument) =>
        argument is JavascriptExpressionLiteral
            ? argument.js
            : jsonEncode(argument)));

    var argumentsJson = '[${argumentsJsonEncoded.join(',')}]';
    var methodJson = jsonEncode(method);

    var js = 'window.CommandBar[$methodJson](...$argumentsJson)';
    return runJavascript(js);
  }

  @override
  Future<void> boot(
      {String? userId,
      Map? userAttributes,
      InstanceAttributes? instanceAttributes}) {
    return _call('boot', [userId, userAttributes, instanceAttributes]);
  }

  @override
  Future<void> setTheme(String slug) => _call('setTheme', [slug]);

  @override
  Future<void> addRouter(RouterFn myRouter) => _call('addRouter', [
        JavascriptExpressionLiteral('''
          (url) => {   
            try {
              CommandBarRouterChannel.postMessage(url);
            }   catch (e) {

            }
          }''')
      ]);

  @override
  Future<void> addCallback(
      String callbackKey,
      Function(Map<String, Object?> args, Map<String, Object?> context)
          callback) async {
    await _call('addCallback', [
      callbackKey,
      JavascriptExpressionLiteral('''
        (args, context) => {  
          const message = {
            callbackKey: ${jsonEncode(callbackKey)},
            args, 
            context,
          };
          
          CommandBarCallbacksChannel.postMessage(JSON.stringify(message));
        }''')
    ]);

    callbackMap[callbackKey] = callback;
  }

  @override
  Future<void> removeCallback(String callbackKey) async {
    await _call('removeCallback', [callbackKey]);

    callbackMap.remove(callbackKey);
  }

  void runCallback(String callbackKey, dynamic args, dynamic context) {
    if (callbackMap.containsKey(callbackKey)) {
      var callback = callbackMap[callbackKey];

      callback!(args, context);

      // Close CommandBar after callback is executed
      close();

      // Reinitialize CommandBar. For sore reason it has no effect when called from `open` or `close` methods
      //return runJavascript('window.CommandBar.open();');
    }
  }

  @override
  Future<void> addCommand(Command command) async {
    await _call('addCommand', [command]);

    commandMap[command.name] = command;
  }

  @override
  Future<void> removeCommand(String commandName) async {
    await _call('removeCommand', [commandName]);

    commandMap.remove(commandName);
  }

  @override
  Future<void> addRecords(String key, List<dynamic> records) =>
      _call('addRecords', [key, records]);

  @override
  Future<void> addRecordAction(String key, Command recordAction) async {
    await _call('addRecordAction', [key, recordAction]);

    recordsActionMap[key] = recordAction;
  }

  @override
  Future<void> addMetadata(String key, dynamic value) =>
      _call('addMetadata', [key, value]);

  @override
  void open() {
    cbPanelController.open();
  }

  @override
  void close() {
    cbPanelController.close();
  }

  @override
  void toggle() {
    if (cbPanelController.isPanelOpen) {
      cbPanelController.close();
    } else {
      cbPanelController.open();
    }
  }

  void onClose() {
    runJavascript('''
      window.scrollTo(0,0); 
      document.activeElement.blur();
    ''');
  }

  void onOpen() {
    runJavascript('''
      window.CommandBar.open(); 
      window.scrollTo(0,0);
    ''');
  }

  void handleCallback(CallbackMessage message) {
    if (callbackMap.containsKey(message.callbackKey)) {
      runCallback(message.callbackKey, message.args, message.context);
    }
  }
}
