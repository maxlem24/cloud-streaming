import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../services/app_mqtt_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/ui_atoms.dart';
import 'signature2.dart';

class LiveViewerPage extends StatefulWidget {
  final String videoId;

  const LiveViewerPage({
    super.key,
    required this.videoId,
  });

  static const String routeName = 'Live Viewer';
  static const String routePath = '/live_viewer';

  @override
  State<LiveViewerPage> createState() => _LiveViewerPageState();
}

class _LiveViewerPageState extends State<LiveViewerPage> {
  // MQTT
  final AppMqttService _mqtt = AppMqttService.instance;
  String? _bestEdgeId;
  String? _clientId;
  StreamSubscription? _messageSubscription;
  bool _isLoading = true;
  bool _isConnected = false;
  String _statusLog = 'Initializing...';

  // Frame reception - ✅ CHANGEMENT: Stocker des Lists de Strings
  final Map<int, List<String>> _framePackets = {}; // frameId -> [packet0, packet1, ...]
  int _totalFramesReceived = 0;
  int _totalPacketsReceived = 0;

  // Image display
  Image? _currentImage;
  int? _currentFrameId;

  // Signature verification
  String? _streamerPublicKey;

  @override
  void initState() {
    super.initState();
    _initViewer();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initViewer() async {
    setState(() {
      _isLoading = true;
      _statusLog = 'Connecting to MQTT...';
    });

    try {
      final auth = AuthService.instance;
      final token = auth.accessToken;
      _clientId = (auth.isLoggedIn && token != null && token.isNotEmpty)
          ? token
          : 'viewer_${DateTime.now().millisecondsSinceEpoch}';

      await _mqtt.initAndConnect();
      await _mqtt.refreshBestEdge();
      _bestEdgeId = _mqtt.bestEdgeId;

      if (_bestEdgeId == null || _bestEdgeId!.isEmpty) {
        throw Exception('No edge server available');
      }

      print("✅ Connected to edge: $_bestEdgeId");

      // Subscribe au topic
      final watchTopic = 'live/watch/$_bestEdgeId/${widget.videoId}';
      _mqtt.rawClient!.subscribe(watchTopic, MqttQos.atLeastOnce);

      // Envoyer une requête pour commencer à recevoir
      final requestMessage = jsonEncode({
        "video_id": widget.videoId,
        "client_id": _clientId,
        "action": "watch",
      });
      final builder = MqttClientPayloadBuilder()..addString(requestMessage);
      _mqtt.rawClient!.publishMessage(
        'live/watch/$_bestEdgeId',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print("📡 Subscribed to: $watchTopic");

      _setupMessageListener(watchTopic);

      setState(() {
        _isConnected = true;
        _isLoading = false;
        _statusLog = '✅ Connected - Waiting for stream...';
      });
    } catch (e) {
      debugPrint('❌ Error initializing viewer: $e');
      setState(() {
        _isLoading = false;
        _statusLog = '❌ Connection failed: $e';
      });
    }
  }

  void _setupMessageListener(String watchTopic) {
    _messageSubscription?.cancel();
    _messageSubscription = _mqtt.rawClient!.updates!.listen((events) {
      for (final evt in events) {
        if (evt.topic == watchTopic) {
          final msg = evt.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
          _handleMessage(payload);
        }
      }
    });
  }

  Future<void> _handleMessage(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Fin de stream
      if (data['end'] == 1) {
        print("🔴 Stream terminé");
        if (mounted) setState(() => _statusLog = '🔴 Stream ended');
        return;
      }

      // Métadonnées initiales
      if (data.containsKey('streamer_id') && data.containsKey('streamer_nom')) {
        _streamerPublicKey = data['streamer_id'] as String?;
        print("📺 Streamer: ${data['streamer_nom']}");
        if (mounted) {
          setState(() {
            _statusLog = '📺 Watching ${data['streamer_nom']}';
          });
        }
        return;
      }

      // ✅ VÉRIFICATION SIMPLIFIÉE : Seulement chunk et chunk_part
      if (!data.containsKey('chunk') || !data.containsKey('chunk_part')) {
        print("⚠️ Paquet incomplet ignoré (manque chunk ou chunk_part)");
        return;
      }

      final int frameId = (data['chunk_part'] as num).toInt();
      final String chunkData = data['chunk'] as String;

      // ✅ AFFICHAGE DEBUG
      print("=" * 80);
      print("📦 Message reçu:");
      print("   - chunk_part (frameId): $frameId");
      print("   - chunk (20 premiers chars): ${chunkData.substring(0, min(20, chunkData.length))}");
      print("   - chunk (longueur totale): ${chunkData.length} chars");


      _totalPacketsReceived++;

      // ✅ STOCKER LES PACKETS DANS UNE LISTE
      final packets = _framePackets.putIfAbsent(frameId, () => []);
      packets.add(chunkData);
      print("📊 Frame $frameId: ${packets.length}/8 packets reçus");

      if (mounted) {
        setState(() {
          _statusLog = 'Receiving frame $frameId: ${packets.length}/8';
        });
      }

      // ✅ Frame complet ?
      if (packets.length == 8) {
        print("✅ Frame $frameId COMPLET! Reconstruction...");
        await _processCompleteFrame(frameId);
      }
    } catch (e, st) {
      debugPrint('❌ Error handling message: $e\n$st');
      final preview = payload.length > 400 ? payload.substring(0, 400) + '…' : payload;
      debugPrint('Payload preview: $preview');
    }
  }

  Future<void> _processCompleteFrame(int frameId) async {
    try {
      print("🔄 Processing complete frame $frameId");

      final packets = _framePackets[frameId]!;

      // ✅ JOINDRE AVEC '\n' comme dans votre code fonctionnel
      final fullSignature = packets.join('\n');

      print("📝 Signature reconstituée:");
      print("   - Nombre de packets: ${packets.length}");
      print("   - Taille totale: ${fullSignature.length} caractères");
      print("   - Première ligne: ${fullSignature.split('\n').first.substring(0, min(80, fullSignature.split('\n').first.length))}");
      print("   - Nombre de lignes: ${fullSignature.split('\n').length}");

      // ✅ Créer le fichier signature
      final tempDir = Directory.systemTemp;
      final sigFile = File('${tempDir.path}/frame_$frameId.sig');
      await sigFile.writeAsString(fullSignature);

      print("💾 Signature sauvegardée: ${sigFile.path}");
      print("   - Fichier existe: ${await sigFile.exists()}");
      print("   - Taille fichier: ${await sigFile.length()} bytes");

      // ✅ Merger avec Signature.client_merge()
      print("🔐 Appel de client_merge...");
      final imagePath = await Signature.client_merge(sigFile.absolute.path);
      print("✅ Image mergée: $imagePath");

      // Vérifier l'image
      final imageFile = File(imagePath.trim());
      if (!await imageFile.exists()) {
        throw Exception("Image file not found: $imagePath");
      }

      final imageSize = await imageFile.length();
      print("📸 Image trouvée: $imageSize bytes");

      if (imageSize == 0) {
        throw Exception("Image file is empty!");
      }

      // Charger l'image
      await _loadImage(imagePath.trim(), frameId);

      // Nettoyer
      _framePackets.remove(frameId);
      _totalFramesReceived++;

      if (await sigFile.exists()) {
        await sigFile.delete();
      }

      if (mounted) {
        setState(() {
          _statusLog = '✅ Frame $frameId displayed';
        });
      }
    } catch (e, st) {
      debugPrint('❌ Error processing frame $frameId: $e\n$st');
      if (mounted) {
        setState(() {
          _statusLog = '⚠️ Error processing frame $frameId: $e';
        });
      }
    }
  }

  Future<void> _loadImage(String imagePath, int frameId) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print("❌ Image file doesn't exist: $imagePath");
        return;
      }

      final bytes = await file.readAsBytes();
      print("📸 Loading image: ${bytes.length} bytes");

      if (mounted) {
        setState(() {
          _currentFrameId = frameId;
          _currentImage = Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error displaying image: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error loading frame $frameId',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            },
          );
        });
        print("✅ Image affichée: Frame $frameId");
      }
    } catch (e) {
      debugPrint('❌ Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... votre build existant (pas de changement)
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
                  child: _isLoading
                      ? _buildLoadingState(theme)
                      : _buildViewerContent(theme),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 16),
          Text(
            _statusLog,
            style: TextStyle(
              color: theme.white.withOpacity(.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerContent(FlutterFlowTheme theme) {
    // ... votre UI existante (pas de changement nécessaire)
    return Padding(
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
                        if (_isConnected) ...[
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
                            _statusLog,
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
                      '$_totalFramesReceived',
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
                            Icon(Icons.video_library,
                                color: theme.white.withOpacity(.7),
                                size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.videoId,
                              style: TextStyle(
                                color: theme.white.withOpacity(.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (_currentFrameId != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
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
                                    Icon(Icons.movie_filter,
                                        color: theme.primary,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Frame $_currentFrameId',
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
                          child: _currentImage != null
                              ? Center(child: _currentImage!)
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
                                  'Video ID: ${widget.videoId}',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                            Icon(Icons.info_outline,
                                color: theme.white.withOpacity(.5),
                                size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Frames: $_totalFramesReceived | Packets: $_totalPacketsReceived',
                              style: TextStyle(
                                color: theme.white.withOpacity(.6),
                                fontSize: 12,
                              ),
                            ),
                            if (_framePackets.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primary.withOpacity(.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_framePackets.length} in progress',
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
    );
  }
}