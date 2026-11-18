import '../enums.dart';

const int mobileBreakpoint = 600;
const int tabletBreakpoint = 900;
const int desktopBreakpoint = 1200;

class ScreenHelper {
  static ScreenType getScreenType(double width) {
    if (width >= desktopBreakpoint) return ScreenType.wide;
    if (width >= mobileBreakpoint) return ScreenType.middle;
    return ScreenType.narrow;
  }
}
