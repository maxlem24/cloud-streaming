import 'dart:async';


import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttStreamer {
  /// Adresse du broker (ex: 127.0.0.1)
  final String broker;

  /// Port du broker (ex: 1883)
  final int port;

  /// Topic pour les segments fMP4
  final String topicSegments;

  /// Active/affiche les logs de debug de la lib mqtt_client
  final bool enableLogging;

  MqttServerClient? _client;
  bool _connected = false;

  // Streams exposées vers l'UI
  final _segmentsCtrl = StreamController<Uint8List>.broadcast();
  final _statusCtrl = StreamController<MqttConnectionState>.broadcast();

  /// Diffuse l'état de connexion
  Stream<MqttConnectionState> get status$ => _statusCtrl.stream;

  /// Diffuse les segments binaires (Uint8List)
  Stream<Uint8List> get segments$ => _segmentsCtrl.stream;

  bool get isConnected =>
      _connected &&
          (_client?.connectionStatus?.state == MqttConnectionState.connected);

  MqttStreamer({
    this.broker = '127.0.0.1',
    this.port = 1883,
    this.topicSegments = 'romain',
    this.enableLogging = false,  // Enable MQTT client logging for debugging
  });

  /// Connexion au broker et souscription aux topics par défaut
  Future<void> connect() async {
    final clientId = 'str2${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient(broker, clientId)
      ..port = port
      ..keepAlivePeriod = 60
      ..autoReconnect = true
      ..logging(on: enableLogging)
      ..secure = false
      ..useWebSocket = false
      ..connectTimeoutPeriod = 10000;

    final connMess =
    MqttConnectMessage().withClientIdentifier(clientId).startClean();
    client.connectionMessage = connMess;

    client.onConnected = () {
      debugPrint('✅ MQTT STREAMER CONNECTÉ - clientId=$clientId, broker=$broker:$port');
      _connected = true;
      _statusCtrl.add(MqttConnectionState.connected);
    };

    client.onDisconnected = () {
      debugPrint('❌ MQTT STREAMER DÉCONNECTÉ');
      _connected = false;
      _statusCtrl.add(MqttConnectionState.disconnected);
    };

    client.onSubscribed = (topic) {
      debugPrint('📡 STREAMER subscribed to: $topic');
    };

    client.onUnsubscribed = (topic) {
      debugPrint('📡 STREAMER unsubscribed from: $topic');
    };

    client.onAutoReconnect = () {
      debugPrint('🔁 Tentative d\'auto-reconnexion MQTT...');
      _statusCtrl.add(MqttConnectionState.faulted);
    };

    client.onAutoReconnected = () {
      debugPrint('✅ Auto-reconnect MQTT OK');
      _statusCtrl.add(MqttConnectionState.connected);
      // Re-souscrire aux topics par défaut après reconnexion
      _subscribeDefaults();
    };

    // Ecoute des messages
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>> events) {
      for (final event in events) {
        final recTopic = event.topic;
        final msg = event.payload;
        if (msg is MqttPublishMessage) {
          final data =
              msg.payload.message; // Uint8Buffer (implements List<int>)
          final bytes = Uint8List.fromList(data);

          if (recTopic == topicSegments) {
            _segmentsCtrl.add(bytes);
          } else {
            // Pour d'autres topics potentiels : no-op
          }
        }
      }
    });

    try {
      debugPrint('🔄 Connexion MQTT à $broker:$port ...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _client = client;
        _connected = true;
        debugPrint('✅ MQTT connecté (clientId=$clientId)');
        // Note: Streamer is for publishing only, no subscriptions needed
        // If you need to receive messages, call _subscribeDefaults() manually
      } else {
        throw Exception(
            'Échec de la connexion MQTT : état=${client.connectionStatus?.state}');
      }
    } catch (e) {
      // Nettoyage si erreur
      debugPrint('❌ Erreur MQTT: $e');
      try {
        client.disconnect();
      } catch (_) {}
      _connected = false;
      rethrow;
    }
  }

  /// Déconnexion propre
  Future<void> disconnect() async {
    try {
      _client?.disconnect();
      debugPrint('MQTT déconnecté');
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
    _connected = false;
    _statusCtrl.add(MqttConnectionState.disconnected);
  }

  /// Souscription aux topics par défaut (segments)
  void _subscribeDefaults() {
    if (_client == null) return;
    _subscribe(topicSegments);
  }

  /// Souscription à un topic générique
  void _subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    try {
      _client!.subscribe(topic, qos);
      debugPrint('Souscrit à "$topic" (QoS ${qos.index})');
    } catch (e) {
      debugPrint(' Erreur souscription "$topic" : $e');
    }
  }

  void publish(String topic, String data, {MqttQos qos = MqttQos.atLeastOnce, bool retain = false}) {

    if (_client == null) {
      debugPrint('❌ CLIENT NULL');
      return;
    }

    if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('❌ PAS CONNECTÉ: ${_client!.connectionStatus?.state}');
      return;
    }

    if (data.isEmpty) {
      debugPrint('❌ DATA VIDE');
      return;
    }

    try {

      final builder = MqttClientPayloadBuilder()..addString(data);

      debugPrint('🔨 Payload construit: ${builder.payload?.length} bytes');

      if (builder.payload == null) {
        debugPrint('❌ PAYLOAD NULL APRÈS CONSTRUCTION');
        return;
      }

      final msgId = _client!.publishMessage(
          topic,
          qos,
          builder.payload!,
          retain: retain
      );

      debugPrint('✅ PUBLISH RÉUSSI ! MessageId: $msgId');

    } catch (e, stack) {
      debugPrint('❌ EXCEPTION: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// À appeler lorsque le service n'est plus nécessaire
  Future<void> dispose() async {
    await disconnect();
    await _segmentsCtrl.close();
    await _statusCtrl.close();
  }
}