// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';

class InviteUsersArguments {
  final String roomId;

  InviteUsersArguments({this.roomId});
}

class InviteUsersView extends StatefulWidget {
  const InviteUsersView({Key key}) : super(key: key);

  @override
  InviteUsersState createState() => InviteUsersState();
}

class InviteUsersState extends State<InviteUsersView> {
  InviteUsersState({Key key});

  final searchInputFocusNode = FocusNode();
  final avatarScrollController = ScrollController();

  bool searching = false;
  String searchable;
  List<User> invites = [];
  String creatingRoomDisplayName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    if (!this.searching) {
      setState(() {
        searching = !searching;
      });
    }

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is User)) {
      store.dispatch(clearSearchResults());
    }

    searchInputFocusNode.addListener(() {
      if (!searchInputFocusNode.hasFocus) {
        searching = false;
      }
    });
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  /**
   * 
   * User Invite
   * 
   * add user to invite list
   */
  @protected
  void onInviteUser({User user}) async {
    final List<User> invitesUpdated = List.from(this.invites);
    final userIndex = invitesUpdated.indexWhere((u) => u.userId == user.userId);

    if (userIndex == -1) {
      invitesUpdated.add(user);
    } else {
      invitesUpdated.removeWhere((u) => u.userId == user.userId);
    }

    this.setState(() {
      invites = invitesUpdated;
    });

    if (invitesUpdated != null && invitesUpdated.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        avatarScrollController.animateTo(
          avatarScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: Values.animationDurationDefaultFast),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  /**
   * 
   * Attempt User Invite
   * 
   * attempt chating with a user 
   * by the name searched
   */
  @protected
  void onAttemptInvite({BuildContext context, _Props props, User user}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Try inviting with ${user.displayName}',
        content: Strings.confirmationAttemptChat,
        onStartChat: () => this.onInviteUser(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final width = MediaQuery.of(context).size.height;
          final showInvites = this.invites.length > 0;

          final searchText = searchable ?? '';

          final attemptableUser = User(
            displayName: searchText,
            userId: searchable != null && searchable.contains(":")
                ? searchable
                : formatUserId(searchText),
          );

          final foundResult = props.searchResults.indexWhere(
            (result) => result.userId.contains(searchText),
          );

          final showManualUser =
              searchable != null && searchable.length > 0 && foundResult < 0;

          return Scaffold(
            appBar: AppBarSearch(
              title: Strings.titleSearchUsers,
              label: 'Search for a user...',
              tooltip: 'Search Users',
              elevation: 0,
              onSearch: (text) => props.onSearch(text),
              onChange: (text) => this.setState(() {
                searchable = text;
              }),
              onToggleSearch: () => this.setState(() {
                searching = !searching;
              }),
            ),
            body: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Visibility(
                    visible: showInvites,
                    child: Container(
                      width: width,
                      height: Dimensions.listAvatarHeighttMax,
                      padding: EdgeInsets.only(top: 8),
                      constraints: BoxConstraints(
                        maxWidth: width,
                        maxHeight: Dimensions.listAvatarHeighttMax,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: avatarScrollController,
                        itemCount: this.invites.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext context, int index) {
                          final user = this.invites[index];

                          return Align(
                            child: GestureDetector(
                              onTap: () => onInviteUser(user: user),
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 12 : 4,
                                  right:
                                      index == this.invites.length - 1 ? 12 : 4,
                                ),
                                child: Chip(
                                  avatar: AvatarCircle(
                                    uri: user.avatarUri,
                                    alt: user.displayName ?? user.userId,
                                    size: Dimensions.avatarSizeMessage,
                                    background:
                                        Colours.hashedColor(user.userId),
                                  ),
                                  label: Text(
                                    formatUsername(user),
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .color,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          shrinkWrap: true,
                          children: [
                            Visibility(
                              visible: showManualUser,
                              child: GestureDetector(
                                onTap: () => this.onAttemptInvite(
                                  props: props,
                                  context: context,
                                  user: attemptableUser,
                                ),
                                child: CardSection(
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      enabled:
                                          creatingRoomDisplayName != searchable,
                                      leading: AvatarCircle(
                                        uri: attemptableUser.avatarUri,
                                        alt: attemptableUser.displayName ??
                                            attemptableUser.userId,
                                        size: Dimensions.avatarSizeMin,
                                      ),
                                      title: Text(
                                        formatUsername(attemptableUser),
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1,
                                      ),
                                      subtitle: Text(
                                        attemptableUser.userId,
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .merge(
                                              TextStyle(
                                                color: props.loading
                                                    ? Color(
                                                        Colours.greyDisabled)
                                                    : null,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: props.searchResults.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                final user =
                                    (props.searchResults[index] as User);

                                return GestureDetector(
                                  onTap: () => this.onInviteUser(user: user),
                                  child: CardSection(
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    child: Container(
                                      child: ListTile(
                                        enabled: creatingRoomDisplayName !=
                                            user.displayName,
                                        leading: AvatarCircle(
                                          uri: user.avatarUri,
                                          alt: user.displayName ?? user.userId,
                                          size: Dimensions.avatarSizeMin,
                                        ),
                                        title: Text(
                                          formatUsername(user),
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1,
                                        ),
                                        subtitle: Text(
                                          user.userId,
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption
                                              .merge(
                                                TextStyle(
                                                  color: props.loading
                                                      ? Color(
                                                          Colours.greyDisabled)
                                                      : null,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                        Positioned(
                          child: Visibility(
                            visible: props.loading,
                            child: Container(
                              margin: EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  RefreshProgressIndicator(
                                    strokeWidth: Dimensions.defaultStrokeWidth,
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                    value: null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType theme;
  final bool creatingRoom;
  final List<User> usersRecent;
  final List<dynamic> searchResults;

  final Function onSearch;
  final Function onCreateChatDirect;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.usersRecent,
    @required this.creatingRoom,
    @required this.searchResults,
    @required this.onSearch,
    @required this.onCreateChatDirect,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        usersRecent: friendlyUsers(store.state),
        theme: store.state.settingsStore.theme,
        loading: store.state.searchStore.loading,
        creatingRoom: store.state.roomStore.loading,
        searchResults: store.state.searchStore.searchResults ?? [],
        onSearch: (text) {
          store.dispatch(searchUsers(searchText: text));
        },
        onCreateChatDirect: ({User user}) async {
          return store.dispatch(createRoom(
            isDirect: true,
            invites: <User>[user],
          ));
        },
      );

  @override
  List<Object> get props => [
        loading,
        theme,
        creatingRoom,
        searchResults,
      ];
}
