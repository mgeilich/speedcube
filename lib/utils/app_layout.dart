import 'package:flutter/widgets.dart';

/// Screen-shape helpers shared by the home screen widgets.
///
/// The iPhone Duo's inner display is landscape (~951x669pt) and its outer
/// display is narrow (~355pt usable beside the side status strip), so layout
/// decisions can't be made from height alone.
class AppLayout {
  /// Wide enough to place the cube and the controls side by side
  /// (iPhone Duo unfolded, iPad landscape, phones in landscape).
  static bool isWide(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 700 && size.width > size.height * 1.1;
  }

  /// Too little vertical space for the full single-column layout.
  /// A wide screen with a tall enough side pane is never short.
  static bool isShort(BuildContext context, [double threshold = 750]) {
    final height = MediaQuery.sizeOf(context).height;
    if (isWide(context) && height >= 600) return false;
    return height < threshold;
  }
}
