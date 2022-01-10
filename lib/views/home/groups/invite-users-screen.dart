import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/dialogs/dialog-invite-users.dart';
import 'package:syphon/views/widgets/dialogs/dialog-start-chat.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/lists/list-item-user.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class InviteUsersArguments {
  final String? roomId;

  InviteUsersArguments({this.roomId});
}

class InviteUsersScreen extends StatefulWidget {
  const InviteUsersScreen({Key? key}) : super(key: key);

  @override
  InviteUsersState createState() => InviteUsersState();
}

class InviteUsersState extends State<InviteUsersScreen> with Lifecycle<InviteUsersScreen> {
  InviteUsersState();

  final searchInputFocusNode = FocusNode();
  final avatarScrollController = ScrollController();

  String searchable = '';
  List<User?> invites = [];
  String? creatingRoomDisplayName;

  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    if (store.state.userStore.invites.isNotEmpty) {
      setState(() {
        invites = store.state.userStore.invites;
      });
    }

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && searchResults[0] is! User) {
      store.dispatch(clearSearchResults());
    }
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  onShowUserDetails({required BuildContext context, User? user}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        user: user,
        nested: true,
      ),
    );
  }

  ///
  /// Toggle User Invite
  ///
  /// add/remove user to invite list
  ///
  onToggleInvite({User? user}) async {
    final List<User?> invitesUpdated = List.from(invites);
    final userIndex = invitesUpdated.indexWhere((u) => u!.userId == user!.userId);

    if (userIndex == -1) {
      invitesUpdated.add(user);
    } else {
      invitesUpdated.removeWhere((u) => u!.userId == user!.userId);
    }

    setState(() {
      invites = invitesUpdated;
    });

    if (invitesUpdated.isNotEmpty) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        avatarScrollController.animateTo(
          avatarScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: Values.animationDurationDefaultFast),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  ///
  /// Attempt User Invite
  ///
  /// attempt chating with a user by the name searched
  ///
  onAttemptInvite({required BuildContext context, _Props? props, User? user}) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => DialogStartChat(
        user: user,
        title: 'Try inviting ${user!.displayName}',
        content: Strings.alertInviteUnknownUser,
        action: 'try invite',
        onStartChat: () {
          onToggleInvite(user: user);
          Navigator.pop(context);
        },
      ),
    );
  }

  ///
  /// Confirm and save invite list
  ///
  /// also attempts to invite users directly if a room id already exists
  ///
  onConfirmInvites(_Props props) async {
    final InviteUsersArguments arguments =
        ModalRoute.of(context)!.settings.arguments as InviteUsersArguments;
    final roomId = arguments.roomId;

    if (roomId != null && invites.isNotEmpty) {
      await onSendInvites(props);
    } else {
      await props.onAddInvites(users: invites);
      Navigator.pop(context);
    }
  }

  ///
  /// Actually send invites to all listed users
  ///
  onSendInvites(_Props props) async {
    FocusScope.of(context).unfocus();
    final InviteUsersArguments arguments =
        ModalRoute.of(context)!.settings.arguments as InviteUsersArguments;
    final store = StoreProvider.of<AppState>(context);

    final roomId = arguments.roomId;
    final room = store.state.roomStore.rooms[roomId!];

    final multiple = invites.length > 1;
    final invitePlurialized = multiple ? 'Invites' : 'Invite';

    // Confirm sending the invites with a dialog
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) => DialogInviteUsers(
        users: invites,
        title: 'Invite To ${room!.name}',
        content:
            '${Strings.confirmInvite}${'\n\nSend ${invites.length} ${invitePlurialized.toLowerCase()} to ${room.name}?'}',
        action: 'send ${invitePlurialized.toLowerCase()}',
        onInviteUsers: () async {
          await Future.wait(invites.map((user) async {
            return props.onSendInvite(room: Room(id: roomId), user: user);
          }));

          Navigator.pop(dialogContext);
          Navigator.pop(context);
        },
      ),
    );
  }

  @protected
  Widget buildUserChipList(BuildContext context, _Props props) {
    return ListView.builder(
      shrinkWrap: true,
      controller: avatarScrollController,
      itemCount: invites.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        final user = invites[index]!;

        return Align(
          child: GestureDetector(
            onTap: () => onShowUserDetails(
              context: context,
              user: user,
            ),
            child: Container(
              padding: EdgeInsets.only(
                left: index == 0 ? 12 : 4,
                right: index == invites.length - 1 ? 12 : 4,
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
                  background: Colours.hashedColorUser(user),
                ),
                label: Text(
                  formatUsername(user),
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Theme.of(context).textTheme.bodyText1!.color,
                      ),
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: Dimensions.avatarSizeMessage / 1.5,
                  color: Theme.of(context).textTheme.bodyText1!.color,
                ),
                onDeleted: () => onToggleInvite(user: user),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) {
        final width = MediaQuery.of(context).size.height; // not a mistake!
        final showInvites = invites.isNotEmpty;

        final attemptableUser = User(
          displayName: searchable,
          userId: searchable.contains(':') ? searchable : formatUserId(searchable),
        );

        final foundResult = props.searchResults.indexWhere(
          (result) => result.userId.contains(searchable),
        );

        final showManualUser = searchable.isNotEmpty && foundResult < 0 && !props.loading;
        final usersList = searchable.isEmpty ? props.usersRecent : props.searchResults;
        final usersListLabel =
            searchable.isEmpty ? Strings.labelUsersRecent : Strings.labelUsersResults;

        return Scaffold(
          appBar: AppBarSearch(
            title: Strings.titleInviteUsers,
            label: 'Search for a user...',
            tooltip: 'Search Users',
            elevation: 0,
            forceFocus: true,
            focusNode: searchInputFocusNode,
            onBack: () => onConfirmInvites(props),
            onSearch: (text) => props.onSearch(text),
            onChange: (text) => setState(() {
              searchable = text;
            }),
          ),
          floatingActionButton: Container(
            padding: Dimensions.appPaddingVertical,
            child: FloatingActionButton(
              heroTag: 'fab5',
              tooltip: 'Add User Invites',
              backgroundColor: Theme.of(context).colorScheme.secondary,
              onPressed: () => onConfirmInvites(props),
              child: Container(
                padding: EdgeInsets.only(left: 2),
                child: SvgPicture.asset(
                  Assets.iconChevronsRightBeing,
                  color: Colors.white,
                  semanticsLabel: Strings.semanticsHomeDefault,
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
                    child: buildUserChipList(context, props),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        shrinkWrap: true,
                        children: [
                          Container(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 16),
                            child: Row(
                              children: [
                                Text(
                                  usersListLabel,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.subtitle2,
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: showManualUser,
                            child: ListItemUser(
                              onPress: () => onAttemptInvite(
                                  props: props, context: context, user: attemptableUser),
                              type: ListItemUserType.Selectable,
                              user: attemptableUser,
                              enabled: creatingRoomDisplayName != searchable,
                              loading: props.loading,
                              real: false,
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: usersList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              final user = usersList[index] as User;

                              return ListItemUser(
                                type: ListItemUserType.Selectable,
                                user: user,
                                enabled: creatingRoomDisplayName != user.displayName,
                                selected: invites.contains(user),
                                loading: props.loading,
                                onPress: () => onToggleInvite(user: user),
                                onPressAvatar: () =>
                                    onShowUserDetails(context: context, user: user),
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
      });
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType themeType;
  final bool creatingRoom;
  final List<User> usersRecent;
  final List<dynamic> searchResults;

  final Function onSearch;
  final Function onAddInvites;
  final Function onSendInvite;

  const _Props({
    required this.themeType,
    required this.loading,
    required this.usersRecent,
    required this.creatingRoom,
    required this.searchResults,
    required this.onSearch,
    required this.onAddInvites,
    required this.onSendInvite,
  });
  @override
  List<Object> get props => [
        loading,
        themeType,
        creatingRoom,
        searchResults,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        usersRecent: selectFriendlyUsers(store.state),
        themeType: store.state.settingsStore.themeSettings.themeType,
        loading: store.state.searchStore.loading,
        creatingRoom: store.state.roomStore.loading,
        searchResults: store.state.searchStore.searchResults,
        onSearch: (text) {
          if (text.contains('@') && text.length == 1) {
            return;
          }

          if (text.isEmpty) {
            return;
          }
          store.dispatch(searchUsers(searchText: text));
        },
        onAddInvites: ({List<User>? users}) async {
          return store.dispatch(setUserInvites(users: users));
        },
        onSendInvite: ({Room? room, User? user}) {
          store.dispatch(
            inviteUser(room: room, user: user),
          );
        },
      );
}
