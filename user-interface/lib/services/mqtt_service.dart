import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String host;
  final int port;
  final String clientId;
  final bool log;

  late final MqttServerClient _client;
  bool _isConnected = false;

  MqttService({
    required this.host,
    this.port = 1883,
    required this.clientId,
    this.log = false,
  }) {
    _client = MqttServerClient(host, clientId);
    _client.port = port;
    _client.logging(on: log);
    _client.keepAlivePeriod = 150000;
    _client.secure = false;
    _client.setProtocolV311();
    _client.connectTimeoutPeriod = 15000;

    // Callbacks
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.onUnsubscribed = _onUnsubscribed;
    _client.onSubscribeFail = _onSubscribeFail;
    _client.pongCallback = _pong;
  }

  bool get isConnected => _isConnected;
  MqttServerClient get rawClient => _client;

  Future<void> connect() async {

    try {
      final status = await _client.connect();
      if (status?.state != MqttConnectionState.connected) {
        throw Exception('MQTT connect failed: ${status?.state}');
      }
    } on NoConnectionException {
      _client.disconnect();
      rethrow;
    } catch (_) {
      _client.disconnect();
      rethrow;
    }
  }

  /// Subscribe to a topic and stream String payloads (UTF-8).
  Stream<String> subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (!_isConnected) {
      throw StateError('Not connected. Call connect() first.');
    }
    _client.subscribe(topic, qos);
    return _client.updates!
        .where((c) => c.isNotEmpty)
        .map((c) => c.first)
        .where((msg) => (msg.payload as MqttPublishMessage).payload.message.isNotEmpty)
        .map((msg) {
      final MqttPublishMessage recMess = msg.payload as MqttPublishMessage;
      final payload =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      return payload;
    });
  }

  Future<void> publishString(String topic, String payload,
      {MqttQos qos = MqttQos.atLeastOnce, bool retain = false}) async {
    if (!_isConnected) {
      throw StateError('Not connected. Call connect() first.');
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      _client.disconnect();
    }
  }

  // ---- Callbacks ----
  void _onConnected() {
    _isConnected = true;
    if (log) print(' MQTT connected to $host:$port as $clientId');
  }

  void _onDisconnected() {
    _isConnected = false;
    if (log) print(' MQTT disconnected');
  }

  void _onSubscribed(String topic) {
    if (log) print(' Subscribed: $topic');
  }

  void _onSubscribeFail(String topic) {
    if (log) print(' Failed to subscribe: $topic');
  }

  void _onUnsubscribed(String? topic) {
    if (log) print(' Unsubscribed: $topic');
  }

  void _pong() {
    if (log) print(' Ping response');
  }
}
