import 'dart:typed_data';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:redux/redux.dart';

/**
 * MatrixImage
 * uses the matrix mxc uris and either pulls from cached data or 
 * downloads the image and saves it to cache
 */
class MatrixImage extends StatefulWidget {
  final String mxcUri;
  final double width;
  final double height;
  final double strokeWidth;
  final String imageType;
  final BoxFit fit;
  final bool thumbnail;
  final bool disableRebuild;
  final bool forceLoading;

  const MatrixImage({
    Key key,
    @required this.mxcUri,
    this.width = 48,
    this.height = 48,
    this.strokeWidth = Dimensions.defaultStrokeWidthLite,
    this.imageType,
    this.fit = BoxFit.fill,
    this.thumbnail = true,
    this.disableRebuild = false,
    this.forceLoading = false,
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final mediaCache = store.state.mediaStore.mediaCache;

    if (!mediaCache.containsKey(widget.mxcUri)) {
      store.dispatch(fetchThumbnail(mxcUri: widget.mxcUri));
    }
    if (this.disableRebuild && mediaCache.containsKey(widget.mxcUri)) {
      finalUriData = mediaCache[widget.mxcUri];
    }
  }

  MatrixImageState({
    Key key,
    this.disableRebuild = false,
    this.forceLoading = false,
  });

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final loading =
              !props.mediaCache.containsKey(finalUriData ?? widget.mxcUri) ||
                  forceLoading;

          if (loading) {
            debugPrint('[MatrixImage] cache miss ${widget.mxcUri}');
            return Container(
              width: widget.width,
              height: widget.height,
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth * 1.5,
                valueColor: new AlwaysStoppedAnimation<Color>(
                  Theme.of(context).accentColor,
                ),
                value: null,
              ),
            );
          } else {
            // uncomment to confirm cache hits - very noisy
            // print('[MatrixImage] cache hit ${widget.mxcUri}');
          }

          return Image(
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            image: MemoryImage(
              finalUriData ?? props.mediaCache[widget.mxcUri],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool fetching;
  final Map<String, Uint8List> mediaCache;

  _Props({
    @required this.fetching,
    @required this.mediaCache,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        fetching: false,
        mediaCache:
            store.state.mediaStore.mediaCache ?? Map<String, Uint8List>(),
      );

  @override
  List<Object> get props => [
        fetching,
        mediaCache,
      ];
}
