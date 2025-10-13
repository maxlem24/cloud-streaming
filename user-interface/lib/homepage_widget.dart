import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'homepage_model.dart';
export 'homepage_model.dart';

// Page Route
import 'features/Auth/signIN.dart';
import 'features/Auth/logIn.dart';

// Utilitaires
import 'widgets/ui_atoms.dart';


class CategoryItem {
  final String label;
  final String live;
  final String image;
  const CategoryItem({
    required this.label,
    required this.live,
    required this.image,
  });
}

/// --- Category data
const categories = <CategoryItem>[
  CategoryItem(
    label: 'Gaming',
    live: '12.5K live',
    image:
    'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=1200&q=80',
  ),
  CategoryItem(
    label: 'Art & Creative',
    live: '3.7K live',
    image:
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
  ),
  CategoryItem(
    label: 'Music',
    live: '8.2K live',
    image:
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
  ),
  CategoryItem(
    label: 'Just Chatting',
    live: '15.8K live',
    image:
    'https://images.unsplash.com/photo-1516245834210-c4c142787335?auto=format&fit=crop&w=1200&q=80',
  ),
];

class HomepageWidget extends StatefulWidget {
  const HomepageWidget({super.key});

  static String routeName = 'Homepage';
  static String routePath = '/homepage';

  @override
  State<HomepageWidget> createState() => _HomepageWidgetState();
}

class _HomepageWidgetState extends State<HomepageWidget> {
  late HomepageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomepageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.bgSoft,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: GlassBar(
              child: Row(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/twinsa_logo_bg.png',
                        height: 34,
                        width: 34,
                        errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 34, height: 34),
                      ),
                      const SizedBox(width: 10),
                      GradientText(
                        "TW'INSA",
                        gradient: LinearGradient(
                          colors: [theme.primary, pairColor(theme.primary)],
                        ),
                        style: theme.titleLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w800,
                            fontStyle: theme.titleLarge.fontStyle,
                          ),
                          letterSpacing: .4,
                          color: theme.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      FFButtonWidget(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signin'),
                        text: 'Sign In',
                        options: FFButtonOptions(
                          height: 40,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              18, 0, 18, 0),
                          iconPadding: EdgeInsets.zero,
                          color: Colors.transparent,
                          textStyle: theme.bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontStyle: theme.bodyMedium.fontStyle,
                            ),
                            color: const Color(0xFFCACACA),
                          ),
                          elevation: 0,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FFButtonWidget(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/login'),
                        text: 'Log In',
                        options: FFButtonOptions(
                          height: 40,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              18, 0, 18, 0),
                          iconPadding: EdgeInsets.zero,
                          color: theme.primary,
                          textStyle: theme.bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontStyle: theme.bodyMedium.fontStyle,
                            ),
                            color: theme.bg,
                          ),
                          elevation: 0,
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const AnimatedBackdrop(),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // HERO
                    Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 500,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.transparent],
                              stops: [0.65, 1.0],
                            ).createShader(rect),
                            child: Image.asset(
                              'images/Home_page.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 500,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.bg.withOpacity(.20),
                                theme.bg.withOpacity(.55),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: GlassGradientBorder(
                                  radius: 24,
                                  innerPadding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 32),
                                  gradient: LinearGradient(colors: [
                                    theme.primary,
                                    pairColor(theme.primary)
                                  ]),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'TW\'INSA',
                                        textAlign: TextAlign.center,
                                        style: theme.displayLarge.override(
                                          font: GoogleFonts.interTight(
                                            fontWeight: FontWeight.w900,
                                            fontStyle:
                                            theme.displayLarge.fontStyle,
                                          ),
                                          color: theme.white,
                                          fontSize: 54,
                                          letterSpacing: .5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Opacity(
                                        opacity: .9,
                                        child: Text(
                                          'Your Gateway to Live Entertainment',
                                          textAlign: TextAlign.center,
                                          style:
                                          theme.headlineMedium.override(
                                            font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w500,
                                              fontStyle: theme
                                                  .headlineMedium.fontStyle,
                                            ),
                                            color: const Color(0xFFECECEC),
                                            letterSpacing: .2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          HoverScale(
                                            child: FFButtonWidget(
                                              onPressed: () => debugPrint(
                                                  'Start Streaming pressed'),
                                              text: 'Start Streaming',
                                              icon: const Icon(
                                                  Icons.videocam_rounded,
                                                  size: 20),
                                              options: FFButtonOptions(
                                                height: 50,
                                                padding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                    30, 0, 30, 0),
                                                iconPadding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                    0, 0, 0, 0),
                                                iconColor: theme.white,
                                                color: theme.primary,
                                                textStyle: theme
                                                    .titleMedium
                                                    .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    fontStyle: theme
                                                        .titleMedium
                                                        .fontStyle,
                                                  ),
                                                  color: theme.bg,
                                                ),
                                                elevation: 6,
                                                borderRadius:
                                                BorderRadius.circular(28),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          HoverScale(
                                            child: FFButtonWidget(
                                              // CHANGEMENT ICI : pushNamed au lieu de pushReplacementNamed
                                              onPressed: () => Navigator.pushNamed(context, '/catalogue'),
                                              text: 'Browse Streams',
                                              icon: const Icon(
                                                  Icons
                                                      .play_circle_outline_rounded,
                                                  size: 20),
                                              options: FFButtonOptions(
                                                height: 50,
                                                padding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                    30, 0, 30, 0),
                                                iconPadding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                    0, 0, 0, 0),
                                                iconColor: theme.primary,
                                                color: Colors.transparent,
                                                textStyle: theme
                                                    .titleMedium
                                                    .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    fontStyle: theme
                                                        .titleMedium
                                                        .fontStyle,
                                                  ),
                                                  color: theme.primary,
                                                ),
                                                elevation: 0,
                                                borderSide: BorderSide(
                                                  color: theme.primary,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(28),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // FEATURE BANNER
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: ConstrainedBox(
                        constraints:
                        const BoxConstraints(maxWidth: 1100),
                        child: HoverLift(
                          child: Glass(
                            radius: 18,
                            padding: const EdgeInsets.all(22),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hd_rounded,
                                    color: theme.primary, size: 40),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ultra HD Quality',
                                      style: theme.titleMedium.override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w700,
                                          fontStyle:
                                          theme.titleMedium.fontStyle,
                                        ),
                                        color: theme.white,
                                      ),
                                    ),
                                    Opacity(
                                      opacity: .85,
                                      child: Text(
                                        'Stream and watch in crystal clear 4K resolution',
                                        style: theme.bodyMedium.override(
                                          font: GoogleFonts.inter(
                                            fontWeight: theme
                                                .bodyMedium.fontWeight,
                                            fontStyle: theme
                                                .bodyMedium.fontStyle,
                                          ),
                                          color: const Color(0xFFCDCDCD),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // MAIN SECTION
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 40, 20, 40),
                      child: ConstrainedBox(
                        constraints:
                        const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          children: [
                            // Why Choose
                            Column(
                              children: [
                                Text(
                                  'Why Choose TW\'INSA?',
                                  textAlign: TextAlign.center,
                                  style: theme.headlineLarge.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w800,
                                      fontStyle:
                                      theme.headlineLarge.fontStyle,
                                    ),
                                    color: theme.white,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GridView(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 24,
                                    childAspectRatio: 0.9,
                                  ),
                                  primary: false,
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  children: [
                                    _featureCard(
                                      context,
                                      icon: Icons.flash_on_rounded,
                                      title: 'Low Latency',
                                      subtitle:
                                      'Real-time interaction with minimal delay',
                                    ),
                                    _featureCard(
                                      context,
                                      icon: Icons.people_rounded,
                                      title: 'Global Community',
                                      subtitle:
                                      'Connect with millions of viewers worldwide',
                                    ),
                                    _featureCard(
                                      context,
                                      icon: Icons.privacy_tip,
                                      title: 'Safe Environment',
                                      subtitle:
                                      'Be safe thank to end-to-end encrypted data',
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 44),

                            // Popular Categories
                            Column(
                              children: [
                                Text(
                                  'Popular Categories',
                                  textAlign: TextAlign.center,
                                  style: theme.headlineLarge.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w800,
                                      fontStyle:
                                      theme.headlineLarge.fontStyle,
                                    ),
                                    color: theme.white,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.8,
                                  ),
                                  primary: false,
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  itemCount: categories.length,
                                  itemBuilder: (context, i) {
                                    final c = categories[i];
                                    return _categoryTile(
                                      context,
                                      label: c.label,
                                      live: c.live,
                                      image: c.image,
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 48),

                            // CTA
                            HoverLift(
                              child: GlassGradientBorder(
                                radius: 22,
                                innerPadding: const EdgeInsets.all(40),
                                gradient: LinearGradient(colors: [
                                  theme.primary,
                                  pairColor(theme.primary)
                                ]),
                                child: Column(
                                  children: [
                                    Text(
                                      'Ready to Start Your Journey?',
                                      textAlign: TextAlign.center,
                                      style: theme.headlineMedium.override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w800,
                                          fontStyle: theme
                                              .headlineMedium.fontStyle,
                                        ),
                                        color: theme.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Opacity(
                                      opacity: .9,
                                      child: Text(
                                        'Join thousands of streamers and millions of viewers in the ultimate live streaming experience',
                                        textAlign: TextAlign.center,
                                        style: theme.bodyLarge.override(
                                          font: GoogleFonts.inter(
                                            fontWeight: theme
                                                .bodyLarge.fontWeight,
                                            fontStyle: theme
                                                .bodyLarge.fontStyle,
                                          ),
                                          color: const Color(0xFFCDCDCD),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        FFButtonWidget(
                                          onPressed: () => debugPrint(
                                              'Create Account pressed'),
                                          text: 'Create Account',
                                          options: FFButtonOptions(
                                            height: 50,
                                            padding:
                                            const EdgeInsetsDirectional
                                                .fromSTEB(
                                                30, 0, 30, 0),
                                            iconPadding: EdgeInsets.zero,
                                            color: theme.primary,
                                            textStyle: theme
                                                .titleMedium
                                                .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w700,
                                                fontStyle: theme
                                                    .titleMedium
                                                    .fontStyle,
                                              ),
                                              color: theme.bg,
                                            ),
                                            elevation: 6,
                                            borderRadius:
                                            BorderRadius.circular(28),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        FFButtonWidget(
                                          onPressed: () => debugPrint(
                                              'Learn More pressed'),
                                          text: 'Learn More',
                                          options: FFButtonOptions(
                                            height: 50,
                                            padding:
                                            const EdgeInsetsDirectional
                                                .fromSTEB(
                                                30, 0, 30, 0),
                                            iconPadding: EdgeInsets.zero,
                                            color: Colors.transparent,
                                            textStyle: theme
                                                .titleMedium
                                                .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w700,
                                                fontStyle: theme
                                                    .titleMedium
                                                    .fontStyle,
                                              ),
                                              color: theme.primary,
                                            ),
                                            elevation: 0,
                                            borderSide: BorderSide(
                                              color: theme.primary,
                                              width: 2,
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(28),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FOOTER
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: ConstrainedBox(
                        constraints:
                        const BoxConstraints(maxWidth: 1100),
                        child: Glass(
                          radius: 20,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Text(
                                'TW\'INSA is an open source project made by INSA HdF students',
                                textAlign: TextAlign.center,
                                style: theme.headlineMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w800,
                                    fontStyle:
                                    theme.headlineMedium.fontStyle,
                                  ),
                                  color: theme.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: .9,
                                child: Text(
                                  'Legal Notice',
                                  textAlign: TextAlign.center,
                                  style: theme.bodyLarge.override(
                                    font: GoogleFonts.inter(
                                      fontWeight:
                                      theme.bodyLarge.fontWeight,
                                      fontStyle:
                                      theme.bodyLarge.fontStyle,
                                    ),
                                    color: const Color(0xFFCDCDCD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    final theme = FlutterFlowTheme.of(context);
    return HoverLift(
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(
              icon: icon,
              gradient: LinearGradient(
                colors: [theme.primary, pairColor(theme.primary)],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  fontStyle: theme.titleMedium.fontStyle,
                ),
                color: theme.white,
              ),
            ),
            Opacity(
              opacity: .9,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight: theme.bodyMedium.fontWeight,
                    fontStyle: theme.bodyMedium.fontStyle,
                  ),
                  color: theme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(
      BuildContext context, {
        required String label,
        required String live,
        required String image,
      }) {
    final theme = FlutterFlowTheme.of(context);
    return HoverScale(
      child: Container(
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withOpacity(.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.bg.withOpacity(.35),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: theme.bg);
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.bg,
                  alignment: Alignment.center,
                  child:  Icon(Icons.broken_image, color: theme.white),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.bg.withOpacity(.0), theme.bg.withOpacity(.55)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [theme.bg.withOpacity(.75), theme.bg.withOpacity(.45)],
                        ),
                        border: Border.all(color: theme.white.withOpacity(.12)),
                      ),
                      child: Text(
                        label,
                        style: theme.titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w800,
                            fontStyle: theme.titleMedium.fontStyle,
                          ),
                          color: theme.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      live,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(
                          fontWeight: theme.bodySmall.fontWeight,
                          fontStyle: theme.bodySmall.fontStyle,
                        ),
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.white.withOpacity(.07), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}