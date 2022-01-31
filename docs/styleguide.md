## Syphon Styleguide


This styleguide provides a few dos and don'ts when developing inside Syphon based on conscensious from the contributors. Some of these will change over time, so if you see something that defies the styleguide here, feel free to change it! It's likely technical debt and is available for refactor. 

Note these are also, as most things in software, largely based on subjective opinions of the developers. If you'd like to add or remove something, let us know! 

The primary goal of this document is not to impose arbitrary restrictions, but to make writing and maintaining Syphon *simple, accessible, and fun*. We want everyone to be able to meaningfully contribute to the code base no matter your skill level. Let us know what else we can do to continue futher this goal! :)


### Akways define UI elements outside the ViewModel

- DO

```dart

class IntroSettingsScreen extends StatelessWidget {
   
  /// ...

  onExportSessionKeys(BuildContext context) async {
    final store = StoreProvider.of<AppState>(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DialogTextInput(
        title: 'Export Session Keys',
        content: 'Enter a password to encrypt your session keys with.',
        label: Strings.labelPassword,
        initialValue: '',
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        onCancel: () async {
          Navigator.of(dialogContext).pop();
        },
        onConfirm: (String password) async {
          store.dispatch(exportSessionKeys(password));

          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
```

- DON'T

```dart

class _Props extends Equatable {


final Function onExportSessionKeys;

// ...

static _Props mapStateToProps(Store<AppState> store) => _Props(
 onExportSessionKeys: (BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DialogTextInput(
        title: 'Export Session Keys',
        content: 'Enter a password to encrypt your session keys with.',
        label: Strings.labelPassword,
        initialValue: '',
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        onCancel: () async {
          Navigator.of(dialogContext).pop();
        },
        onConfirm: (String password) async {
          store.dispatch(exportSessionKeys(password));

          Navigator.of(dialogContext).pop();
        },
      ),
    );
  },
```

