import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(const ProviderScope(child: _UniSapsBootstrap()));
}

class _UniSapsBootstrap extends StatefulWidget {
  const _UniSapsBootstrap();

  @override
  State<_UniSapsBootstrap> createState() => _UniSapsBootstrapState();
}

class _UniSapsBootstrapState extends State<_UniSapsBootstrap> {
  late final Future<void> _initFuture = _initialize();

  Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } on FirebaseException catch (e) {
      // Sur certains environnements (Android natif qui initialise Firebase avant Flutter),
      // l'app par défaut peut déjà exister. Dans ce cas on ignore simplement.
      final msg = e.message ?? '';
      if (e.code != 'duplicate-app' &&
          !msg.contains('already exists') &&
          !msg.contains('already exist')) {
        rethrow;
      }
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Erreur au démarrage',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$error',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return const UniSapsApp();
      },
    );
  }
}
