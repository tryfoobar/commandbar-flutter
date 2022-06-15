import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sdk/sdk.dart';

import 'util/keep_alive_page.dart';

import 'callback_message.dart';
import 'webview_commandbar_sdk.dart';

class CommandBar {
  static CommandBarInstance initialize({Key? key, required String orgId}) {
    var widget = CommandBarWidget._(key: key, orgId: orgId);

    return CommandBarInstance(widget: widget, commandBar: widget.commandBar);
  }
}

// TODO: make this a stateful widget so it can have error (and loading?) states
class CommandBarWidget extends StatelessWidget {
  final log = Logger('CommandBarWidget');

  final String orgId;

  final panelController = PanelController();

  final webViewController = Completer<WebViewController>();
  final initialized = Completer<void>();

  late final WebViewCommandBarSDK commandBar;

  CommandBarWidget._({Key? key, required this.orgId}) : super(key: key) {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    commandBar = WebViewCommandBarSDK(
        initialized.future.then((_) => webViewController.future),
        panelController);
  }

  openURLInSeparateWindow(String url) => launchUrl(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    return KeepAlivePage(child: _slidingWebViewPanel(context));
  }

  Widget _slidingWebViewPanel(BuildContext context) {
    // This allows the webview to be scrollable
    final Set<foundation.Factory<OneSequenceGestureRecognizer>>
        gestureRecognizers = {
      foundation.Factory(() => EagerGestureRecognizer())
    };

    // Mediaquery helps us get the available screen size after the
    // appbar has been calculated.
    final size = MediaQuery.of(context).size;
    final webviewUrl = foundation.kReleaseMode
        ? 'https://mobile.commandbar.com/?org=${Uri.encodeComponent(orgId)}'
        : 'http://localhost:3004/?org=${Uri.encodeComponent(orgId)}&lc=local';

    final webview = WebView(
      gestureRecognizers: gestureRecognizers,
      initialUrl: webviewUrl,
      javascriptMode: JavascriptMode.unrestricted,
      gestureNavigationEnabled: false,
      onWebViewCreated: (c) {
        webViewController.complete(c);
      },
      navigationDelegate: (NavigationRequest request) {
        if (request.url != webviewUrl) {
          // prevent moving off of CBar
          // FIXME: bar not working after nav away
          openURLInSeparateWindow(request.url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageFinished: (String url) {
        webViewController.future.then((c) {
          c.runJavascript('''
          if(!!window.CommandBar) {
            window.CommandBarInitializedStateChannel.postMessage('initialized');
          } else {
            document.addEventListener('commandbar-boot-ready', () => {
              window.CommandBarInitializedStateChannel.postMessage('initialized');
            });
          }
        ''');
        });
      },
      debuggingEnabled: foundation.kDebugMode ? true : false,
      javascriptChannels: {
        JavascriptChannel(
            name: 'CommandBarCallbacksChannel',
            onMessageReceived: (JavascriptMessage message) {
              var callbackMessage =
                  CallbackMessage.fromJson(jsonDecode(message.message));
              commandBar.handleCallback(callbackMessage);
            }),
        JavascriptChannel(
            name: 'CommandBarRouterChannel',
            onMessageReceived: (JavascriptMessage message) {
              var url = message.message;

              commandBar.router?.call(url);
            }),
        JavascriptChannel(
            name: 'CommandBarToggleStateChannel',
            onMessageReceived: (JavascriptMessage message) {
              var state = message.message;

              if (state == 'open') {
                commandBar.open();
              }

              if (state == 'close') {
                commandBar.close();
              }
            }),
        JavascriptChannel(
            name: 'CommandBarInitializedStateChannel',
            onMessageReceived: (JavascriptMessage message) {
              var state = message.message;
              if (state == 'initialized') {
                log.info("CommandBar initialized");
                initialized.complete();
              }

              commandBar.boot();
            }),
      },
    );

    return SlidingUpPanel(
      controller: panelController,
      isDraggable: true,
      backdropEnabled: true,
      minHeight: 0,
      maxHeight: size.height / 1.2,
      onPanelSlide: (double position) {
        if (position == 0.0) {
          commandBar.onClose();
        } else if (position == 1.0) {
          commandBar.onOpen();
        }
      },
      panel: Center(
          child: Column(
        children: [
          // Expanded prevents the app from crashing while at the same time
          // fill the available space with webview
          Expanded(
              child: Stack(children: [
            webview,
            FutureBuilder<void>(
                future: initialized.future,
                builder: (context, snapshot) =>
                    snapshot.connectionState == ConnectionState.done
                        ? const SizedBox.shrink()
                        : const Center(child: CircularProgressIndicator()))
          ])),
        ],
      )),
    );
  }
}
