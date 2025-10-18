import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/ui_atoms.dart';
import 'MQTT_viewer.dart';
import 'signature2.dart';

class ViewerPage extends StatefulWidget {
  final String broker;
  final int port;
  final String topic;

  const ViewerPage({
    Key? key,
    required this.broker,
    required this.port,
    required this.topic,
  }) : super(key: key);

  static const String routeName = 'Viewer';
  static const String routePath = '/viewer';

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  HashMap<String, List<String>> receivedPackets = HashMap();
  HashMap<String, String> final_packets = HashMap();

  MQTTViewer? mqttViewer;

  // For UI display
  String statusLog = 'Initializing...';
  int totalFrames = 0;
  int totalPackets = 0;

  // For image display
  String? currentImagePath;
  Image? currentImage;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    setState(() {
      statusLog = 'Connecting to MQTT broker...';
    });

    mqttViewer = MQTTViewer(
        broker: widget.broker,
        port: widget.port,
        topicBase: widget.topic,
        onConnected: (){
          if (mounted) {
            setState(() {
              statusLog = '✅ Connected to MQTT broker';
            });
          }
        },
        onMessage: (String topic, String payload) async { //TODO j ai cahnge
          totalPackets++;

          final receivedString = jsonDecode(payload);

          //var parts = receivedString.split('::');
          if (receivedString.length < 2) {
            if (mounted) {
              setState(() {
                statusLog = '⚠️ Invalid message format';
              });
            }
            return;
          }


          var frameId = receivedString['chunk_part'];//parts[0];
          var signaturePart = receivedString['chunk'];//parts.skip(1).join('::');
// TODO j ai change jusqu ici
          var previous = receivedPackets.putIfAbsent(frameId, () => [])
            ..add(signaturePart);

          if (mounted) {
            setState(() {
              statusLog = 'Receiving frame $frameId: ${previous.length}/8 packets';
            });
          }

          // Merge if 8 parts received
          if (previous.length == 8) {
            totalFrames++;
            String fullSignature = previous.join('\n');

            try {
              final sigDir = Directory('./signature');
              if (!await sigDir.exists()) {
                await sigDir.create(recursive: true);
              }

              File file = File('./signature/frame_$frameId.sig');
              await file.writeAsString(fullSignature);

              String merged_path = await Signature.client_merge(file.absolute.path);
              final_packets[frameId] = merged_path;

              // Load the image
              await _loadImage(merged_path.trim());

              // Clean up
              receivedPackets.remove(frameId);
              if (await file.exists()) {
                await file.delete();
              }

              if (mounted) {
                setState(() {
                  statusLog = '✅ Frame $frameId received';
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  statusLog = '❌ Error processing frame';
                });
              }
            }
          }
        });

    await mqttViewer!.connect();
  }

  Future<void> _loadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          currentImagePath = imagePath;
          currentImage = Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text('Error loading image', style: TextStyle(color: Colors.red)),
                  ],
                ),
              );
            },
          );
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading image: $e');
    }
  }

  @override
  void dispose() {
    mqttViewer?.disconnect();
    super.dispose();
  }

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
              const AppSidebar(currentKey: 'viewer'),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                              child: Icon(Icons.live_tv, color: theme.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Viewer',
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
                                      if (statusLog.contains('✅')) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: theme.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          statusLog,
                                          style: TextStyle(
                                            color: theme.white.withOpacity(.65),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Stats
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.surface.withOpacity(.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.white.withOpacity(.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image_outlined, color: theme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$totalFrames',
                                    style: TextStyle(
                                      color: theme.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'frames',
                                    style: TextStyle(
                                      color: theme.white.withOpacity(.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Video Player
                        Expanded(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.primary.withOpacity(.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primary.withOpacity(.15),
                                    blurRadius: 24,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  children: [
                                    // Top bar
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(.7),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: theme.white.withOpacity(.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: theme.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: theme.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Icon(Icons.person_outline, color: theme.white.withOpacity(.7), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.topic,
                                            style: TextStyle(
                                              color: theme.white.withOpacity(.7),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (currentImagePath != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: theme.surface.withOpacity(.5),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: theme.white.withOpacity(.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.movie_filter, color: theme.primary, size: 14),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Frame ${currentImagePath!.split('frame_').last.split('.').first}',
                                                    style: TextStyle(
                                                      color: theme.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Video display
                                    Expanded(
                                      child: Container(
                                        color: Colors.black,
                                        child: currentImage != null
                                            ? Center(child: currentImage!)
                                            : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(32),
                                                decoration: BoxDecoration(
                                                  color: theme.surface.withOpacity(.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.photo_library_outlined,
                                                  color: theme.white.withOpacity(.3),
                                                  size: 72,
                                                ),
                                              ),
                                              const SizedBox(height: 28),
                                              Text(
                                                'Waiting for stream...',
                                                style: TextStyle(
                                                  color: theme.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Listening on topic: ${widget.topic}',
                                                style: TextStyle(
                                                  color: theme.white.withOpacity(.4),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Bottom info bar
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(.7),
                                        border: Border(
                                          top: BorderSide(
                                            color: theme.white.withOpacity(.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: theme.white.withOpacity(.5), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Frames received: $totalFrames',
                                            style: TextStyle(
                                              color: theme.white.withOpacity(.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (receivedPackets.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.primary.withOpacity(.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${receivedPackets.length} in progress',
                                                style: TextStyle(
                                                  color: theme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }
}