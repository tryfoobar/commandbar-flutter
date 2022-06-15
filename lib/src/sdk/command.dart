abstract class CommandTemplate {
  final String type;
  final String value;

  CommandTemplate._(this.type, this.value);

  Map toJson() => {'type': type, 'value': value};
}

class LinkCommandTemplate extends CommandTemplate {
  final String operation = 'blank';

  LinkCommandTemplate(String url) : super._('link', url);

  @override
  Map toJson() => {...super.toJson(), 'operation': operation};
}

class CallbackCommandTemplate extends CommandTemplate {
  CallbackCommandTemplate(String callbackKey)
      : super._('callback', callbackKey);
}

class Command {
  final String text;
  final String name;
  final String category;
  final String? icon;
  final CommandTemplate template;

  Command(
      {required this.text,
      required this.name,
      required this.template,
      required this.category,
      this.icon});

  Map toJson() => {
        'name': name,
        'text': text,
        'category': category,
        'icon': icon,
        'template': template
      };
}

abstract class CallbackCommandArgument {
  final String key;
  final int orderKey;
  final String label;
  final String value;
  final String type;

  CallbackCommandArgument(
      this.key, this.orderKey, this.label, this.value, this.type);

  Map toJson() => {
        key: {
          'order_key': orderKey,
          'value': value,
          'label': label,
          'type': type
        }
      };
}

class CallbackCommandTextArgument extends CallbackCommandArgument {
  CallbackCommandTextArgument(key, orderKey, label)
      : super(key, orderKey, label, "text", "provided");
}

class CallbackCommand extends Command {
  final List<CallbackCommandArgument>? arguments;

  CallbackCommand(
      {required String text,
      required String name,
      required String value,
      required String category,
      String? icon,
      this.arguments})
      : super(
            text: text,
            name: name,
            template: CallbackCommandTemplate(value),
            category: category,
            icon: icon);

  @override
  Map toJson() {
    final argumentsMap = arguments?.fold<Map>(
            {}, (acc, argument) => {...acc, ...argument.toJson()}) ??
        {};

    return {...super.toJson(), 'arguments': argumentsMap};
  }
}
