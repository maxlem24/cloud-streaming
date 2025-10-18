import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';


import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../services/app_mqtt_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/ui_atoms.dart';
import 'Camera.dart';
import 'MQTT_streamer.dart';
import 'signature2.dart';


class GoLive extends StatefulWidget {
  final String broker;
  final int port;
  final String topic;
  final VideoItem? video;

  const GoLive({
    Key? key,
    required this.broker,
    required this.port,
    required this.topic,
    this.video,
  }) : super(key: key);

  static const String routeName = 'Go Live';
  static const String routePath = '/go_live';

  @override
  State<GoLive> createState() => _StreamerPageState();
}

class _StreamerPageState extends State<GoLive> {
  final String ownerId = "romain";
  final String ownerBase64ID =
      "hk9jyUPHu0Hjv/fgjXl01+bw3cy3VfhJSB3TPoNSXWWjb8VKrHmkIUPc7+kgwfIpD2J8YICf345a6VrVb7ytQVeE89ajycnLmBxjwqTFc/w1gcZDapXTWipVWp+tnUoXIPwTpyzd0eqzp09KNEumLojDPcfa4L4u7MDs32BwGSE=:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ2zDqW1lbnQgZXQgTWF4aW1lIMOgIDJoIGRlIG1hdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  // --- Camera
  final CameraService camera = CameraService.instance;
  final int fps = 5;
  int frameId = 0;
  bool _isCameraReady = false;
  bool _isStreaming = false;
  String? _errorMessage;

  // --- MQTT streamer
  late MqttStreamer streamer;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  @override
  void dispose() {
    _tick?.cancel();
    camera.dispose();
    streamer.dispose();
    super.dispose();
  }

  String CreateStartMessage({
    required VideoItem video,
    required String streamerName,
  }) {

    final auth = AuthService.instance;
    final token = auth.accessToken;
    String message = jsonEncode( {
      "live_id":      123,         // message_json["video_id"]
      "end":          0,       // message_json["end"]
      "streamer_nom": streamerName,        // message_json["streamer_nom"]
      "category":     video.category,      // message_json["category"]
      "description":  "Live de "+streamerName+" sur Twinsa",   // message_json["description"]
      "thumbnail":    012456,     // message_json["thumbnail"]
      "live_nom":     "Live de "+streamerName+" sur Twinsa",         // message_json["video_nom"]
      "streamer_id":   token,   // message_json["streamer_id"]
    });
    return message;
  }

  String CreateMessage({
    required String categorie,
    required String streamerName,
    required int frameId,
    required String data,
  }) {

    final auth = AuthService.instance;
    final token = auth.accessToken;
    final String StreamerName = auth.userUsername ?? "Unknown streamer";
    String message = jsonEncode({
      "live_id":      123,           // message_json["video_id"]
      "end":          0,       // message_json["end"]
      "streamer_nom": streamerName,        // message_json["streamer_nom"]
      "category":     "live",
      "chunk": data,
      "chunk_part": frameId,// message_json["category"]
      "description":  "Live de "+StreamerName+" sur Twinsa",   // message_json["description"]
      "thumbnail":    012456,     // message_json["thumbnail"]
      "live_nom":     "Live de "+StreamerName+" sur Twinsa",         // message_json["video_nom"]
      "streamer_id":   token,   // message_json["streamer_id"]
    });
    return message;
  }

  String CreateFinalMessage({
    required String categorie,
    required String streamerName,
    required int frameId,
    required String data,
  }) {

    final auth = AuthService.instance;
    final token = auth.accessToken;
    final String StreamerName = auth.userUsername ?? "Unknown streamer";

    String message = jsonEncode({
      "categorie": categorie,
      "live_id":      123,           // message_json["video_id"]
      "end":          0,       // message_json["end"]
      "streamer_nom": streamerName,        // message_json["streamer_nom"]
      "category":     "live",
      "chunk": data,
      "chunk_part": frameId,// message_json["category"]
      "description":  "Live de "+StreamerName+" sur Twinsa",   // message_json["description"]
      "thumbnail":    012456,     // message_json["thumbnail"]
      "live_nom":     "Live de "+StreamerName+" sur Twinsa",         // message_json["video_nom"]
      "streamer_id":   token,

    });
    return message;
  }




  Future<void> _initializeConnection() async {

    try {
      // Initialize MQTT streamer with dynamic parameters
      streamer = MqttStreamer(
        broker: widget.broker,
        port: widget.port,
        topicSegments: widget.topic,
      );

      await streamer.connect();

      if (!streamer.isConnected) {
        setState(() {
          _errorMessage = 'Failed to connect to MQTT broker';
        });
        return;
      }

      VideoItem v = VideoItem(id: '0', title: 'title', description: 'description', category: 'category', live: true, edges: 'edges', thumbnail: 'thumbnail', streamerId: 'streamerId', createdAt: null);


      VideoItem video = widget.video ?? v;
      final auth = AuthService.instance;
      final String streamerName = auth.userUsername ?? "Unknown streamer";

      String init_message = CreateStartMessage(video : video , streamerName: streamerName );

      streamer.publish(
        widget.topic,
        init_message,
        qos: MqttQos.atLeastOnce,
        retain: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Initialize camera
      try {
        await camera.initialize();
      } catch (e) {
        setState(() {
          _errorMessage = 'No camera available on this device';
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isCameraReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: ${e.toString()}';
      });
    }
  }




  void startStreaming() {
    if (!_isCameraReady) {
      return;
    }

    setState(() {
      _isStreaming = true;
    });





    _tick = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (timer) async {
      if (!mounted || !_isStreaming) {
        timer.cancel();
        return;
      }

      try {
        final file = await camera.takePicture();
        List<String> sigs = await Signature.owner_sign(file.path);

        final auth = AuthService.instance;
        final String streamerName = auth.userUsername ?? "Unknown streamer";


        for (var sig in sigs) {
          final appended_sig = '$frameId::$sig';

          String data = CreateMessage(categorie: "live", streamerName: streamerName, frameId: frameId, data: sig);

          streamer.publish(
            widget.topic,
            data,
            qos: MqttQos.atLeastOnce,
            retain: false,
          );
        }

        ++frameId;

        // Clean up
        try {
          final to_del = File(file.path);
          if (await to_del.exists()) {
            await to_del.delete();
          }
        } catch (_) {}
      } catch (e) {
        debugPrint('❌ Error capturing/sending frame: $e');
      }
    });
  }

  void stopStreaming() {
    setState(() {
      _isStreaming = false;
    });
    _tick?.cancel();
    _tick = null;
  }

  Future<void> endStream() async {
    stopStreaming();
    await camera.dispose();
    await streamer.dispose();

    if (mounted) {
      Navigator.of(context).pop();
    }
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
              const AppSidebar(currentKey: 'go_live'),
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
                                    'Go Live',
                                    style: TextStyle(
                                      color: theme.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isStreaming
                                        ? 'Streaming now'
                                        : _isCameraReady
                                        ? 'Ready to stream'
                                        : 'Initializing...',
                                    style: TextStyle(
                                      color: theme.white.withOpacity(.65),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Content
                        Expanded(
                          child: Center(
                            child: _errorMessage != null
                                ? _buildErrorState(theme)
                                : !_isCameraReady
                                ? _buildLoadingState(theme)
                                : !_isStreaming
                                ? _buildGoLiveButton(theme)
                                : _buildLivePreview(theme),
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

  Widget _buildErrorState(FlutterFlowTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.surface.withOpacity(.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.red.withOpacity(.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.error_outline,
            size: 80,
            color: theme.red,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Camera Error',
          style: TextStyle(
            color: theme.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: theme.white.withOpacity(.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _errorMessage = null;
              _isCameraReady = false;
            });
            _initializeConnection();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, size: 20),
              const SizedBox(width: 8),
              Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: theme.primary),
        const SizedBox(height: 16),
        Text(
          'Initializing camera...',
          style: TextStyle(
            color: theme.white.withOpacity(.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGoLiveButton(FlutterFlowTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.surface.withOpacity(.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.red.withOpacity(.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.videocam,
            size: 80,
            color: theme.red,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Ready to go live?',
          style: TextStyle(
            color: theme.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start streaming to your audience',
          style: TextStyle(
            color: theme.white.withOpacity(.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: startStreaming,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.red,
            foregroundColor: theme.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_filled, size: 24),
              const SizedBox(width: 12),
              Text(
                'Start Streaming',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview(FlutterFlowTheme theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.red.withOpacity(.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.red.withOpacity(.2),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Camera preview
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: camera.buildPreview(),
            ),

            // Live badge overlay
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: theme.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // End Stream button
            Positioned(
              top: 20,
              right: 20,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.surface,
                      title: Text(
                        'End Stream?',
                        style: TextStyle(color: theme.white),
                      ),
                      content: Text(
                        'This will stop the stream and return to the previous page.',
                        style: TextStyle(color: theme.white.withOpacity(.7)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: theme.white.withOpacity(.7)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            endStream();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.red,
                            foregroundColor: theme.white,
                          ),
                          child: const Text('End Stream'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.red.withOpacity(.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop_circle, color: theme.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'End Stream',
                        style: TextStyle(
                          color: theme.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }
}