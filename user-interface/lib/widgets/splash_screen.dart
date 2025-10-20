import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routePath = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    final session = Supabase.instance.client.auth.currentSession;
    final logged = session?.user != null;
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(logged ? '/catalogue' : '/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary,
                  theme.bgSoft,
                  cs.primary,
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Container(
              width: 380,
              height: 520,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.white.withOpacity(.08)),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/twinsa_logo_bg.png',
                            height: 100,
                            width: 100,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "TW'INSA",
                            style: theme.titleMedium.override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w800,
                              ),
                              color: theme.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Let's Go Live!",
                        style: theme.headlineLarge.override(
                          font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w800),
                          color: theme.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Streaming starts in a few seconds...",
                        style: theme.bodySmall.override(
                          color: theme.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(
                              theme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // copyright
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Text(
              "© ${DateTime.now().year} TW'INSA",
              textAlign: TextAlign.center,
              style: theme.bodySmall.override(color: theme.white),
            ),
          ),
        ],
      ),
    );
  }
}