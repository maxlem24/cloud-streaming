import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:twinsa/features/HomePage2/catalogue_page.dart';


import '../../flutter_flow/flutter_flow_theme.dart';
import '../../services/app_mqtt_service.dart';
import '../../services/auth_service.dart';

import '../../widgets/app_sidebar.dart';
import '../../widgets/ui_atoms.dart';
import 'Camera.dart';
import 'MQTT_streamer.dart';
import 'signature2.dart';


class GoLive extends StatefulWidget {
  const GoLive({super.key});
  static const String routeName = 'Go Live';
  static const String routePath = '/go_live';

  @override
  State<GoLive> createState() => _StreamerPageState();
}

class _StreamerPageState extends State<GoLive> {
// --- Camera
  final CameraService camera = CameraService.instance;
  final int fps = 1;
  int frameId = 1;
  bool _isCameraReady = false;
  bool _isStreaming = false;
  String? _errorMessage;

  // --- MQTT streamer
  late MqttStreamer streamer;
  Timer? _tick;
  //=========================================================================
  //===== VERSION PROPRE ABLA =====
  //=========================================================================

  //Connexion MQTT
  final AppMqttService _mqtt = AppMqttService.instance;
  bool _isLoading = false;

  //Edges
  String? _bestEdgeId;

  final random = Random();
  String videoId = "";

  final auth = AuthService.instance;
  late String? ownerId = auth.accessToken;
  String ownerBase64ID = '';


  @override
  void initState() {
    videoId = random.nextInt(10001).toString();
    super.initState();
    _initMqtt();

    initializeCamera();
    print("================ FIN INITIALISATION CONNEXION ET CAMERA =================");
  }

  @override
  void dispose() {
    _tick?.cancel();

    if (_isStreaming) {
      String message = CreateFinalMessage(videoId); // ✅ CORRECTION
      final builder = MqttClientPayloadBuilder()..addString(message);
      _mqtt.rawClient?.publishMessage('live/upload/$_bestEdgeId', MqttQos.atLeastOnce, builder.payload!);
    }

    camera.dispose();
    super.dispose();
  }

  Future<void> _initMqtt() async {
    setState(() => _isLoading = true);
    try {
      print("CONNEXION ET RECHERCHE EDGE...");
      await _mqtt.initAndConnect();
      await _mqtt.refreshBestEdge();
      _bestEdgeId= _mqtt.bestEdgeId;

      print("CONNEXION RÉUSSIE ET EDGE TROUVÉ: $_bestEdgeId");

    } catch (e) {
      debugPrint('Erreur init MQTT: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initOwnerId() async {
    if (ownerBase64ID.isNotEmpty) return;

    String init_message = CreateInitMessage(ownerId: ownerId!);
    final builder = MqttClientPayloadBuilder()..addString(init_message);

    print("======= AVANT OWNERID ===========");

    String base64_topic = "auth/user/${auth.sub}";

    _mqtt!.rawClient?.subscribe(base64_topic, MqttQos.atLeastOnce);
    _mqtt!.rawClient?.publishMessage("auth/user", MqttQos.atLeastOnce, builder.payload!);

    print("======= APRES OWNERID ===========");

    // Créer un Completer pour attendre la réponse
    final completer = Completer<void>();
    late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? sub;

    sub = _mqtt!.rawClient?.updates!.listen((events) {
      for (final evt in events) {
        final topic = evt.topic;
        final msg = evt.payload;
        if (msg is! MqttPublishMessage) continue;

        final payload =
        MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        debugPrint('RECV topic="$topic" payload="$payload"');

        if (topic == base64_topic) {
          try {
            final decoded = jsonDecode(payload);
            debugPrint('🧾 Payload JSON: $decoded');
            ownerBase64ID = decoded["ownerbase64"];
            print(ownerBase64ID);

            // Annuler la subscription et compléter le Future
            sub?.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint('Erreur parsing payload: $e');
            sub?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        }
      }
    });

    // Attendre la réception du message (avec timeout optionnel)
    try {
      await completer.future.timeout(
        Duration(seconds: 20),
        onTimeout: () {
          sub?.cancel();
          throw TimeoutException('Timeout waiting for base64');
        },
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'attente du base64: $e');
      rethrow;
    }

    print("======= BASE64 REÇU ===========");
  }


  String CreateInitMessage({
    required String ownerId,

  }) {

    String message = jsonEncode( {
      "ownerId":      ownerId,         // message_json["video_id"]
    });
    return message;
  }

  String CreateStartMessage({
    required String streamerName,
    required String videoId,
  }) {

    final auth = AuthService.instance;
    final token = auth.accessToken;
    String message = jsonEncode( {
      "video_id":      videoId,         // message_json["video_id"]
      "end":          0,       // message_json["end"]
      "streamer_nom": streamerName,        // message_json["streamer_nom"]
      "category":     "live",      // message_json["category"]
      "description":  "Live de $streamerName sur Twinsa",   // message_json["description"]
      "thumbnail":    012456,     // message_json["thumbnail"]
      "video_nom":     "Live de $streamerName sur Twinsa",         // message_json["video_nom"]
      "streamer_id":   token,   // message_json["streamer_id"]
    });
    return message;
  }

  String CreateMessage({
    required int frameId,
    required String data,
    int? packetIndex,
    int? totalPackets,
    String? videoId,
  }) {
    return jsonEncode({
      "video_id": videoId,
      "end": 0,
      "chunk_part": frameId,
      "chunk": data,
      if (packetIndex != null) "packet_index": packetIndex,
      if (totalPackets != null) "total_packets": totalPackets,
    });
  }

  String CreateFinalMessage(String? videoId) {

    String message = jsonEncode({
      "video_id":      videoId,
      "end":          1,
    });
    print(message);
    return message;
  }




  Future<void> initializeCamera() async {

    try {

      // Initialize camera
      try {
        await camera.initialize();
      } catch (e) {
        setState(() {
          _errorMessage = 'Camera error: ${e.toString()}';
        });
        debugPrint('🔴 Camera initialization error: $e');
        return;
      }

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

  Future <void> startStreaming() async {
    await _initOwnerId();
    await Signature.owner_init(ownerId!, ownerBase64ID);

    if (_bestEdgeId == null || _bestEdgeId!.isEmpty) {
      print("❌ Pas d'edge disponible");
      setState(() {
        _errorMessage = "No edge server available";
      });
      return;

    }

    if (!_mqtt.isConnected ) {
      print("❌ MQTT non connecté");
      setState(() {
        _errorMessage = "MQTT not connected";
      });
      return;

    }

    if (_mqtt.rawClient == null) {
      print("❌ MQTT non connecté");
      setState(() {
        _errorMessage = "RAW CLIENT not connected";
      });
      return;
    }

    await _mqtt.refreshBestEdge();
    setState(() {
      _isStreaming = true;
    });

    String user = auth.userUsername ?? 'Unknown Streamer';

    // ENVOIE PREMIER MESSAGE
    String init_message = CreateStartMessage( streamerName: user, videoId: videoId);
    final builder = MqttClientPayloadBuilder()..addString(init_message);
    if (_mqtt.isConnected){
      print ("MQTT connecté");
    };
    if (_mqtt.rawClient?.connectionState != null){
    print ("MQTT IS NULL");
    };
    _mqtt.rawClient!.publishMessage('live/upload/$_bestEdgeId', MqttQos.atLeastOnce, builder.payload!);

    print("============ PREMIER MESSAGE ENVOYE ============");

    await Future.delayed(Duration(seconds: 2));



    _tick = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (timer) async {
      if (!mounted || !_isStreaming) {
        timer.cancel();
        return;
      }

      try {
        final file = await camera.takePicture();
        print("Picture taken: ${file.path}, size: ${await file.length()} bytes");
        List<String> sigs = await Signature.owner_sign(file.path, frameId.toString());
        //print(sigs);

        for (int i = 0; i < sigs.length; i++) {
          var sig = sigs[i].trim();
          print (sig);


          String message = CreateMessage(
              frameId: frameId,
              data: sig,
              packetIndex: i,  // Optionnel : pour tracer quel paquet de la série
              totalPackets: sigs.length, // Optionnel : pour savoir combien de paquets au total
              videoId: videoId,
          );

          final builder = MqttClientPayloadBuilder()..addString(message);
          _mqtt.rawClient!.publishMessage(
              'live/upload/$_bestEdgeId',
              MqttQos.atLeastOnce,
              builder.payload!
          );
        }

        ++frameId;

        // Clean up
        try {
          final toDel = File(file.path);
          if (await toDel.exists()) {
            await toDel.delete();
          }
        } catch (_) {}
      } catch (e) {
        debugPrint('❌ Error capturing/sending frame: $e');
      }
    });
  }

  Future<void> stopStreaming() async {
    String message = CreateFinalMessage(videoId);
    final builder = MqttClientPayloadBuilder()..addString(message);
    _mqtt.rawClient!.publishMessage('live/upload/$_bestEdgeId', MqttQos.atLeastOnce, builder.payload!);

    setState(() {
      _isStreaming = false;
    });
    _tick?.cancel();
    _tick = null;
    await Future.delayed(const Duration(seconds: 2));
    _mqtt.disconnect();
  }

  Future<void> endStream() async {
    stopStreaming();
    if (mounted) {
      _mqtt.disconnect();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CataloguePage(),
        ),
      ); // catalogue
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
                                ? buildErrorState(theme)
                                : !_isCameraReady
                                ? buildLoadingState(theme)
                                : !_isStreaming
                                ? buildGoLiveButton(theme)
                                : buildLivePreview(theme),
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

  Widget buildErrorState(FlutterFlowTheme theme) {
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
            initializeCamera();
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

  Widget buildLoadingState(FlutterFlowTheme theme) {
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

  Widget buildGoLiveButton(FlutterFlowTheme theme) {
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
          onPressed: () async {
            await Future.delayed(Duration(seconds: 2));
            startStreaming();
          },
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

  Widget buildLivePreview(FlutterFlowTheme theme) {
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
                            camera.dispose();
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