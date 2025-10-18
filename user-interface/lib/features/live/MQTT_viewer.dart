import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

class MQTTViewer {
  final String broker;
  final int port;
  final String topicBase;
  void Function(String topic, String payload)? onMessage; //TODO : j ai change
  final void Function()? onConnected;
  final void Function()? onDisconnected;
  final void Function(String topic)? onSubscribed;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  MQTTViewer({
    required this.broker,
    required this.topicBase,
    this.port = 1883,
    this.onMessage,
    this.onConnected,
    this.onDisconnected,
    this.onSubscribed,
  });

  Future<void> connect() async {
    debugPrint('🔌 Initialisation MQTTViewer vers $broker:$port ...');

    final clientId = 'viewer_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(broker, clientId)
      ..port = port
      ..keepAlivePeriod = 60
      ..logging(on: false)
      ..secure = false
      ..useWebSocket = false
      ..autoReconnect = false
      ..onConnected = () {
        debugPrint('✅ MQTTViewer connecté à $broker:$port');
        onConnected?.call();
      }
      ..onDisconnected = () {
        debugPrint('❌ MQTTViewer déconnecté');
        onDisconnected?.call();
      }
      ..onSubscribed = (t) {
        debugPrint('📡 MQTTViewer abonné à $t');
        onSubscribed?.call(t);
      };

    _client!.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();

    try {
      debugPrint('🔌 Connexion MQTTViewer → $broker:$port ...');

      await _client!.connect();

      // Set up message listener BEFORE connecting to avoid missing messages
      _subscription = _client!.updates!.listen((events) {
        for (final rec in events) {
          final msg = rec.payload as MqttPublishMessage;
          final raw = MqttPublishPayload.bytesToStringAsString(msg.payload.message);// TODO : j ai change
          final bytes = jsonDecode(raw); // TODO j ai change
          debugPrint(
              '📥 Message MQTT reçu sur ${rec.topic} (${bytes.length} octets)');
          onMessage?.call(rec.topic, bytes);
        }
      });

      if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
        throw Exception('Connexion MQTT échouée');
      }

      // Topics
      //   _client!.subscribe('$topicBase/#', MqttQos.atLeastOnce);
      //   _client!.subscribe('$topicBase/+', MqttQos.atLeastOnce);
      _client!.subscribe(topicBase, MqttQos.atLeastOnce);
      //_client!.subscribe("#", MqttQos.atLeastOnce);
    } catch (e) {
      debugPrint('❌ Erreur connexion MQTTViewer: $e');
      try {
        _client?.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  /// Déconnexion propre
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      _client?.disconnect();
      debugPrint('🚪 MQTTViewer déconnecté proprement');
    } catch (e) {
      debugPrint('⚠️ Erreur déconnexion MQTTViewer: $e');
    }
  }

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;
}
