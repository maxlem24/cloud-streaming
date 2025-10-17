import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'auth_service.dart';
import 'mqtt_service.dart';
import 'chooseBestEdge.dart';

class VideoItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool live;
  final String edges;
  final String thumbnail;
  final String streamerId;
  final DateTime? createdAt;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.live,
    required this.edges,
    required this.thumbnail,
    required this.streamerId,
    required this.createdAt,
  });

  factory VideoItem.fromRowMap(Map<String, dynamic> row) {
    return VideoItem(
      id: row["id"]?.toString() ?? "",
      title: row["title"]?.toString() ?? "",
      description: row["description"]?.toString() ?? "",
      category: row["category"]?.toString() ?? "",
      live: (row["live"] is bool)
          ? row["live"] as bool
          : (row["live"]?.toString() == '1' || row["live"]?.toString().toLowerCase() == 'true'),
      edges: row["edges"]?.toString() ?? "",
      thumbnail: row["thumbnail"]?.toString() ?? "",
      streamerId: row["streamer_id"]?.toString() ?? "",
      createdAt: _tryParseDate(row["created_at"]),
    );
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}

class AppMqttService with ChangeNotifier {
  AppMqttService._();
  static final AppMqttService instance = AppMqttService._();

  MqttService? _mqtt;
  String? _bestEdgeId;
  String? _clientId;

  StreamSubscription? _globalSubscription;

  final List<VideoItem> _liveVideos = [];
  final List<VideoItem> _nonLiveVideos = [];

  String? get bestEdgeId => _bestEdgeId;
  String? get clientId => _clientId;
  bool get isConnected => _mqtt?.isConnected ?? false;

  List<VideoItem> get liveVideos => List.unmodifiable(_liveVideos);
  List<VideoItem> get nonLiveVideos => List.unmodifiable(_nonLiveVideos);

  Future<void> initAndConnect() async {
    final auth = AuthService.instance;

    final token = auth.accessToken;
    final isLoggedIn = auth.isLoggedIn;
    _clientId = (isLoggedIn && token != null && token.isNotEmpty)
        ? token
        : 'guest${1 + Random().nextInt(1000)}';

    const host = '172.20.10.4';

    await _globalSubscription?.cancel();
    _globalSubscription = null;
    await _mqtt?.disconnect();

    _mqtt = MqttService(
      host: host,
      port: 1883,
      clientId: _clientId!,
      log: true,
    );
    print('creation du service MqTT');

    try {

      await _mqtt!.connect();
      debugPrint(' MQTT connecté (clientId=$_clientId)');

      _setupGlobalListener();
/*
      final prefs = await SharedPreferences.getInstance();
      _bestEdgeId = prefs.getString('best_edge_id');

      if (_bestEdgeId == null || _bestEdgeId!.isEmpty) {
        debugPrint(' Recherche du meilleur edge...');
        final selector = EdgeSelector(_mqtt!.rawClient);
        _bestEdgeId = await selector.chooseBestEdge(_clientId!);

        if (_bestEdgeId != null && _bestEdgeId!.isNotEmpty) {
          await prefs.setString('best_edge_id', _bestEdgeId!);
          debugPrint(' Edge sélectionné: $_bestEdgeId');
        } else {
          debugPrint(' ERREUR: Aucun edge disponible après 3 secondes');
          throw Exception('Aucun edge disponible');
        }
      } else {
        debugPrint(' Edge récupéré du cache: $_bestEdgeId');
      }*/

      notifyListeners();
    } catch (e) {
      debugPrint(' Erreur connexion MQTT: $e');
      rethrow;
    }
  }

  void _setupGlobalListener() {
    _globalSubscription?.cancel();
    _globalSubscription = _mqtt!.rawClient.updates!.listen((events) {
      for (final evt in events) {
        _handleIncomingMessage(evt.topic, evt.payload as MqttPublishMessage);
      }
    });
  }


  final Map<String, Completer<List<dynamic>>> _pendingRequests = {};

  void _handleIncomingMessage(String topic, MqttPublishMessage msg) {
    final payload = MqttPublishPayload.bytesToStringAsString(msg.payload.message);


    for (final entry in _pendingRequests.entries) {
      if (topic == entry.key && !entry.value.isCompleted) {
        try {
          final decoded = json.decode(payload);
          if (decoded is List) {
            entry.value.complete(decoded);
          } else if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is List) {
              entry.value.complete(decoded['data'] as List);
            } else if (decoded['videos'] is List) {
              entry.value.complete(decoded['videos'] as List);
            } else {
              entry.value.completeError('Format JSON inattendu: $decoded');
            }
          } else {
            entry.value.completeError('Type de données inattendu: ${decoded.runtimeType}');
          }
        } catch (e) {
          entry.value.completeError('Erreur parsing JSON: $e');
        }
        return;
      }
    }
  }

  Future<void> refreshVideos() async {
    await refreshBestEdge();
    if (!isConnected) throw StateError('MQTT non connecté');
    if (_bestEdgeId == null || _bestEdgeId!.isEmpty) {
      throw StateError('Aucun edge sélectionné');
    }

    final videoTopic = 'video/liste/$_bestEdgeId/$_clientId';
    final pingMessage = jsonEncode({"client_id": _clientId});
    final builder = MqttClientPayloadBuilder()..addString(pingMessage);

    _mqtt!.rawClient.subscribe(videoTopic, MqttQos.atLeastOnce);
    _mqtt!.rawClient.publishMessage('video/liste/$_bestEdgeId', MqttQos.atLeastOnce, builder.payload!);


    debugPrint('️  Abonné à $videoTopic, attente du premier message...');


    final completer = Completer<List<dynamic>>();
    late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> sub;

    sub = _mqtt!.rawClient.updates!.listen((events) {
      for (final evt in events) {
        final topic = evt.topic;
        final msg = evt.payload;
        if (msg is! MqttPublishMessage) continue;

        final payload =
        MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        debugPrint(' RECV topic="$topic" payload="${payload.length}B"');

        if (topic == videoTopic && !completer.isCompleted) {
          try {
            final decoded = jsonDecode(payload);
            debugPrint('🧾 Payload JSON: $decoded');


            late final List<dynamic> rows;
            if (decoded is List) {
              rows = decoded;
            } else if (decoded is Map<String, dynamic>) {
              if (decoded['videos'] is List) {
                rows = decoded['videos'] as List<dynamic>;
              } else if (decoded['rows'] is List) {
                rows = decoded['rows'] as List<dynamic>;
              } else {
                throw const FormatException('Format inattendu (ni list, ni videos/rows)');
              }
            } else {
              throw const FormatException('Payload non JSON list/map');
            }

            completer.complete(rows);
          } catch (e) {
            debugPrint(' Erreur parsing payload vidéos: $e');
            completer.completeError(e);
          }
        }
      }
    });


    debugPrint('📤 PUBLISH -> $videoTopic ; body=$pingMessage (QoS1)');



    late final List<dynamic> rows;
    try {
      rows = await completer.future;
      debugPrint(' Réponse reçue: ${rows.length} vidéo(s)');
    } catch (e) {
      debugPrint(' Erreur récupération vidéos: $e');
      rethrow;
    } finally {
      try { await sub.cancel(); } catch (_) {}
      try { _mqtt?.rawClient.unsubscribe(videoTopic); } catch (_) {}
      debugPrint('↩️  Unsub $videoTopic');
    }


    final live = <VideoItem>[];
    final vod  = <VideoItem>[];

    for (final r in rows) {
      try {
        if (r is Map<String, dynamic>) {
          final item = VideoItem.fromRowMap(r);
          (item.live ? live : vod).add(item);
        } else {
          debugPrint('Ligne ignorée (non-Map): $r');
        }
      } catch (e) {
        debugPrint('Erreur parsing vidéo: $e');
      }
    }

    _liveVideos
      ..clear()
      ..addAll(live);
    _nonLiveVideos
      ..clear()
      ..addAll(vod);
    print("videooooooooooooo ${_liveVideos}");

    debugPrint('📊 Vidéos chargées: ${live.length} live, ${vod.length} VOD');
    notifyListeners();
  }




  Future<void> refreshBestEdge() async {
    if (!isConnected) throw StateError('MQTT non connecté');
    if (_clientId == null) throw StateError('Aucun clientId');

    debugPrint('Recherche d\'un nouvel edge...');

    final selector = EdgeSelector(_mqtt!.rawClient);
    _bestEdgeId = await selector.chooseBestEdge(_clientId!);

    if (_bestEdgeId != null && _bestEdgeId!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('best_edge_id', _bestEdgeId!);
      debugPrint(' Nouvel edge sélectionné: $_bestEdgeId');
      notifyListeners();
    } else {
      debugPrint(' Aucun edge disponible');
      throw Exception('Aucun edge disponible');
    }
  }


  Future<void> clearEdgeCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('best_edge_id');
    _bestEdgeId = null;
    debugPrint(' Cache edge effacé');
  }

  Future<void> disconnect() async {
    await _globalSubscription?.cancel();
    _globalSubscription = null;
    _pendingRequests.clear();
    await _mqtt?.disconnect();
    _mqtt = null;
    debugPrint(' MQTT déconnecté');
  }
}