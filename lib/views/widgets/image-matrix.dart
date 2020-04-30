import 'dart:typed_data';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/media/actions.dart';
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

  const MatrixImage({
    Key key,
    @required this.mxcUri,
    this.width,
    this.height,
    this.imageType,
    this.strokeWidth,
    this.fit,
    this.thumbnail = true,
  }) : super(key: key);

  @override
  MatrixImageState createState() => MatrixImageState(
        mxcUri: this.mxcUri,
      );
}

class MatrixImageState extends State<MatrixImage> {
  final String mxcUri;
  final double width;
  final double height;
  final double strokeWidth;
  final String imageType;
  final bool thumbnail;
  final BoxFit fit;

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

    if (!mediaCache.containsKey(mxcUri)) {
      print('[MatrixImage] first hit, fetching $mxcUri');
      store.dispatch(fetchThumbnail(mxcUri: mxcUri));
    }
  }

  MatrixImageState({
    Key key,
    @required this.mxcUri,
    this.width = 48,
    this.height = 48,
    this.strokeWidth = 1.5,
    this.imageType,
    this.fit,
    this.thumbnail = true,
  });

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          if (!props.mediaCache.containsKey(this.mxcUri)) {
            print('[MatrixImage] loading $mxcUri');
            return Container(
              margin: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                value: null,
              ),
            );
          }

          print('[MatrixImage] cache loaded $mxcUri');
          return Image(
            width: width,
            height: height,
            fit: fit,
            image: MemoryImage(
              props.mediaCache[this.mxcUri],
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

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
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
