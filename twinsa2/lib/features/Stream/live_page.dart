import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/app_mqtt_service.dart';
import '../live/viewer_page3.dart';
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
  String _selectedCategory = 'All';
  String _sortBy = 'Recently Started';
  final AppMqttService _mqtt = AppMqttService.instance;
  bool _isLoading = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _initMqtt();
  }

  Future<void> _initMqtt() async {
    setState(() => _isLoading = true);
    try {
      if (!_mqtt.isConnected) {
        await _mqtt.initAndConnect();
      }
      await _mqtt.refreshVideos();
    } catch (e) {
      debugPrint('Erreur init MQTT: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _getCategories(List<VideoItem> videos) {
    final cats = videos.map((v) => v.category).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<VideoItem> _filterAndSort(List<VideoItem> videos) {
    var filtered = _selectedCategory == 'All'
        ? List<VideoItem>.from(videos)
        : videos.where((v) => v.category == _selectedCategory).toList();

    if (_sortBy == 'Recently Started') {
      filtered.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        if (a.createdAt != null) return -1;
        if (b.createdAt != null) return 1;
        return 0;
      });
    } else if (_sortBy == 'Oldest First') {
      filtered.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        if (a.createdAt != null) return 1;
        if (b.createdAt != null) return -1;
        return 0;
      });
    } else if (_sortBy == 'A-Z') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return filtered;
  }

  List<VideoItem> _paginateItems(List<VideoItem> items) {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, items.length);
    if (start >= items.length) return [];
    return items.sublist(start, end);
  }

  int _getTotalPages(int itemCount) {
    return (itemCount / _itemsPerPage).ceil();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return 'Started ${diff.inDays}d ago';
    if (diff.inHours > 0) return 'Started ${diff.inHours}h ago';
    if (diff.inMinutes > 0) return 'Started ${diff.inMinutes}m ago';
    return 'Started now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final lives = _mqtt.liveVideos;

    final categories = _getCategories(lives);
    final filtered = _filterAndSort(lives);
    final paginated = _paginateItems(filtered);
    final totalPages = _getTotalPages(filtered.length);

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
                  child: _isLoading
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading live streams...',
                          style: TextStyle(
                            color: theme.white.withOpacity(.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : LayoutBuilder(
                    builder: (context, c) {
                      final width = c.maxWidth;
                      final isNarrow = width < 900;
                      const tileMin = 220.0, gutter = 16.0;
                      final cols = math.max(2, (width / (tileMin + gutter)).floor());

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 16 : 24,
                          vertical: isNarrow ? 12 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isNarrow) ...[
                              _CompactHeader(
                                theme: theme,
                                filtered: filtered,
                                categories: categories,
                                selectedCategory: _selectedCategory,
                                sortBy: _sortBy,
                                onCategoryChanged: (val) => setState(() {
                                  _selectedCategory = val ?? _selectedCategory;
                                  _currentPage = 1;
                                }),
                                onSortChanged: (val) => setState(() {
                                  _sortBy = val ?? _sortBy;
                                  _currentPage = 1;
                                }),
                                onRefresh: _initMqtt,
                              ),
                            ] else ...[
                              _FullHeader(
                                theme: theme,
                                filtered: filtered,
                                categories: categories,
                                selectedCategory: _selectedCategory,
                                sortBy: _sortBy,
                                onCategoryChanged: (val) => setState(() {
                                  _selectedCategory = val ?? _selectedCategory;
                                  _currentPage = 1;
                                }),
                                onSortChanged: (val) => setState(() {
                                  _sortBy = val ?? _sortBy;
                                  _currentPage = 1;
                                }),
                                onRefresh: _initMqtt,
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Content
                            Expanded(
                              child: filtered.isEmpty
                                  ? _EmptyState(theme: theme)
                                  : Column(
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        crossAxisSpacing: gutter,
                                        mainAxisSpacing: gutter,
                                        childAspectRatio: .72,
                                      ),
                                      itemCount: paginated.length,
                                      itemBuilder: (_, i) {
                                        final v = paginated[i];
                                        return VideoCard(
                                          title: v.title,
                                          subtitle: v.category.isNotEmpty ? v.category : 'Live Stream',
                                          isLive: true,
                                          creatorName: v.streamerId.isNotEmpty ? v.streamerId : null,
                                          uploadDate: _formatDate(v.createdAt),
                                          videoID: v.id,
                                          onTap: () {
                                            debugPrint('Play live: ${v.id} (edges: ${v.edges})');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LiveViewerPage(
                                                  videoId: v.id,
                                                ),
                                              ),
                                            );

                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  if (totalPages > 1) ...[
                                    const SizedBox(height: 20),
                                    _Pagination(
                                      theme: theme,
                                      currentPage: _currentPage,
                                      totalPages: totalPages,
                                      onPageChanged: (page) => setState(() => _currentPage = page),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
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
}

// Header version desktop
class _FullHeader extends StatelessWidget {
  const _FullHeader({
    required this.theme,
    required this.filtered,
    required this.categories,
    required this.selectedCategory,
    required this.sortBy,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final FlutterFlowTheme theme;
  final List<VideoItem> filtered;
  final List<String> categories;
  final String selectedCategory;
  final String sortBy;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.red.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.videocam, color: theme.red, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Streams',
                style: TextStyle(
                  color: theme.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'stream' : 'streams'} live',
                    style: TextStyle(
                      color: theme.white.withOpacity(.65),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (categories.length > 1) ...[
          LabeledDropdown<String>(
            label: 'Category',
            value: selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                .toList(),
            onChanged: onCategoryChanged,
            width: 160,
          ),
          const SizedBox(width: 12),
        ],
        LabeledDropdown<String>(
          label: 'Sort',
          value: sortBy,
          items: const ['Recently Started', 'Oldest First', 'A-Z']
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: onSortChanged,
          width: 160,
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.primary.withOpacity(.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.primary),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }
}

// Header version compact
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.theme,
    required this.filtered,
    required this.categories,
    required this.selectedCategory,
    required this.sortBy,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final FlutterFlowTheme theme;
  final List<VideoItem> filtered;
  final List<String> categories;
  final String selectedCategory;
  final String sortBy;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.red.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.videocam, color: theme.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Streams',
                    style: TextStyle(
                      color: theme.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${filtered.length} ${filtered.length == 1 ? 'stream' : 'streams'}',
                        style: TextStyle(
                          color: theme.white.withOpacity(.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primary.withOpacity(.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh_rounded, color: theme.primary, size: 20),
                onPressed: onRefresh,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (categories.length > 1) ...[
              Expanded(
                child: LabeledDropdown<String>(
                  label: 'Category',
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: LabeledDropdown<String>(
                label: 'Sort',
                value: sortBy,
                items: const ['Recently Started', 'Oldest First', 'A-Z']
                    .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                    .toList(),
                onChanged: onSortChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surface.withOpacity(.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: theme.white.withOpacity(.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No live streams available',
            style: TextStyle(
              color: theme.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for live content',
            style: TextStyle(
              color: theme.white.withOpacity(.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Pagination widget
class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.theme,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final FlutterFlowTheme theme;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          color: theme.white,
          disabledColor: theme.white.withOpacity(.3),
        ),
        const SizedBox(width: 8),
        ...List.generate(
          math.min(5, totalPages),
              (i) {
            int pageNum;
            if (totalPages <= 5) {
              pageNum = i + 1;
            } else if (currentPage <= 3) {
              pageNum = i + 1;
            } else if (currentPage >= totalPages - 2) {
              pageNum = totalPages - 4 + i;
            } else {
              pageNum = currentPage - 2 + i;
            }

            final isActive = pageNum == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onPageChanged(pageNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? theme.primary : theme.surface.withOpacity(.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? theme.primary : theme.white.withOpacity(.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: theme.white,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          color: theme.white,
          disabledColor: theme.white.withOpacity(.3),
        ),
      ],
    );
  }
}