import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

class ViewerPage extends StatefulWidget {
  const ViewerPage({Key? key}) : super(key: key);

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  // ---------- MQTT ----------
  MqttServerClient? mqtt;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;

  final TextEditingController hostController =
  TextEditingController(text: '127.0.0.1');
  final TextEditingController topicController =
  TextEditingController(text: 'cam/1/frame');
  final int mqttPort = 1883;

  bool isConnected = false;
  String status = 'Non connecté';
  bool _isDisposing = false;

  // ---------- VIDEO ----------
  Uint8List? currentFrame;
  int framesReceived = 0;
  final Map<int, Map<int, Uint8List>> _frameChunks = {};
  final Map<int, int> _frameTotalChunks = {};

  // ---------- AUDIO (mp_audio_stream) ----------
  final AudioStream _audio = getAudioStream();
  bool audioEnabled = true;
  bool _audioReady = false;

  // Format du flux réseau
  static const int _sr = 16000;     // 16 kHz
  static const int _ch = 1;         // mono
  static const int _pktMs = 20;     // 20 ms par paquet
  static const int _bytesPerMs = (_sr * _ch * 2) ~/ 1000; // 32 B/ms
  static const int _pktBytes = _pktMs * _bytesPerMs;      // 640 B
  static const int _pktSamples = _pktBytes ~/ 2;          // 320 échantillons

  // Jitter buffer indexé par seq -> Uint8List(640)
  final Map<int, Uint8List> _jitter = {};
  int _playSeq = -1;               // prochain seq à lire
  int _anchorSeq = -1;             // premier seq reçu
  final int _playoutDelayPkts = 3;

  // Horloge de lecture
  Timer? _playoutTimer;

  // Stats / UI
  int _packetsReceived = 0;
  int _packetsLost = 0;
  int _lastUiMs = 0;
  double receivedVolume = 0.0;
  double audioGain = 3.0;

  // Logs utiles
  bool _loggedFirstAudio = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Tampon interne du module (lecture) — on reste modeste pour faible latence
      // waitingBuffer ~120 ms : démarrage dès qu'on a ~120 ms en file
      _audio.init(
        bufferMilliSec: 80,         // était 120/300
        waitingBufferMilliSec: 40,  // était 60/120
        channels: _ch,
        sampleRate: _sr,
      );

      // Sur Web, resume() doit être appelé après interaction utilisateur.
      // On le rappellera aussi au clic "Se connecter" pour être sûr.
      _audio.resume();
      _audioReady = true;
      debugPrint('✅ mp_audio_stream prêt ($_sr Hz, $_ch ch)');
    } catch (e) {
      debugPrint('❌ Erreur init audio: $e');
      _audioReady = false;
    }
  }

  // ---------- Connexion MQTT ----------
  Future<void> _mqttConnectAndSubscribe() async {
    final broker = hostController.text.trim();
    final frameTopicBase = topicController.text.trim();

    if (broker.isEmpty || frameTopicBase.isEmpty) {
      throw Exception('Broker et topic requis');
    }

    // Topic audio dérivé automatiquement depuis le topic vidéo
    String audioTopic;
    if (frameTopicBase.endsWith('/frame')) {
      audioTopic = frameTopicBase.substring(0, frameTopicBase.length - '/frame'.length) + '/audio';
    } else {
      audioTopic = '$frameTopicBase/audio';
    }

    final clientId = 'vwr${DateTime.now().millisecondsSinceEpoch}';
    mqtt = MqttServerClient(broker, clientId)
      ..port = mqttPort
      ..keepAlivePeriod = 60
      ..autoReconnect = false
      ..logging(on: false)
      ..secure = false
      ..useWebSocket = false
      ..connectTimeoutPeriod = 10000;

    mqtt!.onConnected = () => debugPrint('✅ Viewer connecté');
    mqtt!.onDisconnected = () => debugPrint('❌ Viewer déconnecté');
    mqtt!.onSubscribed = (t) => debugPrint('📡 Abonné à: $t');

    mqtt!.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();

    try {
      debugPrint('🔌 MQTT -> $broker:$mqttPort');
      await mqtt!.connect();
      if (mqtt!.connectionStatus?.state != MqttConnectionState.connected) {
        throw Exception('Connexion échouée');
      }

      debugPrint('🧵 Subscribe vidéo: $frameTopicBase/#');
      mqtt!.subscribe('$frameTopicBase/#', MqttQos.atMostOnce);

      debugPrint('🎧 Subscribe audio: $audioTopic');
      mqtt!.subscribe(audioTopic, MqttQos.atMostOnce);

      await _updatesSub?.cancel();
      _updatesSub = mqtt!.updates!.listen((events) {
        if (_isDisposing || !mounted || events.isEmpty) return;

        for (final rec in events) {
          final topic = rec.topic;
          final msg = rec.payload as MqttPublishMessage;
          final raw = msg.payload.message;
          final bytes = Uint8List.fromList(raw);

          if (topic == audioTopic) {
            _processAudioPacket(bytes);
            continue;
          }
          if (topic.startsWith(frameTopicBase)) {
            _processVideoPacket(bytes);
          }
        }
      });

      // Redémarre/garantit le stream après interaction (utile Web)
      if (_audioReady) {
        _audio.resume();
      }

      // Démarre l'horloge de lecture audio (20 ms)
      _playoutTimer?.cancel();
      _playoutTimer =
          Timer.periodic(const Duration(milliseconds: _pktMs), (_) {
            if (audioEnabled && _audioReady) {
              _tickPlayout20ms();
            }
          });

      setState(() {
        isConnected = true;
        status = 'Connecté. Audio: $audioTopic';
      });
    } catch (e) {
      debugPrint('❌ Erreur viewer: $e');
      try {
        mqtt?.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  // ---------- VIDEO ----------
  void _processVideoPacket(Uint8List bytes) {
    try {
      final payloadStr = String.fromCharCodes(bytes);
      final parts = payloadStr.split('|');
      if (parts.length >= 4) {
        final frameId = int.parse(parts[0]);
        final chunkIndex = int.parse(parts[1]);
        final totalChunks = int.parse(parts[2]);

        final headerLen =
            parts[0].length + parts[1].length + parts[2].length + 3;
        final chunkData = bytes.sublist(headerLen);

        _frameChunks.putIfAbsent(frameId, () => {});
        _frameChunks[frameId]![chunkIndex] = chunkData;
        _frameTotalChunks[frameId] = totalChunks;

        if (_frameChunks[frameId]!.length == totalChunks) {
          final complete = <int>[];
          for (int i = 0; i < totalChunks; i++) {
            complete.addAll(_frameChunks[frameId]![i]!);
          }
          if (_isDisposing || !mounted) return;
          setState(() {
            currentFrame = Uint8List.fromList(complete);
            framesReceived++;
            _maybeUpdateUi();
          });

          _frameChunks.remove(frameId);
          _frameTotalChunks.remove(frameId);

          final now = DateTime.now().millisecondsSinceEpoch;
          _frameChunks.removeWhere((id, _) => now - id > 2000);
          _frameTotalChunks.removeWhere((id, _) => now - id > 2000);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur parsing vidéo: $e');
    }
  }

  // ---------- AUDIO : réception + jitter ----------
  void _processAudioPacket(Uint8List bytes) {
    if (!audioEnabled || !_audioReady) return;

    // En-tête: "AUD|pcm16|sr=16000|ch=1|seq=N|"
    int headerEnd = -1, bars = 0;
    for (int i = 0; i < bytes.length && i < 128; i++) {
      if (bytes[i] == 0x7C) { // '|'
        bars++;
        if (bars >= 5) { headerEnd = i; break; }
      }
    }
    if (headerEnd < 0) {
      if (!_loggedFirstAudio) {
        debugPrint('⚠️ Audio: en-tête introuvable (len=${bytes.length})');
      }
      return;
    }

    final header = String.fromCharCodes(bytes.sublist(0, headerEnd + 1));
    int seq = -1;
    for (final p in header.split('|')) {
      if (p.startsWith('seq=')) {
        seq = int.tryParse(p.substring(4)) ?? -1;
        break;
      }
    }
    if (seq < 0) {
      if (!_loggedFirstAudio) {
        debugPrint('⚠️ Audio: seq introuvable. header="$header"');
      }
      return;
    }

    // Payload PCM16 LE
    var payload = bytes.sublist(headerEnd + 1);

    // Tolérance de taille : tronque à 640, ou pad silence si trop court
    if (payload.length > _pktBytes) {
      payload = Uint8List.sublistView(payload, 0, _pktBytes);
    } else if (payload.length < _pktBytes) {
      final pad = Uint8List(_pktBytes);
      pad.setRange(0, payload.length, payload);
      payload = pad;
    }

    if (!_loggedFirstAudio) {
      _loggedFirstAudio = true;
      debugPrint('🎧 1er paquet audio: seq=$seq, payload=${payload.length} bytes');
    }

    // Premier ancrage avec délai (~120 ms)
    if (_anchorSeq < 0) {
      _anchorSeq = seq;
      _playSeq = _anchorSeq - _playoutDelayPkts; // 3 paquets ≈ 60 ms
    }

    _jitter[seq] = payload;
    _packetsReceived++;
    _maybeUpdateUi();
  }

  // ---------- AUDIO : horloge 20 ms -> push Float32 ----------
  final Stopwatch _clk = Stopwatch()..start();
  int _ticksSent = 0;
  // accumulateur 40 ms (2 * 20 ms)
  final int _accNeeded = _pktSamples * 2; // 640 échantillons float sur 16 kHz mono
  Float32List _accBuf = Float32List(640); // 40 ms
  int _accPos = 0;

  bool _prevWasSilence = true;
  bool _didSkipRecently = false;


  /// appelée par un timer 20 ms
  void _tickPlayout20ms() {
    if (_playSeq < 0) return;

    // Horloge précise 20 ms (limite la dérive)
    final int idealUs = _ticksSent * 20000;
    final int nowUs   = _clk.elapsedMicroseconds;
    final int skewUs  = nowUs - idealUs;
    if (skewUs < -2000) return; // en avance -> on attend le tick suivant

    // Fast-forward doux si on est trop en retard sur le dernier paquet reçu
    if (_jitter.isNotEmpty) {
      final int latest = _jitter.keys.reduce((a, b) => a > b ? a : b);
      final int backlogPkts = latest - _playSeq;
      const int maxBacklogPkts = 15; // ~300 ms
      if (backlogPkts > maxBacklogPkts) {
        _playSeq = latest - _playoutDelayPkts; // saute vers le présent
        _didSkipRecently = true;               // activer rampe à la prochaine non-silence
      }
    }
    bool _isAllZero(Uint8List b) {
      // 1) test rapide sur quelques positions
      for (int i = 0; i < b.length; i += 64) {
        if (b[i] != 0) return false;
      }
      // 2) si doute, scan complet mais court-circuit dès qu’on voit ≠ 0
      for (int i = 1; i < b.length; i++) {
        if (b[i] != 0) return false;
      }
      return true;
    }



    // Récupère 20 ms (ou silence si manquant)
    Uint8List bytes = _jitter.remove(_playSeq) ?? Uint8List(_pktBytes);
    if (bytes.length != _pktBytes) {
      final pad = Uint8List(_pktBytes);
      final n = bytes.length < _pktBytes ? bytes.length : _pktBytes;
      pad.setRange(0, n, bytes);
      bytes = pad;
    }
    final bool isSilence = _isAllZero(bytes);
    if (isSilence) _packetsLost++;

    // Converti en float32
    final Float32List f = _pcm16leToFloat32(bytes);

    // Applique gain (léger par défaut)
    _applyGainFloat(f, audioGain);

    // Rampe SEULEMENT si transition silence->son ou après skip
    if (!isSilence && (_prevWasSilence || _didSkipRecently)) {
      _applyEdgeRampFloat(f, rampMs: 1); // 1 ms suffit
      _didSkipRecently = false;
    }
    _prevWasSilence = isSilence;

    // Vu-mètre
    _calculateReceivedVolumeFloat(f);

    // Accumule en 40 ms : on pousse quand on a 2 trames de 20 ms
    final int need = _accNeeded - _accPos;
    if (f.length <= need) {
      _accBuf.setRange(_accPos, _accPos + f.length, f);
      _accPos += f.length;
    } else {
      // cas théorique (ne devrait pas arriver), on tronque
      _accBuf.setRange(_accPos, _accNeeded, f);
      _accPos = _accNeeded;
    }

    if (_accPos >= _accNeeded) {
      // Push 40 ms d’un coup → son plus propre
      _audio.push(_accBuf);
      _accPos = 0; // on réutilise le même buffer, pas d’allocation
    }

    _playSeq++;
    _ticksSent++;

    // ménage jitter : ne garde pas un passé trop ancien
    if (_jitter.length > 200) {
      final int cut = _playSeq - 50;
      _jitter.removeWhere((k, _) => k < cut);
    }

    _maybeUpdateUi();
  }



  // ---------- DSP helpers ----------
  Float32List _pcm16leToFloat32(Uint8List data) {
    final bd = data.buffer.asByteData();
    final out = Float32List(_pktSamples);
    for (int i = 0, j = 0; i < data.length; i += 2, j++) {
      int s = bd.getInt16(i, Endian.little);
      out[j] = (s >= 0 ? s / 32767.0 : s / 32768.0);
    }
    return out;
  }

  void _applyGainFloat(Float32List samples, double gain) {
    if (gain == 1.0) return;
    for (int i = 0; i < samples.length; i++) {
      double v = samples[i] * gain;
      // clamp
      if (v > 1.0) v = 1.0;
      if (v < -1.0) v = -1.0;
      samples[i] = v;
    }
  }

  void _applyEdgeRampFloat(Float32List samples, {int rampMs = 1}) {
    final ramp = (rampMs * _sr) ~/ 1000;
    if (ramp <= 0 || samples.length <= ramp * 2) return;
    final n = samples.length;
    for (int i = 0; i < ramp; i++) {
      final w = i / ramp;
      samples[i] *= w;
      samples[n - 1 - i] *= w;
    }
  }

  void _calculateReceivedVolumeFloat(Float32List samples) {
    if (samples.isEmpty) { receivedVolume = 0.0; return; }
    double sum = 0.0;
    for (int i = 0; i < samples.length; i++) {
      final v = samples[i];
      sum += v * v;
    }
    final rms = sqrt(sum / samples.length);
    receivedVolume = rms.clamp(0.0, 1.0);
  }

  // ---------- UI helpers ----------
  void _maybeUpdateUi() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUiMs >= 250 && mounted) {
      _lastUiMs = now;
      final lossRate = (_packetsReceived + _packetsLost) > 0
          ? (100.0 * _packetsLost / (_packetsReceived + _packetsLost))
          : 0.0;
      status =
      '📹 $framesReceived frames | 🎤 loss ${lossRate.toStringAsFixed(1)}% | gain ${audioGain.toStringAsFixed(1)}x';
      setState(() {});
    }
  }

  void _disconnect() async {
    _playoutTimer?.cancel();
    _playoutTimer = null;

    await _updatesSub?.cancel();
    _updatesSub = null;

    _frameChunks.clear();
    _frameTotalChunks.clear();

    _jitter.clear();
    _playSeq = -1;
    _anchorSeq = -1;
    _packetsReceived = 0;
    _packetsLost = 0;
    receivedVolume = 0.0;

    try { mqtt?.disconnect(); } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposing = true;
    _disconnect();
    // Arrêt audio
    if (_audioReady) {
      try {
        _audio.uninit();
      } catch (_) {}
    }
    hostController.dispose();
    topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioOk = audioEnabled && _audioReady;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewer MQTT'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(isConnected ? Icons.cast_connected : Icons.cast,
                size: 80, color: isConnected ? Colors.green : Colors.grey),
            const SizedBox(width: 20),
            Icon(audioOk ? Icons.volume_up : Icons.volume_off,
                size: 60, color: audioOk ? Colors.blue : Colors.grey),
          ]),
          const SizedBox(height: 20),

          if (!isConnected) ...[
            SizedBox(
                width: 320,
                child: TextField(
                    controller: hostController,
                    decoration: const InputDecoration(
                        labelText: 'Adresse du broker MQTT',
                        border: OutlineInputBorder(),
                        hintText: '127.0.0.1'))),
            const SizedBox(height: 10),
            SizedBox(
                width: 320,
                child: TextField(
                    controller: topicController,
                    decoration: const InputDecoration(
                        labelText: 'Topic des frames',
                        border: OutlineInputBorder(),
                        hintText: 'cam/1/frame'))),
            const SizedBox(height: 20),
          ],

          if (isConnected) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Audio: '),
              Switch(
                value: audioEnabled,
                onChanged: _audioReady
                    ? (v) {
                  setState(() {
                    audioEnabled = v;
                    if (!v) {
                      _jitter.clear();
                      _playSeq = -1;
                      _anchorSeq = -1;
                      receivedVolume = 0.0;
                    } else {
                      _audio.resume(); // utile Web
                    }
                  });
                }
                    : null,
                activeColor: Colors.blue,
              ),
            ]),
            const SizedBox(height: 8),

            const Text('🎚️ Gain audio'),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('1x', style: TextStyle(fontSize: 12)),
              Slider(
                value: audioGain,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                label:
                '${audioGain.toStringAsFixed(1)}x (~${(20 * log(audioGain) / ln10).toStringAsFixed(1)} dB)',
                onChanged: (v) => setState(() => audioGain = v),
                activeColor: Colors.blue,
              ),
              const Text('10x', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 8),
          ],

          Text(status,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),

          Container(
            width: 640,
            height: 480,
            decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey, width: 2)),
            child: currentFrame != null
                ? Image.memory(currentFrame!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Center(
                    child: Text('Erreur affichage',
                        style: TextStyle(color: Colors.white))))
                : const Center(
                child: Text('En attente du flux vidéo...',
                    style: TextStyle(color: Colors.white))),
          ),
          const SizedBox(height: 20),

          if (isConnected && audioEnabled) ...[
            const Text('🔊 Volume reçu'),
            const SizedBox(height: 6),
            SizedBox(
                width: 300,
                height: 20,
                child: LinearProgressIndicator(
                    value: receivedVolume,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        receivedVolume > 0.01 ? Colors.green : Colors.grey))),
            const SizedBox(height: 12),
          ],

          ElevatedButton.icon(
            onPressed: isConnected
                ? () {
              _disconnect();
              if (mounted) {
                setState(() {
                  isConnected = false;
                  currentFrame = null;
                  framesReceived = 0;
                  status = 'Déconnecté';
                });
              }
            }
                : () async {
              if (mounted) setState(() => status = 'Connexion MQTT...');
              try {
                await _mqttConnectAndSubscribe();
              } catch (e) {
                if (mounted) {
                  setState(() {
                    isConnected = false;
                    status = 'Erreur MQTT: $e';
                  });
                }
              }
            },
            icon: Icon(isConnected ? Icons.stop : Icons.play_arrow),
            label: Text(isConnected ? 'Se déconnecter' : 'Se connecter',
                style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: isConnected ? Colors.orange : Colors.green,
                foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }
}
