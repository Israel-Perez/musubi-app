import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/theme/app_theme.dart';

/// Raiz de la app: tema, rutas e idioma espanol (RNF-18).
class MusubiApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Musubi',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    locale: const Locale('es', 'MX'),
    supportedLocales: const [Locale('es', 'MX'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
    // Splash animado sobre la app ya construida (SCRUM-81).
    builder: (context, child) =>
        BrandSplash(child: child ?? const SizedBox.shrink()),
  );
}
