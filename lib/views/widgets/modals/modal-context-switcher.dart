import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/context/auth.dart';
import 'package:syphon/context/storage.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/behaviors.dart';
import 'package:syphon/views/intro/login/login-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/syphon.dart';
import 'package:syphon/views/widgets/lists/list-item-account.dart';

class ModalContextSwitcher extends StatelessWidget {
  onNavigateToMultiLogin({required BuildContext context, required _Props props}) async {
    Navigator.pushNamed(
      context,
      Routes.login,
      arguments: LoginScreenArguments(
        multiaccount: true,
      ),
    );
  }

  onSwitchUser({required User user, required BuildContext context, required _Props props}) async {
    props.onSwitchUser(user);
    Navigator.pop(context);
  }

  onSwitchContext({
    required AppContext appContext,
    required BuildContext buildContext,
    required _Props props,
  }) {
    Syphon.setAppContext(buildContext, appContext);
    Navigator.pop(buildContext);
  }

  buildContextList(BuildContext buildContext, _Props props) => FutureBuilder<AppContext>(
      future: props.currentContext, // async work
      builder: (context, currentContextData) => FutureBuilder<List<AppContext>>(
            future: props.availableContext, // async work
            builder: (context, contextsAllData) {
              final knownUsers =
                  props.availableUsers.map((u) => generateContextId_DEPRECATED(id: u.userId!));
              final contextCurrent = currentContextData.data ?? AppContext();
              final contextsAll = contextsAllData.data ?? [];

              final contextsUnknown = contextsAll
                  .where((c) => c.id != contextCurrent.id && !knownUsers.contains(c.id))
                  .toList();

              return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: props.availableUsers.length >= contextsAll.length
                      ? 0
                      : contextsUnknown.length,
                  itemBuilder: (BuildContext context, int index) {
                    final context = contextsUnknown[index];

                    final userContext = User(
                      userId: context.id,
                      displayName: Strings.listItemContextSwitcherUserDisplayName(context.id),
                    );

                    return ListItemAccount(
                      user: userContext,
                      selected: false,
                      enabled: !props.loading,
                      onPress: () => onSwitchContext(
                        appContext: context,
                        buildContext: buildContext,
                        props: props,
                      ),
                    );
                  });
            },
          ));

  buildUserList(BuildContext context, _Props props) => ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: props.availableUsers.length,
      itemBuilder: (BuildContext context, int index) {
        final user = props.availableUsers[index];
        final selected = props.currentUser.userId == user.userId;

        return ListItemAccount(
          user: user,
          selected: selected,
          enabled: !props.loading && !selected,
          onPress: () => onSwitchUser(user: user, context: context, props: props),
        );
      });

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) => Container(
            constraints: BoxConstraints(
              maxHeight: Dimensions.modalHeightMax,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.paddingContainer,
                    horizontal: Dimensions.paddingLarge,
                  ),
                  child: Text(
                    Strings.listItemContextSwitcherAccounts,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Color(Colours.greyDark)
                              : Color(Colours.whiteDefault),
                        ),
                  ),
                ),
                ScrollConfiguration(
                  behavior: DefaultScrollBehavior(),
                  child: SingleChildScrollView(
                    // Use a container of the same height and width
                    // to flex dynamically but within a single child scroll
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildUserList(context, props),
                        buildContextList(context, props),
                        Opacity(
                          opacity: !props.loading ? 1 : 0.7,
                          child: ListTile(
                            enabled: !props.loading,
                            onTap: () => onNavigateToMultiLogin(
                              context: context,
                              props: props,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingContainer,
                            ),
                            title: Text(
                              Strings.listItemContextSwitcherAddAccount,
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            leading: Container(
                              height: Dimensions.avatarSizeMin,
                              width: Dimensions.avatarSizeMin,
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.add_circle_outline,
                                size: Dimensions.iconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ));
}

class _Props extends Equatable {
  final bool loading;

  final User currentUser;
  final List<User> availableUsers;
  final Future<AppContext> currentContext;
  final Future<List<AppContext>> availableContext;
  final ThemeSettings themeSettings;

  final Function onSwitchUser;

  const _Props({
    required this.loading,
    required this.currentUser,
    required this.currentContext,
    required this.themeSettings,
    required this.availableUsers,
    required this.availableContext,
    required this.onSwitchUser,
  });

  @override
  List<Object> get props => [
        loading,
        currentUser,
        availableUsers,
        availableContext,
        themeSettings,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: !store.state.syncStore.synced || store.state.syncStore.lastSince == null,
        currentUser: store.state.authStore.currentUser,
        themeSettings: store.state.settingsStore.themeSettings,
        availableUsers: store.state.authStore.availableUsers,
        currentContext: loadContextCurrent(),
        availableContext: loadContextsAll(),
        onSwitchUser: (User user) {
          final contextObserver = store.state.authStore.contextObserver;
          contextObserver?.add(user);
        },
      );
}
