import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

import 'package:touchable_opacity/touchable_opacity.dart';

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  const AppBarSearch({
    Key? key,
    this.title = 'title:',
    this.label = 'label:',
    this.tooltip = 'tooltip:',
    this.throttle = const Duration(milliseconds: 400),
    this.elevation,
    this.focusNode,
    this.startFocused = false,
    this.navigate = true,
    this.forceFocus = false,
    this.loading = false,
    this.onBack,
    this.onChange,
    this.onSearch,
    this.onToggleSearch,
  }) : super(key: key);

  final bool loading;
  final bool forceFocus;
  final bool startFocused;
  final bool navigate;

  final String title;
  final String label;
  final String tooltip;
  final double? elevation;
  final Duration throttle;
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

class AppBarSearchState extends State<AppBarSearch> with Lifecycle<AppBarSearch> {
  final focusNode = FocusNode();

  bool searching = false;
  Timer? searchTimeout;

  @override
  void initState() {
    super.initState();

    searching = widget.startFocused;
  }

  @override
  void onMounted() {
    if (searching) {
      FocusScope.of(context).requestFocus(
        widget.focusNode ?? focusNode,
      );
    }
  }

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

  @protected
  void onBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    }
    if (widget.navigate) {
      Navigator.pop(context, false);
    }
  }

  @protected
  void onToggleSearch({BuildContext? context}) {
    if (widget.onToggleSearch != null && searching) {
      widget.onToggleSearch!();
      return;
    }

    setState(() {
      searching = !searching;
    });

    if (searching) {
      FocusScope.of(context!).requestFocus(
        widget.focusNode ?? focusNode,
      );
    } else {
      onChange(text: ''); // clear search results
      FocusScope.of(context!).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => AppBar(
        elevation: widget.elevation,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => onBack(),
          tooltip: Strings.labelBack,
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
                    if (searchTimeout != null) {
                      searchTimeout!.cancel();
                      searchTimeout = null;
                    }

                    onChange(text: text);

                    setState(() {
                      searchTimeout = Timer(widget.throttle, () {
                        onSearch(text: text);
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
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
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
