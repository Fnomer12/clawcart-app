import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_settings.dart';
import 'app/theme.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'providers/search_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

if (!kReleaseMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}

  if (!kReleaseMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }

  runApp(const ClawCartApp());
}

class ClawCartApp extends StatelessWidget {
  const ClawCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>(
          create: (_) => AppSettings(),
        ),
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => SearchProvider(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}