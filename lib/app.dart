import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_scaffold.dart';

/// Root MaterialApp with Persian locale and dark theme.
class ZhiroFactorApp extends StatelessWidget {
  const ZhiroFactorApp({super.key});

  static final GlobalKey<AppScaffoldState> scaffoldKey = GlobalKey<AppScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ژیروفاکتور',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppScaffold(key: scaffoldKey),
    );
  }
}
