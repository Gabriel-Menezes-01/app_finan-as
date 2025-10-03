import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/financas_provider.dart';
import 'screens/home_screen.dart';

/// Inicializa configurações de janela para Windows Desktop
Future<void> _initWindow() async {
  // Inicializa window_manager somente em desktop Windows
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1100, 700),
      minimumSize: Size(900, 600),
      center: true,
      title: 'Finanças App',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

/// Inicializa Firebase apenas em plataformas suportadas (Android/iOS/Web)
Future<void> _initFirebaseIfSupported() async {
  // Inicializar Firebase apenas em plataformas suportadas
  if (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS))) {
    try {
      await Firebase.initializeApp();
      print('Firebase inicializado com sucesso');
    } catch (e) {
      print('Firebase não disponível, continuando sem: $e');
    }
  } else {
    print('Plataforma desktop detectada: pulando inicialização do Firebase');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  // Inicializar janela (Windows Desktop)
  await _initWindow();
  
  // Inicializar Firebase apenas se suportado
  await _initFirebaseIfSupported();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FinancasProvider(),
      child: MaterialApp(
        title: 'Finanças App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
