import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:cross_file/cross_file.dart';
import 'package:typed_data/typed_data.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:record/record.dart';

class StreamerPage extends StatefulWidget {
  const StreamerPage({Key? key}) : super(key: key);

  @override
  State<StreamerPage> createState() => _StreamerPageState();
}

class _StreamerPageState extends State<StreamerPage> {
  // Caméra
  int cameraId = -1;
  List<CameraDescription> cameras = [];
  CameraDescription? selectedCamera;

  // MQTT
  MqttServerClient? mqtt;
  bool mqttConnected = false;

  // Streaming vidéo
  bool isStreaming = false;
  String status = 'Prêt à démarrer';
  Timer? _captureTimer;
  int fps = 30;
  bool _isDisposing = false;
  bool _isCapturing = false;

  // Audio
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  StreamSubscription<Uint8List>? _audioStreamSub;
  bool audioEnabled = true;

  // Indicateur volume audio
  double currentVolume = 0.0;
  Timer? _volumeUpdateTimer;

  // Buffer audio et numéro de séquence
  final BytesBuilder _audioBuffer = BytesBuilder(copy: false);
  int _audioSequence = 0;
  static const int _targetAudioBytes = 640; // 20ms à 16kHz mono 16-bit = 640 bytes

  // ---- Config MQTT ----
  final String broker = '127.0.0.1';
  final int brokerPort = 1883;
  final String topicFrames = 'cam/1/frame';
  final String topicAudio = 'cam/1/audio';
  final int chunkSize = 1024;
  // ----------------------

  @override
  void initState() {
    super.initState();
    CameraPlatform.instance = CameraWindows();
    _initializeCameraList();
    _checkAudioPermissions();
  }

  Future<void> _checkAudioPermissions() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        debugPrint('✅ Permission audio OK');
      } else {
        debugPrint('⚠️ Permission audio refusée');
        audioEnabled = false;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur permission audio: $e');
      audioEnabled = false;
    }
  }

  Future<void> _initializeCameraList() async {
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (!mounted) return;
      if (cameras.isNotEmpty) {
        selectedCamera = cameras.first;
        setState(() => status = 'Caméra trouvée: ${selectedCamera!.name}');
      } else {
        setState(() => status = 'Aucune caméra trouvée');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => status = 'Erreur caméra: $e');
    }
  }

  Future<void> _createAndInitCamera() async {
    if (selectedCamera == null) {
      throw Exception('Aucune caméra disponible');
    }
    cameraId = await CameraPlatform.instance.createCamera(
      selectedCamera!,
      ResolutionPreset.medium,
    );
    await CameraPlatform.instance.initializeCamera(cameraId);
    debugPrint('✅ Caméra initialisée ID: $cameraId');
  }

  // ---------------- MQTT ----------------
  Future<void> _connectMqtt() async {
    final clientId = 'str${DateTime.now().millisecondsSinceEpoch}';

    mqtt = MqttServerClient(broker, clientId);
    mqtt!.port = brokerPort;
    mqtt!.keepAlivePeriod = 60;
    mqtt!.autoReconnect = false;
    mqtt!.logging(on: false);
    mqtt!.secure = false;
    mqtt!.useWebSocket = false;
    mqtt!.connectTimeoutPeriod = 10000;

    mqtt!.onConnected = () {
      debugPrint('✅ MQTT Connecté !');
      mqttConnected = true;
    };

    mqtt!.onDisconnected = () {
      debugPrint('❌ MQTT Déconnecté');
      mqttConnected = false;
    };

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    mqtt!.connectionMessage = connMess;

    try {
      debugPrint('🔄 Connexion MQTT à $broker:$brokerPort...');
      final status = await mqtt!.connect();

      if (mqtt!.connectionStatus?.state == MqttConnectionState.connected) {
        mqttConnected = true;
        debugPrint('✅ MQTT OK - Code: ${status?.returnCode}');
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        throw Exception('Échec connexion - ${status?.returnCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur MQTT: $e');
      try { mqtt?.disconnect(); } catch (_) {}
      mqttConnected = false;
      rethrow;
    }
  }

  Future<void> _disconnectMqtt() async {
    try {
      mqtt?.disconnect();
      debugPrint('MQTT déconnecté');
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
    mqttConnected = false;
  }

  void _publishFrame(Uint8List jpegBytes) async {
    if (!mqttConnected || mqtt == null) return;

    try {
      final totalSize = jpegBytes.length;
      final totalChunks = (totalSize / chunkSize).ceil();
      final frameId = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize > totalSize) ? totalSize : start + chunkSize;
        final chunk = jpegBytes.sublist(start, end);

        final header = '$frameId|$i|$totalChunks|';
        final headerBytes = Uint8List.fromList(header.codeUnits);

        final builder = MqttClientPayloadBuilder();
        final buffer = Uint8Buffer()
          ..addAll(headerBytes)
          ..addAll(chunk);
        builder.addBuffer(buffer);

        mqtt!.publishMessage(
          '$topicFrames/$frameId/$i',
          MqttQos.atMostOnce,
          builder.payload!,
        );

        if (i < totalChunks - 1) {
          await Future.delayed(const Duration(microseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur publish frame: $e');
    }
  }

  // ---------------- AUDIO (CORRIGÉ) ----------------
  Future<void> _startAudioCapture() async {
    if (!audioEnabled || _isRecording) return;

    try {
      // Configuration audio : PCM 16-bit, 16kHz, mono
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );

      final stream = await _audioRecorder.startStream(config);

      _isRecording = true;
      _audioSequence = 0;
      _audioBuffer.clear();
      debugPrint('🎤 Capture audio démarrée');

      _audioStreamSub = stream.listen(
            (audioData) {
          if (!mqttConnected || _isDisposing) return;

          // Calculer le volume
          _calculateVolume(audioData);

          // Ajouter au buffer
          _audioBuffer.add(audioData);

          // Envoyer des paquets de ~20ms (640 bytes)
          _flushAudioBuffer();
        },
        onError: (error) {
          debugPrint('❌ Erreur stream audio: $error');
        },
      );

      _volumeUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && _isRecording) {
          setState(() {});
        }
      });

    } catch (e) {
      debugPrint('❌ Erreur démarrage audio: $e');
      _isRecording = false;
    }
  }

  void _flushAudioBuffer() {
    final bytes = _audioBuffer.toBytes();

    // Envoyer par paquets de 640 bytes (20ms)
    int offset = 0;
    while (offset + _targetAudioBytes <= bytes.length) {
      final chunk = Uint8List.sublistView(bytes, offset, offset + _targetAudioBytes);
      _publishAudioPacket(chunk);
      offset += _targetAudioBytes;
    }

    // Garder le reste dans le buffer
    _audioBuffer.clear();
    if (offset < bytes.length) {
      _audioBuffer.add(Uint8List.sublistView(bytes, offset));
    }
  }

  void _publishAudioPacket(Uint8List pcmData) {
    if (!mqttConnected || mqtt == null) return;

    try {
      // Format attendu par le viewer : "AUD|pcm16|sr=16000|ch=1|seq=N|" + PCM data
      final header = 'AUD|pcm16|sr=16000|ch=1|seq=${_audioSequence}|';
      final headerBytes = Uint8List.fromList(header.codeUnits);

      final builder = MqttClientPayloadBuilder();
      final buffer = Uint8Buffer()
        ..addAll(headerBytes)
        ..addAll(pcmData);
      builder.addBuffer(buffer);

      mqtt!.publishMessage(
        topicAudio,
        MqttQos.atMostOnce,
        builder.payload!,
      );

      _audioSequence++;

      if (_audioSequence % 100 == 0) {
        debugPrint('🎤 Envoyé ${_audioSequence} paquets audio');
      }
    } catch (e) {
      debugPrint('❌ Erreur publish audio: $e');
    }
  }

  void _calculateVolume(Uint8List audioData) {
    if (audioData.length < 2) {
      currentVolume = 0.0;
      return;
    }

    double sum = 0.0;
    int sampleCount = audioData.length ~/ 2;

    for (int i = 0; i < audioData.length - 1; i += 2) {
      int sample = audioData[i] | (audioData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      double normalized = sample / 32768.0;
      sum += normalized * normalized;
    }

    double rms = sampleCount > 0 ? sqrt(sum / sampleCount) : 0.0;
    currentVolume = (rms * 3).clamp(0.0, 1.0);
  }

  Future<void> _stopAudioCapture() async {
    try {
      _volumeUpdateTimer?.cancel();
      _volumeUpdateTimer = null;

      await _audioStreamSub?.cancel();
      _audioStreamSub = null;
      await _audioRecorder.stop();
      _isRecording = false;
      currentVolume = 0.0;
      _audioBuffer.clear();
      debugPrint('🎤 Capture audio arrêtée (${_audioSequence} paquets envoyés)');
    } catch (e) {
      debugPrint('⚠️ Erreur arrêt audio: $e');
    }
  }

  // --------------------------------------

  Future<void> startStreaming() async {
    if (isStreaming) return;

    try {
      if (mounted) setState(() => status = 'Initialisation caméra...');
      await _createAndInitCamera();
      if (_isDisposing) return;

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) setState(() => status = 'Connexion MQTT...');
      await _connectMqtt();
      if (_isDisposing) return;

      if (audioEnabled) {
        if (mounted) setState(() => status = 'Démarrage audio...');
        await _startAudioCapture();
        if (_isDisposing) return;
      }

      final period = Duration(milliseconds: (1000 / fps).round());
      _captureTimer?.cancel();
      _captureTimer = Timer.periodic(period, (_) async {
        if (_isDisposing || !mounted || !mqttConnected) return;

        if (_isCapturing) return;
        _isCapturing = true;

        try {
          if (cameraId < 0) return;

          final XFile xfile = await CameraPlatform.instance.takePicture(cameraId);
          final bytes = await xfile.readAsBytes();

          _publishFrame(bytes);

          try {
            final file = File(xfile.path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('⚠️ Impossible de supprimer: ${xfile.path}');
          }
        } catch (e) {
          debugPrint('⚠️ Erreur capture: $e');
        } finally {
          _isCapturing = false;
        }
      });

      if (mounted) {
        setState(() {
          isStreaming = true;
          status = '🔴 Streaming actif @ ${fps}fps ${audioEnabled ? '🎤' : ''}';
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage: $e');
      if (mounted && !_isDisposing) {
        setState(() => status = 'Erreur: $e');
      }
      await stopStreaming();
    }
  }

  Future<void> stopStreaming({bool fromDispose = false}) async {
    try {
      _captureTimer?.cancel();
      _captureTimer = null;

      if (_isRecording) {
        await _stopAudioCapture();
      }

      if (mqttConnected) {
        await _disconnectMqtt();
      }

      if (cameraId >= 0) {
        try {
          await CameraPlatform.instance.dispose(cameraId);
        } catch (e) {
          debugPrint('Erreur dispose caméra: $e');
        }
        cameraId = -1;
      }
    } finally {
      if (!fromDispose && mounted) {
        setState(() {
          isStreaming = false;
          status = 'Streaming arrêté';
        });
      } else {
        isStreaming = false;
        status = 'Streaming arrêté';
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    stopStreaming(fromDispose: true);
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streamer MQTT'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStreaming ? Icons.videocam : Icons.videocam_off,
                size: 100,
                color: isStreaming ? Colors.red : Colors.grey,
              ),
              const SizedBox(height: 40),
              Text(
                status,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Broker: $broker:$brokerPort\nVidéo: $topicFrames\nAudio: $topicAudio',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    audioEnabled ? Icons.mic : Icons.mic_off,
                    color: audioEnabled ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: audioEnabled,
                    onChanged: isStreaming ? null : (value) {
                      setState(() => audioEnabled = value);
                    },
                    activeColor: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    audioEnabled ? 'Audio activé' : 'Audio désactivé',
                    style: TextStyle(
                      color: audioEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (isStreaming && audioEnabled && _isRecording) ...[
                const Text(
                  '🎤 Volume d\'entrée:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: currentVolume,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentVolume > 0.7 ? Colors.red :
                            currentVolume > 0.4 ? Colors.orange :
                            Colors.green,
                          ),
                          minHeight: 30,
                        ),
                        Center(
                          child: Text(
                            '${(currentVolume * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentVolume > 0.01 ? '🔊 Audio détecté' : '🔇 Silence',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentVolume > 0.01 ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                onPressed: isStreaming
                    ? () async => await stopStreaming()
                    : () async => await startStreaming(),
                icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isStreaming ? 'Arrêter le Stream' : 'Démarrer le Stream',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: isStreaming ? Colors.orange : Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}