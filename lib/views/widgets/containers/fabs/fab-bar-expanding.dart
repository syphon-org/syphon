import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';

class FabBarExpanding extends StatelessWidget {
  final Alignment? alignment;

  const FabBarExpanding({
    Key? key,
    this.alignment,
  }) : super(key: key);

  @protected
  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.searchGroups);
  }

  @protected
  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.searchUsers);
  }

  @protected
  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.groupCreate);
  }

  @protected
  onNavigateToCreateGroupPublic(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.groupCreatePublic);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) => SpeedDial(
          overlayOpacity: 0.4,
          switchLabelPosition: alignment == Alignment.bottomLeft,
          // childrenButtonSize: 64.0,
          childMargin: EdgeInsets.symmetric(vertical: 16),
          spacing: 8,
          children: <SpeedDialChild>[
            SpeedDialChild(
              label: 'Create A Public Chat',
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToCreateGroupPublic(context),
              child: SvgPicture.asset(
                Assets.iconPublicAddBeing,
                color: Colors.white,
              ),
            ),
            SpeedDialChild(
              label: 'Create Group',
              labelStyle: TextStyle(),
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToCreateGroup(context),
              child: SvgPicture.asset(
                Assets.iconGroupAddBeing,
                color: Colors.white,
              ),
            ),
            SpeedDialChild(
              label: 'Direct Message',
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToDraft(context),
              child: SvgPicture.asset(
                Assets.iconPersonAddBeing,
                color: Colors.white,
              ),
            ),
            SpeedDialChild(
              label: 'Search Public Chats',
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToPublicSearch(context),
              child: SvgPicture.asset(
                Assets.iconSearchPublicCondensedBeing,
                color: Colors.white,
              ),
            ),
          ],
          activeChild: Icon(
            Icons.close,
            semanticLabel: 'Close Actions Ring',
            color: Colors.white,
          ),
          child: Icon(
            Icons.bubble_chart,
            size: Dimensions.iconSizeLarge,
            semanticLabel: 'Open Actions Ring',
            color: Colors.white,
          ),
        ),
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
