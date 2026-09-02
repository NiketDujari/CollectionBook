import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import 'app_lock_screen.dart';
import 'webview_screen.dart';

class LockedHome
    extends StatefulWidget {

  final bool initiallyLocked;

  const LockedHome({
    super.key,
    this.initiallyLocked = true,
  });

  @override
  State<LockedHome> createState() =>
      _LockedHomeState();
}

class _LockedHomeState
    extends State<LockedHome>
    with WidgetsBindingObserver {
  static const Color indigo =
  Color(0xFF2B3A67);

  static const Color indigoDeep =
  Color(0xFF182449);

  static const Color turmeric =
  Color(0xFFC98A2D);

  static const Color khadi =
  Color(0xFFEFE7D6);

  static const Color paper =
  Color(0xFFFBF8F1);

  static const Color muted =
  Color(0xFF77705F);

  late bool _locked;

  @override
  void initState() {
    super.initState();

    _locked =
        widget.initiallyLocked;

    WidgetsBinding.instance
        .addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }


  Future<void> _lockIfEnabled() async {
    final hasPin =
    await AppLockService.hasPin();

    if (
    hasPin &&
        mounted
    ) {
      setState(() {
        _locked = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (
    state ==
        AppLifecycleState.paused
    ) {
      _lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_locked) {
      return AppLockScreen(
        onUnlocked: () {
          setState(() {
            _locked = false;
          });
        },
      );
    }

    return const WebViewScreen();
  }
}