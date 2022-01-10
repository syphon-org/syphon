import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/lifecycle.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class ChatUsersDetailArguments {
  final String? roomId;

  ChatUsersDetailArguments({this.roomId});
}

class ChatUsersDetailScreen extends StatefulWidget {
  const ChatUsersDetailScreen({Key? key}) : super(key: key);

  @override
  ChatUsersDetailState createState() => ChatUsersDetailState();
}

class ChatUsersDetailState extends State<ChatUsersDetailScreen>
    with Lifecycle<ChatUsersDetailScreen> {
  final searchInputFocusNode = FocusNode();

  bool loading = false;

  ChatUsersDetailState();

  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final ChatUsersDetailArguments arguments =
        ModalRoute.of(context)!.settings.arguments as ChatUsersDetailArguments;

    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && searchResults[0] is! User) {
      store.dispatch(clearSearchResults());
    }

    store.dispatch(fetchRoomMembers(room: Room(id: arguments.roomId!)));
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  onShowUserDetails({required BuildContext context, String? roomId, String? userId}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        userId: userId,
      ),
    );
  }

  buildUserList(BuildContext context, _Props props) => ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: props.usersFiltered.length,
        itemBuilder: (BuildContext context, int index) {
          final user = props.usersFiltered[index] as User;

          return GestureDetector(
            onTap: () => onShowUserDetails(
              context: context,
              userId: user.userId,
              roomId: props.room.id,
            ),
            child: CardSection(
              padding: EdgeInsets.zero,
              elevation: 0,
              child: ListTile(
                leading: Avatar(
                  uri: user.avatarUri,
                  alt: user.displayName ?? user.userId,
                  size: Dimensions.avatarSizeMin,
                  background: Colours.hashedColor(
                    user.displayName ?? user.userId,
                  ),
                ),
                title: Text(
                  formatUsername(user),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                subtitle: Text(
                  user.userId!,
                  style: Theme.of(context).textTheme.caption!.merge(
                        TextStyle(
                          color: props.loading ? Color(Colours.greyDisabled) : null,
                        ),
                      ),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final ChatUsersDetailArguments? arguments =
        ModalRoute.of(context)!.settings.arguments as ChatUsersDetailArguments?;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store, arguments!.roomId),
      builder: (context, props) => Scaffold(
        appBar: AppBarSearch(
          title: Strings.titleChatUsers,
          label: Strings.labelSearchUser,
          tooltip: Strings.tooltipSearchUsers,
          focusNode: searchInputFocusNode,
          onChange: (text) {
            props.onSearch(text);
          },
          onSearch: (text) {
            props.onSearch(text);
          },
        ),
        body: Stack(
          children: [
            buildUserList(context, props),
            Positioned(
              child: Loader(
                loading: loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Props extends Equatable {
  final Room room;
  final bool loading;
  final String? searchText;
  final List<dynamic> usersFiltered;

  final Function onSearch;

  const _Props({
    required this.room,
    required this.loading,
    required this.searchText,
    required this.usersFiltered,
    required this.onSearch,
  });

  @override
  List<Object?> get props => [
        searchText,
        usersFiltered,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store, String? roomId) => _Props(
        loading: store.state.roomStore.loading,
        searchText: store.state.searchStore.searchText,
        room: store.state.roomStore.rooms[roomId!] ?? Room(id: roomId),
        usersFiltered: searchUsersLocal(
          store.state,
          roomId: roomId,
          searchText: store.state.searchStore.searchText,
        ),
        onSearch: (text) {
          store.dispatch(setSearchText(text: text));
        },
      );
}
