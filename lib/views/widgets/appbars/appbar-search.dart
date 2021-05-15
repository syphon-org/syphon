// Flutter imports:
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Project imports:
import 'package:touchable_opacity/touchable_opacity.dart';

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  AppBarSearch({
    Key? key,
    this.title = 'title:',
    this.label = 'label:',
    this.tooltip = 'tooltip:',
    this.throttle = const Duration(milliseconds: 400),
    this.brightness = Brightness.dark,
    this.elevation,
    this.focusNode,
    this.onBack,
    this.onChange,
    this.onSearch,
    this.onToggleSearch,
    this.forceFocus = false,
    this.loading = false,
  }) : super(key: key);

  final bool loading;
  final bool forceFocus;
  final String title;
  final String label;
  final String tooltip;
  final double? elevation;
  final Duration throttle;
  final Brightness brightness;
  final FocusNode? focusNode;

  final Function? onBack;
  final Function? onChange;
  final Function? onSearch;
  final Function? onToggleSearch;

  @override
  AppBarSearchState createState() => AppBarSearchState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class AppBarSearchState extends State<AppBarSearch> {
  final focusNode = FocusNode();

  bool searching = false;
  Timer? searchTimeout;

  @protected
  void onChange({String? text}) {
    if (widget.onChange != null) {
      widget.onChange!(text);
    }
  }

  @protected
  void onSearch({String? text}) {
    if (widget.onSearch != null) {
      widget.onSearch!(text);
    }
  }

  @override
  void initState() {
    super.initState();

    // NOTE: still needed to have navigator context in dialogs
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      if (widget.forceFocus) {
        onToggleSearch(context: context);
      }
    });
  }

  @protected
  void onBack() {
    if (onBack != null) {
      onBack();
    }
    Navigator.pop(context);
  }

  @protected
  void onToggleSearch({BuildContext? context}) {
    setState(() {
      searching = !searching;
    });
    if (this.searching) {
      Timer(
        Duration(milliseconds: 5), // hack to focus after visibility change
        () => FocusScope.of(
          context!,
        ).requestFocus(
          widget.focusNode ?? focusNode,
        ),
      );
    } else {
      FocusScope.of(context!).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => AppBar(
        elevation: widget.elevation,
        brightness: widget.brightness,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Stack(
          children: [
            Visibility(
              visible: !searching,
              child: TouchableOpacity(
                activeOpacity: 0.4,
                onTap: () => onToggleSearch(context: context),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ),
            Positioned(
              child: Visibility(
                visible: searching,
                maintainState: true,
                child: TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  focusNode: widget.focusNode ?? focusNode,
                  onChanged: (text) {
                    if (this.searchTimeout != null) {
                      this.searchTimeout!.cancel();
                      this.searchTimeout = null;
                    }

                    this.onChange(text: text);

                    this.setState(() {
                      searchTimeout = Timer(widget.throttle, () {
                        this.onSearch(text: text);
                      });
                    });
                  },
                  cursorColor: Colors.white,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w100,
                  ),
                  decoration: InputDecoration(
                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.0,
                        color: Colors.transparent,
                      ),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.0,
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.0,
                        color: Colors.transparent,
                      ),
                    ),
                    hintText: widget.label,
                    hintStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(searching ? Icons.cancel : Icons.search),
            onPressed: () => onToggleSearch(context: context),
            tooltip: widget.tooltip,
          ),
        ],
      );
}
