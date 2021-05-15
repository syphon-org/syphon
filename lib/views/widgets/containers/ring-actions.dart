// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';

class ActionRing extends StatelessWidget {
  ActionRing({
    Key? key,
    this.fabKey,
  }) : super(key: key);

  final GlobalKey<FabCircularMenuState>? fabKey;

  @protected
  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, '/home/groups/search');
  }

  @protected
  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, '/home/user/search');
  }

  @protected
  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, '/home/groups/create');
  }

  @protected
  onNavigateToCreateGroupPublic(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, '/home/groups/create/public');
  }

  @override
  Widget build(BuildContext context) => FabCircularMenu(
        key: fabKey,
        fabSize: 58,
        fabElevation: 4.0,
        fabOpenIcon: Icon(
          Icons.bubble_chart,
          size: Dimensions.iconSizeLarge,
          color: Colors.white,
        ),
        fabCloseIcon: Icon(
          Icons.close,
          color: Colors.white,
        ),
        fabColor: Theme.of(context).primaryColor,
        ringColor: Theme.of(context).primaryColor.withAlpha(144),
        ringDiameter: Dimensions.actionRingDefaultWidth(context),
        animationDuration: Duration(milliseconds: 275),
        onDisplayChange: (opened) {},
        children: [
          FloatingActionButton(
            heroTag: 'fab1',
            tooltip: 'Create Public Room',
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => onNavigateToCreateGroupPublic(context),
            child: SvgPicture.asset(
              Assets.iconPublicAddBeing,
              semanticsLabel: 'Create A Public Room',
              color: Colors.white,
            ),
          ),
          FloatingActionButton(
            heroTag: 'fab2',
            tooltip: 'Create Group',
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => onNavigateToCreateGroup(context),
            child: SvgPicture.asset(
              Assets.iconGroupAddBeing,
              semanticsLabel: 'Create A Public Room',
              color: Colors.white,
            ),
          ),
          FloatingActionButton(
            heroTag: 'fab3',
            tooltip: 'Direct Message',
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => onNavigateToDraft(context),
            child: SvgPicture.asset(
              Assets.iconPersonAddBeing,
              semanticsLabel: 'Create A Public Room',
              color: Colors.white,
            ),
          ),
          FloatingActionButton(
            heroTag: 'fab4',
            tooltip: 'Search Public Groups',
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => onNavigateToPublicSearch(context),
            child: SvgPicture.asset(
              Assets.iconSearchPublicCondensedBeing,
              semanticsLabel: 'Search Public Groups',
              color: Colors.white,
            ),
          ),
        ],
      );
}

class Props extends Equatable {
  final ThemeType type;

  Props({
    required this.type,
  });

  @override
  List<Object> get props => [
        type,
      ];

  static Props mapStateToProps(Store<AppState> store) => Props(
        type: store.state.settingsStore.theme,
      );
}
