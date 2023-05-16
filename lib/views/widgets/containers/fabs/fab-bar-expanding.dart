import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/theme-settings/selectors.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/navigation.dart';

class FabBarExpanding extends StatelessWidget {
  final bool showLabels;
  final Alignment? alignment;

  const FabBarExpanding({
    super.key,
    this.alignment,
    this.showLabels = false,
  });

  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.searchGroups);
  }

  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.searchUsers);
  }

  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, Routes.groupCreate);
  }

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
          childMargin: EdgeInsets.symmetric(vertical: 16),
          spacing: 8,
          children: <SpeedDialChild>[
            SpeedDialChild(
              label: showLabels ? Strings.labelFabCreatePublic : null,
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToCreateGroupPublic(context),
              child: SvgPicture.asset(
                Assets.iconPublicAddBeing,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            SpeedDialChild(
              label: showLabels ? Strings.labelFabCreateGroup : null,
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToCreateGroup(context),
              child: SvgPicture.asset(
                Assets.iconGroupAddBeing,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            SpeedDialChild(
              label: showLabels ? Strings.labelFabCreateDM : null,
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToDraft(context),
              child: SvgPicture.asset(
                Assets.iconMessageCircleBeing,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            SpeedDialChild(
              label: showLabels ? Strings.labelFabSearch : null,
              backgroundColor: props.primaryColor,
              onTap: () => onNavigateToPublicSearch(context),
              child: SvgPicture.asset(
                Assets.iconSearchPublicCondensedBeing,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ],
          activeChild: Icon(
            Icons.close,
            semanticLabel: Strings.semanticsCloseActionsRing,
            color: Colors.white,
          ),
          child: Icon(
            Icons.bubble_chart,
            size: Dimensions.iconSizeLarge,
            semanticLabel: Strings.semanticsOpenActionsRing,
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
