import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/views/navigation.dart';

class FabCircleExpanding extends StatelessWidget {
  final GlobalKey<FabBarContainerState>? fabKey;

  final Alignment? alignment;

  const FabCircleExpanding({
    Key? key,
    this.fabKey,
    this.alignment,
  }) : super(key: key);

  @protected
  onNavigateToPublicSearch(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.toggle(open: false);
    Navigator.pushNamed(context, Routes.searchGroups);
  }

  @protected
  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.toggle(open: false);
    Navigator.pushNamed(context, Routes.searchUsers);
  }

  @protected
  onNavigateToCreateGroup(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.toggle(open: false);
    Navigator.pushNamed(context, Routes.groupCreate);
  }

  @protected
  onNavigateToCreateGroupPublic(context) {
    HapticFeedback.lightImpact();
    fabKey!.currentState!.toggle(open: false);
    Navigator.pushNamed(context, Routes.groupCreatePublic);
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          return FabBarContainer(
            key: fabKey,
            alignment: alignment ?? Alignment.bottomRight,
            distance: 112.0,
            children: [
              FloatingActionButton(
                heroTag: 'fab1',
                tooltip: 'Create Public Group',
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

class FabBarContainer extends StatefulWidget {
  const FabBarContainer({
    Key? key,
    this.initialOpen,
    this.alignment,
    required this.distance,
    required this.children,
  }) : super(key: key);

  final bool? initialOpen;
  final Alignment? alignment;
  final double distance;
  final List<Widget> children;

  @override
  FabBarContainerState createState() => FabBarContainerState();
}

class FabBarContainerState extends State<FabBarContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ignore: avoid_positional_boolean_parameters
  void toggle({bool? open}) {
    if (open != null) {
      return setState(() {
        _open = open;
        if (_open) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: widget.alignment ?? Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: () => toggle(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0; i < count; i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: toggle,
            child: const Icon(Icons.create),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    Key? key,
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  }) : super(key: key);

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}
