import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';

calculatePosition(int copyLength) => copyLength * 3.4;

class FabRing extends StatelessWidget {
  final bool showLabels;
  final Alignment alignment;
  final GlobalKey<FabCircularMenuState>? fabKey;

  const FabRing({
    super.key,
    this.fabKey,
    this.alignment = Alignment.bottomRight,
    this.showLabels = false,
  });

  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.searchGroups);
  }

  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.searchUsers);
  }

  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.groupCreate);
  }

  onNavigateToCreateGroupPublic(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.close();
    Navigator.pushNamed(context, Routes.groupCreatePublic);
  }

  double actionRingDefaultDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width > 640) return 640;
    if (size.width > 400) return size.width * 0.9;
    return size.width;
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final modifier = alignment == Alignment.bottomRight ? -1.0 : .425;

          return FabCircularMenu(
            key: fabKey,
            fabSize: 58,
            fabElevation: 4.0,
            alignment: alignment,
            fabOpenIcon: Icon(
              Icons.bubble_chart,
              size: Dimensions.iconSizeLarge,
              semanticLabel: Strings.semanticsOpenActionsRing,
              color: Colors.white,
            ),
            fabCloseIcon: Icon(
              Icons.close,
              semanticLabel: Strings.semanticsCloseActionsRing,
              color: Colors.white,
            ),
            fabColor: props.primaryColor,
            ringColor: props.primaryColor.withAlpha(144),
            ringDiameter: actionRingDefaultDimensions(context),
            animationDuration: Duration(milliseconds: 275),
            onDisplayChange: (opened) {},
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab1',
                    tooltip: Strings.labelFabCreatePublic,
                    backgroundColor: props.primaryColor,
                    onPressed: () => onNavigateToCreateGroupPublic(context),
                    child: SvgPicture.asset(
                      Assets.iconPublicAddBeing,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 148 * modifier,
                    child: Visibility(
                      visible: showLabels,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            Strings.labelFabCreatePublic,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          backgroundColor: props.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab2',
                    tooltip: Strings.labelFabCreateGroup,
                    backgroundColor: props.primaryColor,
                    onPressed: () => onNavigateToCreateGroup(context),
                    child: SvgPicture.asset(
                      Assets.iconGroupAddBeing,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 148 * modifier,
                    child: Visibility(
                      visible: showLabels,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            Strings.labelFabCreateGroup,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          backgroundColor: props.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab3',
                    tooltip: Strings.labelFabCreateDM,
                    backgroundColor: props.primaryColor,
                    onPressed: () => onNavigateToDraft(context),
                    child: SvgPicture.asset(
                      Assets.iconMessageCircleBeing,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    left: 136 * modifier,
                    child: Visibility(
                      visible: showLabels,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            Strings.labelFabCreateDM,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          backgroundColor: props.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab4',
                    tooltip: Strings.labelFabSearch,
                    backgroundColor: props.primaryColor,
                    onPressed: () => onNavigateToPublicSearch(context),
                    child: SvgPicture.asset(
                      Assets.iconSearchPublicCondensedBeing,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -68,
                    bottom: 0,
                    left: 112 * modifier,
                    child: Visibility(
                      visible: showLabels,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(
                            Strings.labelFabSearch,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          backgroundColor: props.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
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
