import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';

class FabRing extends StatelessWidget {
  final GlobalKey<FabCircularMenuState>? fabKey;

  final Alignment? alignment;

  const FabRing({
    Key? key,
    this.fabKey,
    this.alignment,
  }) : super(key: key);

  @protected
  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.searchGroups);
  }

  @protected
  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.searchUsers);
  }

  @protected
  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.groupCreate);
  }

  @protected
  onNavigateToCreateGroupPublic(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.groupCreatePublic);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          return FabCircularMenu(
            key: fabKey,
            fabSize: 58,
            fabElevation: 4.0,
            alignment: alignment ?? Alignment.bottomRight,
            fabOpenIcon: Icon(
              Icons.bubble_chart,
              size: Dimensions.iconSizeLarge,
              semanticLabel: 'Open Actions Ring',
              color: Colors.white,
            ),
            fabCloseIcon: Icon(
              Icons.close,
              semanticLabel: 'Close Actions Ring',
              color: Colors.white,
            ),
            fabColor: props.primaryColor,
            ringColor: props.primaryColor.withAlpha(144),
            ringDiameter: Dimensions.actionRingDefaultWidth(context),
            animationDuration: Duration(milliseconds: 275),
            onDisplayChange: (opened) {},
            children: [
              FloatingActionButton(
                heroTag: 'fab1',
                tooltip: 'Create Public Room',
                backgroundColor: props.primaryColor,
                onPressed: () => onNavigateToCreateGroupPublic(context),
                child: SvgPicture.asset(
                  Assets.iconPublicAddBeing,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                heroTag: 'fab2',
                tooltip: 'Create Group',
                backgroundColor: props.primaryColor,
                onPressed: () => onNavigateToCreateGroup(context),
                child: SvgPicture.asset(
                  Assets.iconGroupAddBeing,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                heroTag: 'fab3',
                tooltip: 'Direct Message',
                backgroundColor: props.primaryColor,
                onPressed: () => onNavigateToDraft(context),
                child: SvgPicture.asset(
                  Assets.iconPersonAddBeing,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                heroTag: 'fab4',
                tooltip: 'Search Public Groups',
                backgroundColor: props.primaryColor,
                onPressed: () => onNavigateToPublicSearch(context),
                child: SvgPicture.asset(
                  Assets.iconSearchPublicCondensedBeing,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      );
}

class _Props extends Equatable {
  final Color primaryColor;

  const _Props({
    required this.primaryColor,
  });

  @override
  List<Object> get props => [
        primaryColor,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        primaryColor: selectPrimaryColor(store.state.settingsStore.themeSettings),
      );
}
