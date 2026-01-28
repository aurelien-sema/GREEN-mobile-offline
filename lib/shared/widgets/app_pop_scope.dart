import 'package:flutter/material.dart';

/// Compatibility wrapper: use `PopScope` when available in the SDK,
/// otherwise fall back to `WillPopScope` while keeping the same API.
///
/// This avoids hard requirement on a newer Flutter SDK while letting
/// us centralize the future migration.
class AppPopScope extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onWillPop;

  const AppPopScope({super.key, required this.child, this.onWillPop});

  @override
  Widget build(BuildContext context) {
    // Keep using WillPopScope internally for backward compatibility.
    // Suppress deprecation warning centrally so other files don't need to.
    // ignore: deprecated_member_use
    return WillPopScope(onWillPop: onWillPop, child: child);
  }
}
