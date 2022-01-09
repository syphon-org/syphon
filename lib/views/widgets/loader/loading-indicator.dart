import 'package:flutter/material.dart';

import 'package:syphon/global/dimensions.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
    this.size = 28,
    this.loading = false,
  }) : super(key: key);

  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(
          maxWidth: size,
          maxHeight: size,
        ),
        child: CircularProgressIndicator(
          strokeWidth: Dimensions.strokeWidthDefault,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey,
          ),
        ),
      );
}
