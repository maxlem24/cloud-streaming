
// lib/features/Stream/video_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/app_mqtt_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:twinsa/widgets/app_sidebar.dart';
import 'widgets/video_card.dart';
import 'package:twinsa/widgets/ui_atoms.dart';

// TODO(DATABASE): Créer le modèle Video
// class Video {
//   final String id;
//   final String title;
//   final String coverUrl;
//   final String category;
//   final String genre;
//   final int year;
//   final double rating;
//   final String creatorId;
//   final String creatorName;
//   final String creatorAvatar;
//   final int views;
//   final DateTime uploadDate;
//   final int duration; // en secondes
// }

// TODO(API): Créer le service VideoService
// class VideoService {
//   Future<List<Video>> getAllVideos() async { }
//   Future<List<Video>> getVideosByCategory(String category) async { }
//   Future<List<Video>> searchVideos(String query) async { }
//   Future<Video> getVideoById(String id) async { }
//   Stream<List<Video>> watchVideos() { }
// }

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});
  static const String routeName = 'Videos';
  static const String routePath = '/videos';

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  // TODO(DATABASE): Remplacer par des données de la base de données
  // Ces données devraient venir de :
  // - Firestore collection "videos"
  // - SQL table "videos"
  // - API endpoint "/api/videos"
  final List<Map<String, dynamic>> _videos = [
    {
      'title': 'Aquaman',
      'year': '2018',
      'genre': 'Fantasy / SF',
      'category': 'Fantasy',
      'cover': 'https://image.tmdb.org/t/p/w500/ydUpl3QkVUCHCq1VWvo2rW4Sf7y.jpg',
      'rating': '7.7',
      'creator': 'StreamerPro',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'views': 2400,
    },
    {
      'title': 'The Dark Knight',
      'year': '2008',
      'genre': 'Drama / Thriller',
      'category': 'Action',
      'cover': 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      'rating': '9.0',
      'creator': 'CinemaKing',
      'avatar': 'https://i.pravatar.cc/150?img=8',
      'views': 5100,
    },
    {
      'title': 'Avatar',
      'year': '2009',
      'genre': 'Fantasy / SF',
      'category': 'Science Fiction',
      'cover': 'https://image.tmdb.org/t/p/w500/kyeqWdyUXW608qlYkRqosgbbJyK.jpg',
      'rating': '7.8',
      'creator': 'EpicGamer',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'views': 3200,
    },
  ];

  late final List<String> _categories = ['All', ...{for (final v in _videos) v['category']! as String}];
  String _selectedCategory = 'All';
  String _sortBy = 'Most Recent';
  final AppMqttService _mqtt = AppMqttService.instance;


  @override
  void initState() {
    super.initState();
    _initMqtt();
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
    final videos = _mqtt.nonLiveVideos;
    // TODO(DATABASE): Utiliser les vraies données
    final lives = _mqtt.liveVideos;
    var filtered = _selectedCategory == 'All'
        ? List<Map<String, dynamic>>.from(_videos)
        : _videos.where((e) => e['category'] == _selectedCategory).toList();

    // Tri
    if (_sortBy == 'Most Popular') {
      filtered.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));
    } else if (_sortBy == 'Top Rated') {
      filtered.sort((a, b) {
        final ratingA = double.tryParse(a['rating'] as String? ?? '0') ?? 0;
        final ratingB = double.tryParse(b['rating'] as String? ?? '0') ?? 0;
        return ratingB.compareTo(ratingA);
      });
    }



    return Scaffold(
      backgroundColor: theme.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackdrop(),
          Row(
            children: [
              const AppSidebar(currentKey: 'videos'),
              Expanded(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width = c.maxWidth;
                      const tileMin = 200.0, gutter = 14.0;
                      final cols = math.max(2, (width / (tileMin + gutter)).floor());
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Spacer(),
                                LabeledDropdown<String>(
                                  label: 'Filter by',
                                  value: _selectedCategory,
                                  items: _categories
                                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                                  width: 180,
                                ),
                                const SizedBox(width: 12),
                                LabeledDropdown<String>(
                                  label: 'Order by',
                                  value: _sortBy,
                                  items: const ['Most Recent', 'Most Popular', 'Top Rated']
                                      .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _sortBy = val ?? _sortBy),
                                  width: 180,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: gutter,
                                  mainAxisSpacing: gutter,
                                  childAspectRatio: .7,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final v = filtered[i];
                                  return VideoCard(
                                    title: v['title']! as String,
                                    subtitle: '${v['year']} • ${v['genre']}',
                                    coverUrl: v['cover']! as String,
                                    rating: v['rating'] as String?,
                                    creatorName: v['creator'] as String?,
                                    creatorAvatar: v['avatar'] as String?,
                                    viewCount: '${_formatViews(v['views'] as int)}',
                                    isLive: false,
                                    // TODO(NAVIGATION): Implémenter la navigation vers le player vidéo
                                    onTap: () {
                                      // Navigator.pushNamed(context, '/video/${v['id']}');
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}