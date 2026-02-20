import 'package:flutter/material.dart';
import 'focus_utils.dart';

class NavigationUtils {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<T?> push<T>(Widget page) {
    // Clear focus before navigation
    FocusUtils.unfocus();
    return Navigator.of(navigatorKey.currentContext!).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static Future<T?> pushReplacement<T>(Widget page) {
    // Clear focus before navigation
    FocusUtils.unfocus();
    return Navigator.of(navigatorKey.currentContext!).pushReplacement<T, void>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(Widget page) {
    // Clear focus before navigation
    FocusUtils.unfocus();
    return Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  static void pop<T>([T? result]) {
    // Clear focus before popping
    FocusUtils.unfocus();
    Navigator.of(navigatorKey.currentContext!).pop(result);
    // Clear focus after pop as well to ensure keyboard is dismissed
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusUtils.unfocus();
    });
  }

  static void popUntil(String routeName) {
    Navigator.of(navigatorKey.currentContext!).popUntil(
      ModalRoute.withName(routeName),
    );
  }

  static bool canPop() {
    return Navigator.of(navigatorKey.currentContext!).canPop();
  }
}
