library commandbar;

export 'src/sdk/sdk.dart'
    show
        InstanceAttributes,
        CommandBarSDK,
        CommandBarInstance,
        Callback,
        CallbackArguments,
        Context,
        RouterFn;
export 'src/sdk/command.dart'
    show Command, CallbackCommand, LinkCommandTemplate;

export 'src/command_bar_widget.dart' show CommandBar;

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
