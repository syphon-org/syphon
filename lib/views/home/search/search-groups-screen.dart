import 'package:equatable/equatable.dart';
import 'package:expandable/expandable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/loader/index.dart';

class GroupSearchScreen extends StatefulWidget {
  const GroupSearchScreen({Key? key}) : super(key: key);

  @override
  GroupSearchState createState() => GroupSearchState();
}

class GroupSearchState extends State<GroupSearchScreen> {
  final searchInputFocusNode = FocusNode();

  GroupSearchState();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  onMounted() async {
    final store = StoreProvider.of<AppState>(context);
    final searchResults = store.state.searchStore.searchResults;

    // Clear search if previous results are not from User searching
    if (searchResults.isNotEmpty && searchResults[0] is! Room) {
      store.dispatch(clearSearchResults());
    }
    // Initial search to show rooms by most popular
    if (store.state.searchStore.searchResults.isEmpty) {
      store.dispatch(searchRoomsPublic(searchable: ''));
    }
  }

  @override
  void dispose() {
    searchInputFocusNode.dispose();
    super.dispose();
  }

  @protected
  Widget buildSearchList(BuildContext context, _Props props) {
    final label = props.loading ? Strings.labelSearching : Strings.labelGroupsEmpty;

    if (props.searchResults.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              minWidth: Dimensions.mediaSizeMin,
              maxWidth: Dimensions.mediaSizeMax,
              maxHeight: Dimensions.mediaSizeMin,
            ),
            child: SvgPicture.asset(
              Assets.heroChatNotFound,
              semanticsLabel: Strings.semanticsHomeDefault,
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                label,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ],
      ));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: props.searchResults.length,
      itemBuilder: (BuildContext context, int index) {
        final room = props.searchResults[index] as Room;
        final formattedUserTotal = NumberFormat.compact();
        final localUserTotal = NumberFormat();
        final hashedColor = Colours.hashedColor(room.id);

        return Container(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
          ),
          child: ExpandablePanel(
            theme: ExpandableThemeData(
              hasIcon: false,
              tapBodyToCollapse: true,
              tapHeaderToExpand: true,
            ),
            header: ListTile(
              leading: Stack(
                children: [
                  Avatar(
                    uri: room.avatarUri,
                    alt: room.name,
                    size: Dimensions.avatarSizeMin,
                    background: hashedColor,
                  ),
                  Visibility(
                    visible: !room.encryptionEnabled,
                    child: Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.thumbnailSizeMax,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.red,
                                offset: Offset(8.0, 8.0),
                              )
                            ],
                          ),
                          height: 16,
                          width: 16,
                          child: Icon(
                            Icons.lock_open,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: room.encryptionEnabled,
                    child: Positioned(
                      bottom: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.thumbnailSizeMax,
                        ),
                        child: Container(
                          height: 16,
                          width: 16,
                          color: Colors.green,
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      room.name!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        formattedUserTotal.format(
                          room.totalJoinedUsers,
                        ),
                        style: TextStyle(
                          fontSize: Dimensions.textSizeTiny,
                        ),
                      ),
                      Icon(
                        Icons.person,
                        size: 20,
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    icon: Icon(
                      Icons.add_circle,
                      color: Colors.greenAccent,
                    ),
                    iconSize: Dimensions.iconSize,
                    onPressed: () async {
                      await props.onJoin(room: room);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            collapsed: Container(
              padding: Dimensions.listPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      formatPreviewTopic(room.topic),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                ],
              ),
            ),
            expanded: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: Dimensions.listPadding,
                  child: Text(
                    room.topic ?? Strings.placeholderTopic,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                Container(
                  padding: Dimensions.listPadding,
                  child: Text(
                    room.name!,
                    textAlign: TextAlign.start,
                    softWrap: true,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: !room.encryptionEnabled
                                  ? Icon(
                                      Icons.lock_open,
                                      size: Dimensions.iconSizeLarge,
                                      color: Colors.redAccent,
                                    )
                                  : Icon(
                                      Icons.lock,
                                      size: Dimensions.iconSizeLarge,
                                      color: Colors.greenAccent,
                                    ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Text(
                                'Encryption',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              child: Text(
                                localUserTotal.format(room.totalJoinedUsers),
                                style: TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              child: Text(
                                'Total Users',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            )
                          ],
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

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) => Scaffold(
          appBar: AppBarSearch(
            title: Strings.titleSearchGroups,
            label: 'Search a topic...',
            tooltip: 'Search topics',
            forceFocus: true,
            focusNode: searchInputFocusNode,
            onSearch: (String text) {
              var isValid = true;
              if (text.contains(':')) {
                isValid = RegExp(Values.urlRegex).hasMatch(text.split(':')[1]);
              }

              if (isValid) {
                props.onSearch(text);
              }
            },
          ),
          body: Center(
            child: Stack(
              children: [
                buildSearchList(context, props),
                Positioned(
                  child: Loader(
                    loading: props.loading,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Props extends Equatable {
  final bool loading;
  final ThemeType themeType;
  final List<dynamic> searchResults;

  final Function onJoin;
  final Function onSearch;

  const _Props({
    required this.themeType,
    required this.loading,
    required this.searchResults,
    required this.onJoin,
    required this.onSearch,
  });

  @override
  List<Object> get props => [
        themeType,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.searchStore.loading,
        themeType: store.state.settingsStore.themeSettings.themeType,
        searchResults: store.state.searchStore.searchResults,
        onJoin: ({Room? room}) {
          store.dispatch(joinRoom(room: room));
        },
        onSearch: (text) {
          store.dispatch(searchRoomsPublic(searchable: text));
        },
      );
}
