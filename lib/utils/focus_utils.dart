import 'package:flutter/material.dart';
import 'package:smart_attendance_tracker/utils/navigation_utils.dart';

class FocusUtils {
  /// Unfocus any focused field and hide keyboard
  static void unfocus() {
    final context = NavigationUtils.context;
    if (context == null) return;
    
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild?.unfocus();
    } else {
      currentFocus.unfocus();
    }
  }

  /// Unfocus and hide keyboard
  static void hideKeyboard() {
    unfocus();
  }
}
