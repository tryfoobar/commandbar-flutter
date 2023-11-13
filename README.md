⚠️ Warning ⚠️
This repository is deprecated and is no longer actively maintained or supported. We do not plan to make any further changes or updates to this repository.

<img src="https://raw.githubusercontent.com/tryfoobar/commandbar-flutter/main/resources/logo.svg" width="400" />

CommandBar gives your users onboarding nudges, quick actions, relevant support content, and 
powerful search, in one ‍personalized, blazing fast widget.

Learn more at https://www.commandbar.com

> NOTE: this package is a *beta* release. We'd love to hear your feedback, bug reports, and 
questions; please reach out to us at support@commandbar.com.

## Features

In just a few minutes, you can have a beautiful and fast command palette in your Flutter app.

<img src="https://raw.githubusercontent.com/tryfoobar/commandbar-flutter/main/resources/commandbar-flutter-demo.gif" width="400" />


## Getting started

Before you start using the SDK:

1) Sign up for a CommandBar account at https://app.commandbar.com/signup
2) Copy your "organization ID" from https://app.commandbar.com/getting-started

<img src="https://raw.githubusercontent.com/tryfoobar/commandbar-flutter/main/resources/org_id.png" width="400" />

## Usage

Call `CommandBar.initialize`. This returns a `CommandBarInstance` with two fields:
  - `widget`: The CommandBar bottomsheet Widget. This should be installed in your app's 
    widget hierarchy
  - `commandBar`: An instance of `CommandBarSDK`; this is how you make calls to the 
    CommandBar SDK. See https://commandbar.com/docs and https://commandbar.com/sdk for 
    detailed documentation.

The `CommandBarSDK` instance will need to be passed down to any Widget in your hierarchy 
that needs to use the SDK. We recommend using `Provider` (https://pub.dev/packages/provider)
to do this. e.g.
```dart
# lib/main.dart
void main() {
  runApp(Provider(
      create: (context) {
        final cbInstance = CommandBar.initialize(
          orgId: '<your org id here>',
        );

        // This is optional; provide the user's ID so that analytics events can include it.
        // You can also call `boot` later in your app initialization code if necessary.
        cbInstance.commandBar.boot(<user ID of logged in user>);

        return cbInstance;
      },
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final cbInstance = Provider.of<CommandBarInstance>(context);

    var app = MaterialApp(
        title: 'Flutter Demo',
        builder: (context, widget) => widget != null
            ? Stack(children: [
                widget,
                cbInstance.widget,
              ])
            : Stack(),
            ...
```

The call to `commandBar.boot` is optional; if included, you can provide the user's ID as well as any user 
metadata. If you do this, analytics events will be tagged with the user's ID. (see 
https://www.commandbar.com/sdk#boot for more details).

### Opening the bar

Finally, we need to open the Bar by calling `commandBar.toggle()`.

#### Using a button

```dart
class LauncherButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cbInstance = Provider.of<CommandBarInstance>(context);
    
    return IconButton(
        icon: Icon(
          Icons.bolt,
        ),
        onPressed: () {
          cbInstance.commandBar.toggle();
        },
    );
  }
}
```

#### Using a gesture

```dart
class LauncherGesture extends StatelessWidget {
  final Widget? child;
  LauncherGesture({this.child});

  @override
  Widget build(BuildContext context) {
    final commandBar = Provider.of<CommandBarSDK>(context);

    return GestureDetector(
      onDoubleTap: () {
        commandBar.toggle();
      },
      child: child,
    );
  }
}
```

## Using the Editor

The CommandBar Editor is how you can add commands to your Bar. Usually, the Editor can be used directly 
from your Bar in-situ on your site; however, for Mobile SDK integrations this won't work.

Instead, you can use the Editor via this link:
  [https://mobile.commandbar.com/?org=your-org-id&editor=true](https://mobile.commandbar.com/?org=your-org-id&editor=true)

You can learn more about the Editor here:
  https://www.commandbar.com/docs/getting-started/open-editor

## Additional information

Reach out to us at support@commandbar.com with questions, comments, or feedback.
