import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:twinsa/widgets/app_sidebar.dart';
import 'widgets/video_card.dart';
import 'package:twinsa/widgets/ui_atoms.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  static const String routeName = 'Lives';
  static const String routePath = '/lives';

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final List<String> _categories = const ['All', 'Gaming', 'Music', 'Tech', 'Sports', 'News'];
  String _selected = 'All';
  String _sortBy = 'Most Viewers';

  final List<Map<String, dynamic>> _lives = [
    {
      'title': 'Pro League Finals',
      'year': '2025',
      'genre': 'Sports',
      'category': 'Sports',
      'cover': 'https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=800',
      'creator': 'ESportsLive',
      'avatar': 'https://i.pravatar.cc/150?img=33',
      'views': 12500,
    },
    {
      'title': 'Synthwave Set',
      'year': '2025',
      'genre': 'Music',
      'category': 'Music',
      'cover': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=800',
      'creator': 'DJNeon',
      'avatar': 'https://i.pravatar.cc/150?img=28',
      'views': 8200,
    },
    {
      'title': 'Rust Lang AMA',
      'year': '2025',
      'genre': 'Tech',
      'category': 'Tech',
      'cover': 'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?q=80&w=800',
      'creator': 'CodeMaster',
      'avatar': 'https://i.pravatar.cc/150?img=51',
      'views': 3700,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    var filtered = _selected == 'All'
        ? List<Map<String, dynamic>>.from(_lives)
        : _lives.where((e) => e['category'] == _selected).toList();

    // Tri
    if (_sortBy == 'Most Viewers') {
      filtered.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));
    } else if (_sortBy == 'Recently Started') {
      // Garder l'ordre actuel
    }

    return Scaffold(
      backgroundColor: theme.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackdrop(),
          Row(
            children: [
              const AppSidebar(currentKey: 'live'),
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
                                const Spacer(), // pousse à droite
                                LabeledDropdown<String>(
                                  label: 'Filter by',
                                  value: _selected,
                                  items: _categories
                                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selected = val ?? _selected),
                                  width: 180,
                                ),
                                const SizedBox(width: 12),
                                LabeledDropdown<String>(
                                  label: 'Order by',
                                  value: _sortBy,
                                  items: const ['Most Viewers', 'Recently Started']
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
                                    rating: null,
                                    creatorName: v['creator'] as String?,
                                    creatorAvatar: v['avatar'] as String?,
                                    viewCount: _formatViews(v['views'] as int),
                                    isLive: true,
                                    onTap: () {},
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

class _ModernFilter extends StatefulWidget {
  const _ModernFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final FlutterFlowTheme theme;

  @override
  State<_ModernFilter> createState() => _ModernFilterState();
}

class _ModernFilterState extends State<_ModernFilter> {
  bool _isOpen = false;
  final _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          setState(() => _isOpen = !_isOpen);
          if (_isOpen) {
            _showDropdown();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F24),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isOpen ? widget.theme.primary : Colors.white.withOpacity(.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withOpacity(.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.theme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: widget.theme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDropdown() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          entry.remove();
          setState(() => _isOpen = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.items.map((item) {
                        final isSelected = item == widget.value;
                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            entry.remove();
                            setState(() => _isOpen = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.theme.primary.withOpacity(.15)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: isSelected
                                          ? widget.theme.primary
                                          : Colors.white.withOpacity(.85),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    color: widget.theme.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(entry);
  }
}

// lib/features/Stream/live_page.dart

// TODO(DATABASE): Créer le modèle LiveStream
// class LiveStream {
//   final String id;
//   final String title;
//   final String coverUrl;
//   final String category;
//   final String genre;
//   final String streamerId;
//   final String streamerName;
//   final String streamerAvatar;
//   final int viewerCount;
//   final DateTime startedAt;
//   final bool isLive;
//   final String streamUrl;
// }

// TODO(API): Créer le service LiveService
// class LiveService {
//   Stream<List<LiveStream>> watchActiveLives() { }
//   Future<List<LiveStream>> getLivesByCategory(String category) async { }
//   Future<LiveStream> getLiveById(String id) async { }
//   Future<void> startLive(LiveStream live) async { }
//   Future<void> endLive(String liveId) async { }
// }

// TODO(REALTIME): Implémenter les mises à jour en temps réel
// - Utiliser WebSocket ou Firebase Realtime Database
// - Mettre à jour le nombre de viewers en temps réel
// - Notifier quand un live démarre/termine

// Note: Le reste du code de live_page.dart reste identique à video_page.dart
// mais avec les données des lives actifs au lieu des vidéos enregistrées