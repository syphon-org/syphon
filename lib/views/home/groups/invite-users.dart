// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/user/actions.dart';
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
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

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
      this.setState(() {
        searching = !searching;
      });
    }

    if (store.state.userStore.invites.isNotEmpty) {
      this.setState(() {
        invites = store.state.userStore.invites;
      });
    }

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && !(searchResults[0] is User)) {
      store.dispatch(clearSearchResults());
    }
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
   * User Invite
   * 
   * add user to invite list
   */
  @protected
  void onSubmitUsers({BuildContext context, _Props props}) async {
    await props.onSubmitInvites(
      users: this.invites,
    );
    Navigator.pop(context);
  }

  @protected
  onShowUserDetails({
    BuildContext context,
    User user,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
      ),
    );
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
        title: 'Try inviting ${user.displayName}',
        content: Strings.alertInviteUnknownUser,
        action: 'try invite',
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

          final usersList = searchable == null || searchable.isEmpty
              ? props.usersRecent
              : props.searchResults;

          final usersListLabel = searchable == null || searchable.isEmpty
              ? Strings.labelRecentUsers
              : Strings.labelSearchedUsers;

          return Scaffold(
            appBar: AppBarSearch(
              title: Strings.titleInviteusers,
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
            floatingActionButton: Container(
              padding: Dimensions.appPaddingVertical,
              child: FloatingActionButton(
                heroTag: 'fab5',
                tooltip: 'Add User Invites',
                backgroundColor: Theme.of(context).accentColor,
                onPressed: () => onSubmitUsers(
                  context: context,
                  props: props,
                ),
                child: Container(
                  padding: EdgeInsets.only(left: 2),
                  child: SvgPicture.asset(
                    Assets.iconChevronsRightBeing,
                    color: Colors.white,
                    semanticsLabel: Strings.semanticsLabelHomeEmpty,
                  ),
                ),
              ),
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
                              onTap: () => onShowUserDetails(
                                context: context,
                                user: user,
                              ),
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 12 : 4,
                                  right:
                                      index == this.invites.length - 1 ? 12 : 4,
                                ),
                                child: Chip(
                                  labelPadding: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.comfortable,
                                  avatar: AvatarCircle(
                                    margin: EdgeInsets.zero,
                                    padding: EdgeInsets.zero,
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
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: Dimensions.avatarSizeMessage / 1.5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color,
                                  ),
                                  onDeleted: () => onInviteUser(user: user),
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
                            Container(
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    usersListLabel,
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                                visible: showManualUser,
                                child: GestureDetector(
                                    onTap: () => this.onAttemptInvite(
                                          props: props,
                                          context: context,
                                          user: attemptableUser,
                                        ),
                                    child: CardSection(
                                      margin: EdgeInsets.zero,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 4),
                                      elevation: 0,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          enabled: creatingRoomDisplayName !=
                                              searchable,
                                          leading: AvatarCircle(
                                            uri: attemptableUser.avatarUri,
                                            alt: attemptableUser.displayName ??
                                                attemptableUser.userId,
                                            size: Dimensions.avatarSizeMin,
                                            background: Colours.hashedColor(
                                                attemptableUser.userId),
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
                                                        ? Color(Colours
                                                            .greyDisabled)
                                                        : null,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ))),
                            ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: usersList.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                final user = (usersList[index] as User);

                                return CardSection(
                                  margin: EdgeInsets.zero,
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  elevation: 0,
                                  child: InkWell(
                                    onTap: () => this.onInviteUser(user: user),
                                    child: Container(
                                      child: ListTile(
                                        enabled: creatingRoomDisplayName !=
                                            user.displayName,
                                        leading: GestureDetector(
                                          onTap: () => this.onShowUserDetails(
                                            context: context,
                                            user: user,
                                          ),
                                          child: Stack(
                                            children: [
                                              AvatarCircle(
                                                uri: user.avatarUri,
                                                alt: user.displayName ??
                                                    user.userId,
                                                size: Dimensions.avatarSizeMin,
                                                selected: this.invites.contains(
                                                      user,
                                                    ),
                                                background: Colours.hashedColor(
                                                  user.userId,
                                                ),
                                              ),
                                            ],
                                          ),
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
  final Function onSubmitInvites;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.usersRecent,
    @required this.creatingRoom,
    @required this.searchResults,
    @required this.onSearch,
    @required this.onSubmitInvites,
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
        onSubmitInvites: ({List<User> users}) async {
          return store.dispatch(setUserInvites(users: users));
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
