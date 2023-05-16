import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syphon/domain/hooks.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/media/actions.dart';
import 'package:syphon/domain/media/model.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

///
/// Matrix Image
///
/// uses the matrix mxc uris and either pulls from cached data
/// or downloads the image and saves it to cache
///
class MatrixImage extends HookWidget {
  const MatrixImage({
    super.key,
    required this.mxcUri,
    this.width = Dimensions.avatarSizeMin,
    this.height = Dimensions.avatarSizeMin,
    this.size,
    this.strokeWidth = Dimensions.strokeWidthThin,
    this.imageType,
    this.loadingPadding = 0,
    this.fit = BoxFit.fill,
    this.thumbnail = true,
    this.autodownload = true,
    this.rebuild = true,
    this.forceLoading = false,
    this.fallbackColor = Colors.grey,
    this.fallback,
    this.fileName = '',
    this.onPressImage,
  });

  final String? mxcUri;
  final String? imageType;
  final String fileName;

  final double width;
  final double height;
  final double? size;
  final double strokeWidth;
  final double loadingPadding;

  final bool rebuild;
  final bool thumbnail;
  final bool autodownload;
  final bool forceLoading;

  final BoxFit fit;
  final Widget? fallback;
  final Color fallbackColor;

  final Function(Uint8List bytes)? onPressImage;

  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<AppState>();

    final bool isMediaCached = useSelectorUnsafe<AppState, bool?>(
          (state) => state.mediaStore.mediaCache.containsKey(mxcUri),
        ) ??
        false;

    final String? mediaStatus = useSelectorUnsafe<AppState, String?>(
      (state) => state.mediaStore.mediaStatus[mxcUri],
    );

    final Uint8List? mediaCached = useSelectorUnsafe<AppState, Uint8List?>(
      (state) => state.mediaStore.mediaCache[mxcUri],
    );

    final loadingLocal = useRef<bool>(false);
    final mediaCachedLocal = useState<Uint8List?>(null);

    useEffect(() {
      if (!isMediaCached && autodownload) {
        dispatch(fetchMedia(mxcUri: mxcUri, thumbnail: thumbnail));
      }

      // Attempts to reduce framerate drop in chat details
      // not sure this actually works as it still drops on scroll
      if (isMediaCached && rebuild) {
        mediaCachedLocal.value = mediaCached;
      }

      return null;
    }, []);

    onManualLoad() async {
      loadingLocal.value = true;
      await dispatch(fetchMedia(mxcUri: mxcUri, thumbnail: thumbnail));
      loadingLocal.value = false;
    }

    final failed = mediaStatus != null && mediaStatus == MediaStatus.FAILURE.value;
    final loading = forceLoading || !isMediaCached || loadingLocal.value;

    // allows user option to manually load images on tap
    if (!autodownload && !isMediaCached && !loadingLocal.value) {
      return TouchableOpacity(
        behavior: HitTestBehavior.translucent,
        onTap: () => onManualLoad(),
        child: Container(
          padding: EdgeInsets.all(loadingPadding),
          width: size ?? width,
          height: size ?? height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo,
                size: Dimensions.avatarSizeLarge,
                color: Colors.white,
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  Strings.labelDownloadImage,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (failed) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: fallbackColor,
        child: fallback ??
            Icon(
              Icons.photo,
              color: Colors.white,
            ),
      );
    }

    if (loading) {
      return Container(
        width: size ?? width,
        height: size ?? height,
        child: Padding(
          padding: EdgeInsets.all(loadingPadding),
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth * 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
            value: null,
          ),
        ),
      );
    }

    final imageBytes = mediaCached ?? mediaCachedLocal.value!;

    if (onPressImage != null) {
      return GestureDetector(
        onTap: () => onPressImage!(imageBytes),
        child: Image(
          width: width,
          height: height,
          fit: fit,
          image: MemoryImage(imageBytes),
        ),
      );
    }

    return Image(
      width: width,
      height: height,
      fit: fit,
      image: MemoryImage(imageBytes),
    );
  }
}
