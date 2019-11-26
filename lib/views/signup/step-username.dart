import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Domain
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/user/model.dart';

// Styling
import 'package:Tether/global/assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tether/global/dimensions.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({Key key}) : super(key: key);

  UsernameStepState createState() => UsernameStepState();
}

class UsernameStepState extends State<UsernameStep> {
  UsernameStepState({Key key});

  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      runInitTasks();
    });
    usernameController.addListener(() {
      final text = usernameController.text.replaceAll(' ', '');
      usernameController.value = usernameController.value.copyWith(
        text: text,
      );
    });
  }

  @protected
  void runInitTasks() {
    final store = StoreProvider.of<AppState>(context);
    usernameController.text = username(store.state);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: height * 0.1),
        Container(
          height: DEFAULT_INPUT_HEIGHT,
          constraints:
              BoxConstraints(minWidth: 200, maxWidth: 400, minHeight: 240),
          child: SvgPicture.asset(SIGNUP_USERNAME_GRAPHIC,
              semanticsLabel: 'User hidding behind a message'),
        ),
        SizedBox(height: 24),
        Text(
          'Create a username',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline,
        ),
        SizedBox(height: height * 0.025),
        StoreConnector<AppState, Store<AppState>>(
            converter: (Store<AppState> store) => store,
            builder: (context, store) {
              return Container(
                width: width * 0.7,
                height: DEFAULT_INPUT_HEIGHT,
                margin: const EdgeInsets.all(10.0),
                constraints: BoxConstraints(
                    minWidth: 200, maxWidth: 400, minHeight: 45, maxHeight: 45),
                child: TextField(
                  controller: usernameController,
                  onChanged: (text) {
                    store.dispatch(setUsername(username: text));
                  },
                  onEditingComplete: () {
                    store.dispatch(
                        setUsername(username: store.state.userStore.username));
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      labelText: store.state.userStore.username != null ||
                              store.state.userStore.username.length > 0
                          ? alias(store.state)
                          : "Username"),
                ),
              );
            }),
      ],
    ));
  }
}
