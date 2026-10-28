import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/platform_localizations.dart';
import 'screens/app_shell.dart';
import 'screens/country_selection_screen.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';
import 'widgets/app_lock_gate.dart';

class VycetkaApp extends StatelessWidget {
  const VycetkaApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            onGenerateTitle: (context) => context.tr('appTitle'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: controller.themeMode,
            locale: controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              AppMaterialFallbackLocalizationsDelegate(),
              AppCupertinoFallbackLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // builder wraps Navigator as well as every pushed route and dialog.
            builder: (context, child) => AppLockGate(
              controller: controller,
              child: child ?? const SizedBox.shrink(),
            ),
            home: controller.loading
                ? const _LoadingScreen()
                : controller.errorMessage != null
                ? Scaffold(
                    body: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SelectableText(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )
                : controller.countryConfirmedForRun
                ? const AppShell()
                : const CountrySelectionScreen(),
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
