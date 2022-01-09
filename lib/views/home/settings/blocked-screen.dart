import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:syphon/views/widgets/appbars/appbar-normal.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/loader/index.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({Key? key}) : super(key: key);

  @override
  BlockedScreenState createState() => BlockedScreenState();
}

class BlockedScreenState extends State<BlockedScreen> {
  bool loading = false;

  BlockedScreenState();

  // componentDidMount(){}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @protected
  onShowUserDetails({
    required BuildContext context,
    String? userId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        userId: userId,
      ),
    );
  }

  @protected
  Widget buildUserList(BuildContext context, _Props props) => ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: props.usersBlocked.length,
        itemBuilder: (BuildContext context, int index) {
          final user = props.usersBlocked[index]!;

          return GestureDetector(
            onTap: () => onShowUserDetails(
              context: context,
              userId: user.userId,
            ),
            child: CardSection(
              padding: EdgeInsets.zero,
              elevation: 0,
              child: ListTile(
                leading: Avatar(
                  uri: user.avatarUri,
                  alt: user.displayName ?? user.userId,
                  size: Dimensions.avatarSizeMin,
                  background: Colours.hashedColorUser(user),
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
    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(store),
      builder: (context, props) => Scaffold(
        appBar: AppBarNormal(
          title: 'Blocked users',
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
  final bool loading;
  final List<User?> usersBlocked;

  const _Props({
    required this.loading,
    required this.usersBlocked,
  });

  @override
  List<Object> get props => [
        loading,
        usersBlocked,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        loading: store.state.roomStore.loading,
        usersBlocked:
            store.state.userStore.blocked.map((id) => store.state.userStore.users[id]).toList(),
      );
}
