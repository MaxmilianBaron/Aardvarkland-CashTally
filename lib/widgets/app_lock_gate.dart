import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';

/// Keeps the current navigation tree alive while covering it with a system
/// authentication gate whenever the app is launched or returns from the
/// background.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.controller, required this.child, super.key});

  final AppController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  var _locked = false;
  var _busy = false;
  var _startup = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_handleControllerChange);
    _locked = widget.controller.appLockEnabled;
    if (_locked) {
      _startup = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.appLockEnabled &&
        !widget.controller.appLockEnabled) {
      setState(() {
        _locked = false;
        _message = null;
      });
    }
    // Enabling is authenticated by SettingsScreen before persistence. Do not
    // immediately prompt a second time; the next launch/resume is gated.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final enabled = widget.controller.appLockEnabled;
    if (_startup) {
      _startup = false;
      if (enabled && mounted) {
        setState(() {
          _locked = true;
          _message = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
      }
      return;
    }
    if (!enabled && _locked && mounted) {
      setState(() {
        _locked = false;
        _message = null;
      });
    }
    // Enabling from Settings has just been authenticated there; the new gate
    // takes effect on the next launch or lifecycle resume.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.controller.appLockEnabled) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (mounted) {
        setState(() {
          _locked = true;
          _message = null;
        });
      }
    } else if (state == AppLifecycleState.resumed && _locked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (!widget.controller.appLockEnabled || _busy || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final authenticated = await widget.controller.appLockService.authenticate(
      localizedReason: AppLocalizations.of(context).tr('appLockReason'),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _locked = !authenticated;
      _message = authenticated
          ? null
          : AppLocalizations.of(context).tr('appLockFailed');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked || !widget.controller.appLockEnabled) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).tr('appLock'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).tr('appLockHelp'),
                      textAlign: TextAlign.center,
                    ),
                    if (_message != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _authenticate,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(AppLocalizations.of(context).tr('unlockApp')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
