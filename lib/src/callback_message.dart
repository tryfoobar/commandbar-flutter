class CallbackMessage {
  final String callbackKey;
  final Map<String, dynamic> args;
  final Map<String, dynamic> context;

  CallbackMessage(this.callbackKey, this.args, this.context);

  CallbackMessage.fromJson(Map<String, dynamic> json)
      : callbackKey = json['callbackKey'],
        args = json['args'],
        context = json['context'];
}
