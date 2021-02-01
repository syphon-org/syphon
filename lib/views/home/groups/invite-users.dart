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
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/views/home/chat/dialog-invite.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-invite-users.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';
import 'package:syphon/views/widgets/loader/index.dart';
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
   * Toggle User Invite
   * 
   * add/remove user to invite list
   */
  @protected
  void onToggleInvite({User user}) async {
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
        title: 'Try inviting ${user.displayName}',
        content: Strings.alertInviteUnknownUser,
        action: 'try invite',
        onStartChat: () {
          this.onToggleInvite(user: user);
          Navigator.pop(context);
        },
      ),
    );
  }

  /**
   * 
   * Confirm and save invite list
   * 
   * also attempts to invite users directly if a room id already exists
   */
  @protected
  void onConfirmInvites(_Props props) async {
    final InviteUsersArguments arguments =
        ModalRoute.of(context).settings.arguments;
    final roomId = arguments.roomId;

    if (roomId != null && this.invites.length > 0) {
      await this.onSendInvites(props);
    } else {
      await props.onAddInvites(users: this.invites);
      Navigator.pop(context);
    }
  }

  /**
   * Actually send invites to all listed users
   */
  Future<void> onSendInvites(_Props props) async {
    FocusScope.of(context).unfocus();
    final InviteUsersArguments arguments =
        ModalRoute.of(context).settings.arguments;
    final store = StoreProvider.of<AppState>(context);

    final roomId = arguments.roomId;
    final room = store.state.roomStore.rooms[roomId];

    final multiple = this.invites.length > 1;
    final invitePlurialized = multiple ? 'Invites' : 'Invite';

    // Confirm sending the invites with a dialog
    return await showDialog(
      context: context,
      builder: (BuildContext context) => DialogInviteUsers(
        users: this.invites,
        title: 'Invite To ${room.name}',
        content: Strings.confirmationInvites +
            '\n\nSend ${this.invites.length} ${invitePlurialized.toLowerCase()} to ${room.name}?',
        action: 'send ${invitePlurialized.toLowerCase()}',
        onInviteUsers: () async {
          await Future.wait(this.invites.map((user) async {
            return props.onSendInvite(room: Room(id: roomId), user: user);
          }));

          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void onShowUserDetails({
    BuildContext context,
    User user,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
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

          final showManualUser = searchable != null &&
              searchable.length > 0 &&
              foundResult < 0 &&
              !props.loading;

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
              forceFocus: true,
              focusNode: searchInputFocusNode,
              onBack: () => onConfirmInvites(props),
              onSearch: (text) => props.onSearch(text),
              onChange: (text) => this.setState(() {
                searchable = text;
              }),
            ),
            floatingActionButton: Container(
              padding: Dimensions.appPaddingVertical,
              child: FloatingActionButton(
                heroTag: 'fab5',
                tooltip: 'Add User Invites',
                backgroundColor: Theme.of(context).accentColor,
                onPressed: () => onConfirmInvites(props),
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
                                  avatar: Avatar(
                                    margin: EdgeInsets.zero,
                                    padding: EdgeInsets.zero,
                                    uri: user.avatarUri,
                                    alt: user.displayName ?? user.userId,
                                    size: Dimensions.avatarSizeMessage,
                                    background: Colours.hashedColor(
                                      formatUsername(user),
                                    ),
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
                                  onDeleted: () => onToggleInvite(user: user),
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
                                          leading: Avatar(
                                            uri: attemptableUser.avatarUri,
                                            alt: attemptableUser.displayName ??
                                                attemptableUser.userId,
                                            size: Dimensions.avatarSizeMin,
                                            background: Colours.hashedColor(
                                              attemptableUser.userId,
                                            ),
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
                                    onTap: () =>
                                        this.onToggleInvite(user: user),
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
                                              Avatar(
                                                uri: user.avatarUri,
                                                alt: user.displayName ??
                                                    user.userId,
                                                size: Dimensions.avatarSizeMin,
                                                selected: this.invites.contains(
                                                      user,
                                                    ),
                                                background: Colours.hashedColor(
                                                  formatUsername(user),
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
                          child: Loader(
                            loading: props.loading,
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
  final Function onAddInvites;
  final Function onSendInvite;

  _Props({
    @required this.theme,
    @required this.loading,
    @required this.usersRecent,
    @required this.creatingRoom,
    @required this.searchResults,
    @required this.onSearch,
    @required this.onAddInvites,
    @required this.onSendInvite,
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
        onAddInvites: ({List<User> users}) async {
          return store.dispatch(setUserInvites(users: users));
        },
        onSendInvite: ({Room room, User user}) {
          store.dispatch(
            inviteUser(room: room, user: user),
          );
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
