// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';

/**
 * MatrixImage
 * uses the matrix mxc uris and either pulls from cached data or 
 * downloads the image and saves it to cache
 */
class MatrixImage extends StatefulWidget {
  final String mxcUri;
  final double width;
  final double height;
  final double size;
  final double strokeWidth;
  final String imageType;
  final BoxFit fit;
  final bool thumbnail;
  final bool disableRebuild;
  final bool forceLoading;
  final Widget fallback;
  final Color fallbackColor;

  const MatrixImage({
    Key key,
    @required this.mxcUri,
    this.width = 48,
    this.height = 48,
    this.size,
    this.strokeWidth = Dimensions.defaultStrokeWidthLite,
    this.imageType,
    this.fit = BoxFit.fill,
    this.thumbnail = true,
    this.disableRebuild = false,
    this.forceLoading = false,
    this.fallbackColor = Colors.grey,
    this.fallback,
  }) : super(key: key);

  @override
  MatrixImageState createState() => MatrixImageState();
}

class MatrixImageState extends State<MatrixImage> {
  final bool disableRebuild;
  final bool forceLoading;

  Uint8List finalUriData;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final mediaCache = store.state.mediaStore.mediaCache;

    if (!mediaCache.containsKey(widget.mxcUri)) {
      store.dispatch(fetchThumbnail(mxcUri: widget.mxcUri));
    }

    // Created in attempts to reduce framerate drop in chat details
    // not sure this actually works as it still drops on scroll
    if (this.disableRebuild && mediaCache.containsKey(widget.mxcUri)) {
      finalUriData = mediaCache[widget.mxcUri];
    }
  }

  MatrixImageState({
    Key key,
    this.forceLoading = false,
    this.disableRebuild = false,
  });

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final failed = props.mediaChecks[widget.mxcUri] != null &&
              props.mediaChecks[widget.mxcUri] == 'failed';
          final loading =
              forceLoading || !props.mediaCache.containsKey(widget.mxcUri);

          if (failed) {
            return CircleAvatar(
              radius: 24,
              backgroundColor: widget.fallbackColor,
              child: widget.fallback ??
                  Icon(
                    Icons.photo,
                    color: Colors.white,
                  ),
            );
          }

          if (loading) {
            return Container(
              width: widget.size ?? widget.width,
              height: widget.size ?? widget.height,
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth * 1.5,
                valueColor: new AlwaysStoppedAnimation<Color>(
                  Theme.of(context).accentColor,
                ),
                value: null,
              ),
            );
          }

          return Image(
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            image: MemoryImage(
              props.mediaCache[widget.mxcUri] ?? finalUriData,
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool fetching;
  final Map<String, Uint8List> mediaCache;
  final Map<String, String> mediaChecks;

  _Props({
    @required this.fetching,
    @required this.mediaCache,
    @required this.mediaChecks,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        fetching: false,
        mediaCache:
            store.state.mediaStore.mediaCache ?? Map<String, Uint8List>(),
        mediaChecks:
            store.state.mediaStore.mediaChecks ?? Map<String, String>(),
      );

  @override
  List<Object> get props => [
        fetching,
        mediaCache,
      ];
}
