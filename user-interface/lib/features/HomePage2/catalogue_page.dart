/*
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/app_mqtt_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:twinsa/widgets/ui_atoms.dart';
import 'package:twinsa/widgets/app_sidebar.dart';




class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});
  static String routeName = 'Catalogue';
  static String routePath = '/catalogue';

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage>
    with SingleTickerProviderStateMixin {
  String _currentKey = 'home';

  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 22))
    ..repeat(reverse: true);
  final AppMqttService _mqtt = AppMqttService.instance;


  @override
  void initState() {
    super.initState();
    //_initMqtt();
  }

  Future<void> _initMqtt() async {
    if (!_mqtt.isConnected) {
      await _mqtt.initAndConnect();
    }
    await _mqtt.refreshVideos();
    setState(() {});
  }




  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final lives = _mqtt.liveVideos;
    final videos = _mqtt.nonLiveVideos;

    return Scaffold(
      backgroundColor: theme.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackdrop(),
          Row(
            children: [
              AppSidebar(
                currentKey: _currentKey,
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CatalogueContent(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogueContent extends StatelessWidget {
  _CatalogueContent({super.key});

  // ===========================
  // TODO(DATA): REMPLACER PAR DES DONNÉES DE LA BASE DE DONNÉES
  // ===========================
  // TODO(DATABASE): Remplacer par Stream<List<LiveStream>> ou Future<List<LiveStream>>
  // Ces données devraient venir de :
  // - Une collection Firestore "live_streams"
  // - Une table SQL "live_streams"
  // - Une API REST endpoint "/api/lives/current"
  final List<String> liveCarousel = const [
    'https://picsum.photos/seed/live1/1200/700',
    'https://picsum.photos/seed/live2/1200/700',
    'https://picsum.photos/seed/live3/1200/700',
  ];

  // TODO(DATABASE): Remplacer par Stream<List<Video>> ou Future<List<Video>>
  // Ces données devraient venir de :
  // - Une collection Firestore "videos" avec orderBy("views", descending: true)
  // - Une table SQL avec requête SELECT * FROM videos ORDER BY views DESC LIMIT 10
  // - Une API REST endpoint "/api/videos/top"
  final List<_Poster> topVideos = const [
    _Poster('League of Legends', 'https://picsum.photos/seed/lol/600/800'),
    _Poster('Fortnite', 'https://picsum.photos/seed/fortnite/600/800'),
    _Poster('Call of Duty', 'https://picsum.photos/seed/cod/600/800'),
    _Poster('PUBG', 'https://picsum.photos/seed/pubg/600/800'),
    _Poster('Dota 2', 'https://picsum.photos/seed/dota/600/800'),
    _Poster('Hearthstone', 'https://picsum.photos/seed/hs/600/800'),
    _Poster('WoW', 'https://picsum.photos/seed/wow/600/800'),
  ];

  // TODO(DATABASE): Remplacer par Stream<List<LiveStream>> ou Future<List<LiveStream>>
  // Ces données devraient venir de :
  // - Une collection Firestore "live_streams" avec where("isLive", isEqualTo: true)
  // - Une API endpoint "/api/lives/active"
  final List<_Poster> topLives = const [
    _Poster('Speedrun Live', 'https://picsum.photos/seed/speedrun/1200/675'),
    _Poster('Pro League', 'https://picsum.photos/seed/proleague/1200/675'),
    _Poster('Indie Night', 'https://picsum.photos/seed/indie/1200/675'),
    _Poster('Chill Stream', 'https://picsum.photos/seed/chill/1200/675'),
    _Poster('Arena Finals', 'https://picsum.photos/seed/arena/1200/675'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final isNarrow = maxW < 920;

        final carouselAspect = 21 / 9;
        final shelfCardWVideos = isNarrow ? 150.0 : 180.0;
        final shelfCardWLives = isNarrow ? 170.0 : 200.0;

        // TODO(UI): Utiliser StreamBuilder ou FutureBuilder pour afficher les données
        // Example:
        // StreamBuilder<List<LiveStream>>(
        //   stream: LiveService.getCurrentLives(),
        //   builder: (context, snapshot) {
        //     if (snapshot.hasError) return ErrorWidget();
        //     if (!snapshot.hasData) return LoadingWidget();
        //     return _LiveCarousel(lives: snapshot.data!);
        //   },
        // )

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: "Live en cours",
                // TODO(NAVIGATION): Implémenter la navigation vers la page "Tous les lives"
                onShowAll: () {
                  // Navigator.pushNamed(context, '/all-lives');
                },
              ),
              const SizedBox(height: 10),
              _LiveCarousel(
                images: liveCarousel,
                aspectRatio: carouselAspect,
                // TODO(INTERACTION): Ajouter onTap pour naviguer vers le live
                // onTap: (liveId) => Navigator.pushNamed(context, '/live/$liveId')
              ),
              const SizedBox(height: 22),

              _SectionHeader(
                title: "Top vidéos streaming",
                // TODO(NAVIGATION): Implémenter la navigation vers la page vidéos
                onShowAll: () {
                  // Navigator.pushNamed(context, VideoPage.routePath);
                },
              ),
              const SizedBox(height: 8),
              _MediaShelf(
                posters: topVideos,
                targetCardWidth: shelfCardWVideos,
                aspectRatio: 3 / 4,
                // TODO(INTERACTION): Ajouter onTap pour naviguer vers la vidéo
                // onTap: (videoId) => Navigator.pushNamed(context, '/video/$videoId')
              ),
              const SizedBox(height: 22),

              _SectionHeader(
                title: "Top lives",
                // TODO(NAVIGATION): Implémenter la navigation vers la page lives
                onShowAll: () {
                  // Navigator.pushNamed(context, LivePage.routePath);
                },
              ),
              const SizedBox(height: 8),
              _MediaShelf(
                posters: topLives,
                targetCardWidth: shelfCardWLives,
                aspectRatio: 16 / 9,
                showLiveBadge: true,
                // TODO(INTERACTION): Ajouter onTap pour naviguer vers le live
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onShowAll});
  final String title;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const Spacer(),
        if (onShowAll != null)
          TextButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text("Voir tout"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(.85),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveCarousel extends StatefulWidget {
  const _LiveCarousel({
    required this.images,
    this.aspectRatio = 16 / 9,
  });
  final List<String> images;
  final double aspectRatio;

  @override
  State<_LiveCarousel> createState() => _LiveCarouselState();
}

class _LiveCarouselState extends State<_LiveCarousel> {
  final PageController _pc = PageController(viewportFraction: .9);
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.images.length - 1);
    _pc.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final img = widget.images[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.04),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _NetImage(img: img),
                        Container(color: Colors.black.withOpacity(.18)),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _LiveBadge(color: theme.primary),
                        ),
                        // TODO(UI): Ajouter les infos du live (titre, streamer, viewers)
                        // Positioned(
                        //   bottom: 12,
                        //   left: 12,
                        //   right: 12,
                        //   child: _LiveInfo(live: liveData),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          child: _CarouselArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () => _go(-1),
            enabled: _index > 0,
          ),
        ),
        Positioned(
          right: 0,
          child: _CarouselArrow(
            icon: Icons.chevron_right_rounded,
            onTap: () => _go(1),
            enabled: _index < widget.images.length - 1,
          ),
        ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.onTap,
    required this.enabled,
    required this.icon,
  });
  final VoidCallback onTap;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: color.withOpacity(.4), blurRadius: 12)],
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _MediaShelf extends StatelessWidget {
  const _MediaShelf({
    required this.posters,
    required this.targetCardWidth,
    required this.aspectRatio,
    this.showLiveBadge = false,
  });

  final List<_Poster> posters;
  final double targetCardWidth;
  final double aspectRatio;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: targetCardWidth / (aspectRatio) + 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: posters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = posters[i];
          return _PosterCard(
            poster: p,
            width: targetCardWidth,
            aspectRatio: aspectRatio,
            showLiveBadge: showLiveBadge && i < 2,
          );
        },
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.poster,
    required this.width,
    required this.aspectRatio,
    this.showLiveBadge = false,
  });

  final _Poster poster;
  final double width;
  final double aspectRatio;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withOpacity(.04)),
                  _NetImage(img: poster.imageUrl),
                  if (showLiveBadge)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _LiveBadge(color: theme.primary),
                    ),
                  // TODO(INTERACTION): Ajouter InkWell pour la navigation
                  // Positioned.fill(
                  //   child: Material(
                  //     color: Colors.transparent,
                  //     child: InkWell(
                  //       onTap: () => onTap?.call(poster.id),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            poster.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _NetImage extends StatelessWidget {
  const _NetImage({required this.img});
  final String img;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      img,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: Colors.white.withOpacity(.06),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}

class _Poster {
  // TODO(MODEL): Remplacer par un vrai modèle avec :
  // - String id
  // - String title
  // - String imageUrl
  // - String? streamerId
  // - int? viewerCount
  // - DateTime? startTime
  const _Poster(this.title, this.imageUrl);
  final String title;
  final String imageUrl;
}*/
import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:twinsa/widgets/ui_atoms.dart';
import 'package:twinsa/widgets/app_sidebar.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});
  static String routeName = 'Catalogue';
  static String routePath = '/catalogue';

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage>
    with SingleTickerProviderStateMixin {
  String _currentKey = 'home';

  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 22))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackdrop(),
          Row(
            children: [
              AppSidebar(
                currentKey: _currentKey,
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CatalogueContent(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogueContent extends StatelessWidget {
  _CatalogueContent({super.key});

  final List<_Poster> liveCarousel = const [
    _Poster('Championship Finals - Live Now', 0),
    _Poster('Music Festival Stream', 1),
    _Poster('Gaming Marathon 24/7', 2),
  ];

  final List<_Poster> topVideos = const [
    _Poster('League of Legends', 0),
    _Poster('Fortnite', 1),
    _Poster('Call of Duty', 2),
    _Poster('PUBG', 3),
    _Poster('Dota 2', 4),
    _Poster('Hearthstone', 5),
    _Poster('World of Warcraft', 6),
  ];

  final List<_Poster> topLives = const [
    _Poster('Speedrun Live', 0),
    _Poster('Pro League', 1),
    _Poster('Indie Night', 2),
    _Poster('Chill Stream', 3),
    _Poster('Arena Finals', 4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final isNarrow = maxW < 920;

        final carouselAspect = 21 / 9;
        final shelfCardWVideos = isNarrow ? 150.0 : 180.0;
        final shelfCardWLives = isNarrow ? 170.0 : 200.0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: "Live en cours",
                onShowAll: () {},
              ),
              const SizedBox(height: 10),
              _LiveCarousel(
                posters: liveCarousel,
                aspectRatio: carouselAspect,
              ),
              const SizedBox(height: 22),

              _SectionHeader(
                title: "Top vidéos streaming",
                onShowAll: () {},
              ),
              const SizedBox(height: 8),
              _MediaShelf(
                posters: topVideos,
                targetCardWidth: shelfCardWVideos,
                aspectRatio: 3 / 4,
              ),
              const SizedBox(height: 22),

              _SectionHeader(
                title: "Top lives",
                onShowAll: () {},
              ),
              const SizedBox(height: 8),
              _MediaShelf(
                posters: topLives,
                targetCardWidth: shelfCardWLives,
                aspectRatio: 16 / 9,
                showLiveBadge: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onShowAll});
  final String title;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const Spacer(),
        if (onShowAll != null)
          TextButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text("Voir tout"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(.85),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveCarousel extends StatefulWidget {
  const _LiveCarousel({
    required this.posters,
    this.aspectRatio = 16 / 9,
  });
  final List<_Poster> posters;
  final double aspectRatio;

  @override
  State<_LiveCarousel> createState() => _LiveCarouselState();
}

class _LiveCarouselState extends State<_LiveCarousel> {
  final PageController _pc = PageController(viewportFraction: .9);
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.posters.length - 1);
    _pc.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.posters.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final poster = widget.posters[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _getGradient(poster.colorIndex, theme),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _LiveBadge(color: theme.red),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                poster.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          child: _CarouselArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () => _go(-1),
            enabled: _index > 0,
          ),
        ),
        Positioned(
          right: 0,
          child: _CarouselArrow(
            icon: Icons.chevron_right_rounded,
            onTap: () => _go(1),
            enabled: _index < widget.posters.length - 1,
          ),
        ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.onTap,
    required this.enabled,
    required this.icon,
  });
  final VoidCallback onTap;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: color.withOpacity(.4), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaShelf extends StatelessWidget {
  const _MediaShelf({
    required this.posters,
    required this.targetCardWidth,
    required this.aspectRatio,
    this.showLiveBadge = false,
  });

  final List<_Poster> posters;
  final double targetCardWidth;
  final double aspectRatio;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: targetCardWidth / (aspectRatio) + 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: posters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = posters[i];
          return _PosterCard(
            poster: p,
            width: targetCardWidth,
            aspectRatio: aspectRatio,
            showLiveBadge: showLiveBadge,
          );
        },
      ),
    );
  }
}

class _PosterCard extends StatefulWidget {
  const _PosterCard({
    required this.poster,
    required this.width,
    required this.aspectRatio,
    this.showLiveBadge = false,
  });

  final _Poster poster;
  final double width;
  final double aspectRatio;
  final bool showLiveBadge;

  @override
  State<_PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<_PosterCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _getGradient(widget.poster.colorIndex, theme),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hover
                        ? theme.primary.withOpacity(.4)
                        : Colors.white.withOpacity(.1),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withOpacity(.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.showLiveBadge)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _LiveBadge(color: theme.red),
                      ),
                    if (_hover)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.poster.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LinearGradient _getGradient(int index, FlutterFlowTheme theme) {
  final gradients = [
    // Gradient 0: Primary dominant
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.primary, theme.bg],
    ),
    // Gradient 1: Accent dominant
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.accent, theme.bgSoft],
    ),
    // Gradient 2: Dark with primary
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.bg, theme.primary.withOpacity(.5)],
    ),
    // Gradient 3: Surface with accent
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.surface, theme.accent.withOpacity(.6)],
    ),
    // Gradient 4: BgSoft with primary
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.bgSoft, theme.primary],
    ),
    // Gradient 5: Dark purple
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF2D1B4E), theme.bg],
    ),
    // Gradient 6: Deep blue
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF1A2332), theme.primary.withOpacity(.4)],
    ),
  ];

  return gradients[index % gradients.length];
}

class _Poster {
  const _Poster(this.title, this.colorIndex);
  final String title;
  final int colorIndex;
}