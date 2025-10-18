import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:twinsa/features/Stream/widgets/video_card.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../services/app_mqtt_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/ui_atoms.dart';
import '../live/viewer_page3.dart';


class VideoPage extends StatefulWidget {
  const VideoPage({super.key});
  static const String routeName = 'Videos';
  static const String routePath = '/videos';

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String _selectedCategory = 'All';
  String _sortBy = 'Most Recent';
  final AppMqttService _mqtt = AppMqttService.instance;
  bool _isLoading = false;

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

    if (_sortBy == 'Most Recent') {
      filtered.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        if (a.createdAt != null) return -1;
        if (b.createdAt != null) return 1;
        return 0;
      });
    } else if (_sortBy == 'Oldest') {
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
    } else if (_sortBy == 'Z-A') {
      filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    }

    return filtered;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year${diff.inDays >= 730 ? 's' : ''} ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month${diff.inDays >= 60 ? 's' : ''} ago';
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  Map<String, dynamic> buildLiveJsonMessage({
    required VideoItem video,
    required String streamerName, // streamer_nom
    required dynamic end,         // peut être bool, String, DateTime
  }) {
    // Normalise "end" si c’est un DateTime
    final normalizedEnd = (end is DateTime) ? end.toIso8601String() : end;

    return {
      "live_id":      video.id,            // message_json["video_id"]
      "end":          normalizedEnd,       // message_json["end"]
      "streamer_nom": streamerName,        // message_json["streamer_nom"]
      "category":     video.category,      // message_json["category"]
      "description":  video.description,   // message_json["description"]
      "thumbnail":    video.thumbnail,     // message_json["thumbnail"]
      "live_nom":     video.title,         // message_json["video_nom"]
      "streamer_id":  video.streamerId,    // message_json["streamer_id"]
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final videos = _mqtt.nonLiveVideos;


    final categories = _getCategories(videos);
    final filtered = _filterAndSort(videos);



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
                  child: _isLoading
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading videos...',
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
                      const tileMin = 220.0, gutter = 16.0;
                      final cols = math.max(2, (width / (tileMin + gutter)).floor());
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.video_library,
                                    color: theme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Video Library',
                                      style: TextStyle(
                                        color: theme.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${filtered.length} ${filtered.length == 1 ? 'video' : 'videos'} available',
                                      style: TextStyle(
                                        color: theme.white.withOpacity(.65),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Filters
                                if (categories.length > 1)
                                  LabeledDropdown<String>(
                                    label: 'Category',
                                    value: _selectedCategory,
                                    items: categories
                                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                                    width: 180,
                                  ),
                                const SizedBox(width: 12),
                                LabeledDropdown<String>(
                                  label: 'Sort by',
                                  value: _sortBy,
                                  items: const ['Most Recent', 'Oldest', 'A-Z', 'Z-A']
                                      .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _sortBy = val ?? _sortBy),
                                  width: 180,
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
                                    onPressed: _initMqtt,
                                    tooltip: 'Refresh',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // Content
                            Expanded(
                              child: filtered.isEmpty
                                  ? Center(
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
                                        Icons.video_library_outlined,
                                        size: 64,
                                        color: theme.white.withOpacity(.3),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No videos available',
                                      style: TextStyle(
                                        color: theme.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Videos will appear here once uploaded',
                                      style: TextStyle(
                                        color: theme.white.withOpacity(.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: gutter,
                                  mainAxisSpacing: gutter,
                                  childAspectRatio: .72,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final v = filtered[i];
                                  return VideoCard(
                                    title: v.title,
                                    subtitle: v.category.isNotEmpty ? v.category : 'Video',
                                    isLive: false,
                                    creatorName: v.streamerId.isNotEmpty ? v.streamerId : null,
                                    uploadDate: _formatDate(v.createdAt),
                                    onTap: () {
                                      if (v.edges.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('No stream information available'),
                                            backgroundColor: theme.red,
                                          ),
                                        );
                                        return;
                                      }

                                      try {

                                        final parts = v.edges.split(',');
                                        print(parts);
                                        final brokerParts = parts[0];
                                        print(brokerParts);
                                        final broker = '172.20.10.4';
                                        final port = 1883;
                                        final topic_main = "live/watch/${brokerParts}/";
                                        final topic = topic_main+v.id;

                                        print(topic_main);
                                        print(topic);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewerPage(
                                              broker: broker,
                                              port: port,
                                              topic: topic,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Mauvaise information de stream: $e'),
                                            backgroundColor: theme.red,
                                          ),
                                        );
                                      }
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
}