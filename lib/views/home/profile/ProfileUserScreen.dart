import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/user/actions.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/libraries/redux/hooks.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

class UserProfileArguments {
  final User? user;

  UserProfileArguments({this.user});
}

class UserProfileScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();
    final arguments = useScreenArguments<UserProfileArguments>(context, UserProfileArguments());

    final headerOpacity = useState(1.0);

    final user = arguments.user!;

    final scaffordBackgroundColor = Theme.of(context).brightness == Brightness.light
        ? const Color(AppColors.greyLightest)
        : Theme.of(context).scaffoldBackgroundColor;

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final userColor = useMemoized(
      () => AppColors.hashedColor(user.userId),
      [user.userId],
    );

    final titlePadding = useMemoized(
      () => Dimensions.listTitlePaddingDynamic(width: width),
      [width],
    );
    final contentPadding = useMemoized(
      () => Dimensions.listPaddingDynamic(width: width),
      [width],
    );

    final scrollController = useScrollController(initialScrollOffset: 0);

    useEffect(() {
      scrollController.addListener(() {
        final height = MediaQuery.of(context).size.height;
        const minOffset = 0;
        final maxOffset = height * 0.2;
        final offsetRatio = scrollController.offset / maxOffset;

        final isOpaque = scrollController.offset <= minOffset;
        final isTransparent = scrollController.offset > maxOffset;
        final isFading = !isOpaque && !isTransparent;

        if (isFading) {
          headerOpacity.value = 1 - offsetRatio;
          return;
        }

        if (isTransparent) {
          headerOpacity.value = 0;
          return;
        }

        headerOpacity.value = 1;
      });
      return null;
    }, []);

    final onPickColor = useCallback(({required int originalColor}) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => DialogColorPicker(
          title: 'Select User Color',
          currentColor: originalColor,
          onSelectColor: () => null,
        ),
      );
    }, []);

    final onBlockUser = useCallback(() async {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => DialogConfirm(
          title: 'Block User',
          content:
              'If you block ${user.displayName}, you will not be able to see their messages and you will immediately leave this chat.',
          onConfirm: () async {
            dispatch(toggleBlockUser(user: user));
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          onDismiss: () => Navigator.pop(dialogContext),
        ),
      );
    }, [context]);

    return Scaffold(
      backgroundColor: scaffordBackgroundColor,
      body: CustomScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: height * 0.3,
            systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
            automaticallyImplyLeading: false,
            titleSpacing: 0.0,
            title: Row(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Flexible(
                  child: Text(
                    user.displayName ?? user.userId!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                ),
              ],
            ),
            flexibleSpace: Hero(
              tag: 'UserAvatar',
              child: Container(
                padding: EdgeInsets.only(top: height * 0.075),
                color: userColor,
                width: width,
                child: OverflowBox(
                  minHeight: 64,
                  maxHeight: height * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: headerOpacity.value,
                        child: Avatar(
                          size: height * 0.15,
                          uri: user.avatarUri,
                          alt: user.displayName ?? user.userId ?? '',
                          background: userColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: <Widget>[
                  CardSection(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: width,
                          padding: titlePadding,
                          child: Text(
                            'About',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: contentPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? '',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                user.userId ?? '',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'User',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  CardSection(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: contentPadding,
                          child: Text(
                            'Chat Settings',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ListTile(
                          enabled: false,
                          contentPadding: contentPadding,
                          onTap: () => onPickColor(originalColor: userColor.value),
                          title: const Text('Color'),
                          trailing: Container(
                            padding: const EdgeInsets.only(right: 16),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: userColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CardSection(
                    child: Column(
                      children: [
                        Container(
                          width: width,
                          padding: contentPadding,
                          child: Text(
                            'Privacy and Status',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ListTile(
                          enabled: false,
                          contentPadding: contentPadding,
                          title: const Text('View Sessions'),
                        ),
                        ListTile(
                          onTap: () => onBlockUser(),
                          contentPadding: contentPadding,
                          title: const Text('Block'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ])),
        ],
      ),
    );
  }
}
