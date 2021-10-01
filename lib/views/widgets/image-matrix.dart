import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

///
/// MatrixImage
///
/// uses the matrix mxc uris and either pulls from cached data or
/// downloads the image and saves it to cache
class MatrixImage extends StatefulWidget {
  final String? mxcUri;
  final double width;
  final double height;
  final double? size;
  final double strokeWidth;
  final double loadingPadding;
  final String? imageType;
  final BoxFit fit;
  final bool thumbnail;
  final bool disableRebuild;
  final bool forceLoading;
  final Widget? fallback;
  final Color fallbackColor;

  const MatrixImage({
    Key? key,
    required this.mxcUri,
    this.width = Dimensions.avatarSizeMin,
    this.height = Dimensions.avatarSizeMin,
    this.size,
    this.strokeWidth = Dimensions.strokeWidthThin,
    this.imageType,
    this.loadingPadding = 0,
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

class MatrixImageState extends State<MatrixImage> with Lifecycle<MatrixImage> {
  Uint8List? finalUriData;

  // @override
  // void initState() {
  //   super.initState();
  //   printInfo('[MatrixImageState] initState ${widget.mxcUri}');
  // }

  // TODO: potentially revert to didChangeDependencies
  @override
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);
    final mediaCache = store.state.mediaStore.mediaCache;

    printInfo('[onMounted] checking ${widget.mxcUri}');

    if (!mediaCache.containsKey(widget.mxcUri)) {
      if (!widget.thumbnail) {
        printInfo('[onMounted] fetching media');
        store.dispatch(fetchMedia(mxcUri: widget.mxcUri));
      } else {
        printInfo('[onMounted] fetching thumbnail');
        store.dispatch(fetchThumbnail(mxcUri: widget.mxcUri));
      }
    }

    // Created in attempts to reduce framerate drop in chat details
    // not sure this actually works as it still drops on scroll
    if (widget.disableRebuild && mediaCache.containsKey(widget.mxcUri)) {
      printInfo('[onMounted] disabled rebuild');
      finalUriData = mediaCache[widget.mxcUri!];
    }
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   onMounted();
  // }

  // void onDidUpdate(_Props? prev, _Props props) {
  //   final failed = props.mediaCheck.isNotEmpty && props.mediaCheck == MediaStatus.FAILURE;
  //   final loading = widget.forceLoading || !props.exists;
  //   printInfo(
  //     '[fetchMedia] updated widget failed: ${failed} loading: ${loading} mxc: ${widget.mxcUri}',
  //   );
  // }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        // onDidChange: onDidUpdate,
        // onInitialBuild: (props) => onMounted(),
        converter: (Store<AppState> store) => _Props.mapStateToProps(store, widget.mxcUri),
        builder: (context, props) {
          final failed = props.mediaCheck.isNotEmpty && props.mediaCheck == MediaStatus.FAILURE;
          final loading = widget.forceLoading || !props.exists;

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
                child: Padding(
                  padding: EdgeInsets.all(widget.loadingPadding),
                  child: CircularProgressIndicator(
                    strokeWidth: widget.strokeWidth * 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.secondary,
                    ),
                    value: null,
                  ),
                ));
          }

          return Image(
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            image: MemoryImage(
              props.mediaCache ?? finalUriData!,
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool exists;
  final String mediaCheck;
  final Uint8List? mediaCache;

  const _Props({
    required this.exists,
    required this.mediaCheck,
    required this.mediaCache,
  });

  @override
  List<Object?> get props => [
        exists,
        mediaCheck,
        mediaCache,
      ];

  static _Props mapStateToProps(Store<AppState> store, String? mxcUri) => _Props(
        exists: store.state.mediaStore.mediaCache[mxcUri] != null,
        mediaCache: store.state.mediaStore.mediaCache[mxcUri],
        mediaCheck: store.state.mediaStore.mediaChecks[mxcUri] ?? '',
      );
}
