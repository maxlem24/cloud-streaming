import 'package:flutter/material.dart';
import 'package:twinsa/services/app_mqtt_service.dart';
import 'package:twinsa/widgets/splash_screen.dart';
import 'features/live/streamer_page3.dart';
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

//Signature


//BD
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect BD
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
  //await PermissionService.ensurePermissions();

  //final directory = await getApplicationDocumentsDirectory();

  //var id = "abracadabra";
  //var base64ID ="asM3qgVWaUD69mFRBNuuuVukvm8uCuHmPdCAdRTL1X+8dtmxHu2FMS+gT/yEsMBi8euJkJDHHawwR4T7A8RroVgerrHAJWvCwsJe8TChxQb3JvrpwatCVJYTiYebX3p0f/pGZL8z4g3DJbVngYnWXXivLMZ5xNOlsFp+wCvp2bw=:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ2zDqW1lbnQgZXQgTWF4aW1lIMOgIDJoIGRlIG1hdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  //await Signature.owner_init(id, base64ID);
  //var result = await Signature.owner_sign("assets/images/noises.jpg");

  //await Signature.writeTextFile('video.txt', result);

  //var data1= result.split('\n')[1];
  //var result_client = await Signature.client_verify(data1);
  //var result_path = await Signature.client_merge('${directory.path}/video.txt');
  // print(result_client);
  //print(result_path);
  //WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwInsaApp());
}

class TwInsaApp extends StatelessWidget {
  const TwInsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterFlowTheme.of(context);
    VideoItem v = VideoItem(id: '0', title: 'title', description: 'description', category: 'category', live: true, edges: 'edges', thumbnail: 'thumbnail', streamerId: 'streamerId', createdAt: null);

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
      initialRoute: SplashScreen.routePath,
      routes: {
        SplashScreen.routePath: (_) => const SplashScreen(),
        // App routes
        '/': (_) => const HomepageWidget(),
        '/login': (_) => const LoginPage(),
        '/signin': (_) => const SignINPage(),
        '/catalogue': (_) => const CataloguePage(),
        '/videos': (_) => const VideoPage(),
        '/lives': (_) => const LivePage(),
        '/profile': (_) => const ProfilePage(),
        '/settings': (_) => const SettingsPage(),
        '/go_live': (_) =>  const GoLive()
      },
    );
  }
}



