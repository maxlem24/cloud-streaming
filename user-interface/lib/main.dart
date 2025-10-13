import 'package:flutter/material.dart';
import 'flutter_flow/flutter_flow_theme.dart';

// Pages
import 'homepage_widget.dart';
import 'features/Auth/signIN.dart';
import 'features/Auth/logIn.dart';
import 'features/HomePage2/catalogue_page.dart';
import 'features/Stream/video_page.dart';
import 'features/Stream/live_page.dart';
import 'features/Auth/profile.dart';
import 'features/Stream/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwInsaApp());
}

class TwInsaApp extends StatelessWidget {
  const TwInsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterFlowTheme.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TW'INSA",
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xADFF2DAC),
          secondary: Color(0xFF7F5AF0),
        ),
        useMaterial3: false,
      ),
      initialRoute: '/', // Home d’accueil
      routes: {
        '/': (_) => const HomepageWidget(),
        '/login': (_) => const LoginPage(),
        '/signin': (_) => const SignINPage(),
        '/catalogue': (_) => const CataloguePage(),
        '/videos': (_) => const VideoPage(),
        '/lives': (_) => const LivePage(),
        '/profile': (_) => const ProfilePage(),
        '/settings': (_) =>const SettingsPage(),
      },
    );
  }
}
