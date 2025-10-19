import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class EdgeData {
  final String edgeId;
  final double cpuUsagePercent;
  final Map<String, dynamic> memoryUsage;
  final Map<String, dynamic> diskUsage;
  final String timestamp;
  final String status;

  EdgeData({
    required this.edgeId,
    required this.cpuUsagePercent,
    required this.memoryUsage,
    required this.diskUsage,
    required this.timestamp,
    required this.status,
  });

  factory EdgeData.fromJson(Map<String, dynamic> json) {
    return EdgeData(
      edgeId: json['edge_id'] ?? '',
      cpuUsagePercent: (json['cpu_usage_percent'] ?? 100.0).toDouble(),
      memoryUsage: json['memory_usage'] ?? {},
      diskUsage: json['disk_usage'] ?? {},
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class EdgeSelector {
  late MqttServerClient client;

  EdgeSelector(this.client);

  /// Calculate latency from timestamp
  double calculateLatency(String timestampStr) {
    try {
      // Parse ISO timestamp
      DateTime edgeTime = DateTime.parse(timestampStr.replaceAll('Z', ''));
      DateTime currentTime = DateTime.now();

      // Calculate latency in milliseconds
      double latency = currentTime.difference(edgeTime).inMilliseconds.toDouble();
      return latency < 0 ? 0 : latency; // Ensure non-negative latency
    } catch (e) {
      return double.infinity;
    }
  }

  /// Calculate a score for an edge based on its performance metrics
  double calculateScore(EdgeData edgeData) {
    try {
      double cpuScore = edgeData.cpuUsagePercent;
      double memoryScore = (edgeData.memoryUsage['percent'] ?? 100.0).toDouble();
      double diskScore = (edgeData.diskUsage['percent'] ?? 100.0).toDouble();
      double latency = calculateLatency(edgeData.timestamp);

      // Weighted scoring
      double score = (cpuScore * 0.3 +
          memoryScore * 0.3 +
          diskScore * 0.2 +
          min(latency, 1000) * 0.2);

      // Heavy penalty for high usage
      if (cpuScore > 90 || memoryScore > 90 || diskScore > 90) {
        score += 1000;
      }

      return score;
    } catch (e) {
      return double.infinity;
    }
  }

  /// Choose the best edge cluster based on CPU, RAM, Disk usage and Latency
  /// Returns the ID of the most suitable edge cluster
  Future<String?> chooseBestEdge(String clientId) async {
    // Send ping request
    final pingMessage = jsonEncode({"client_id": clientId});
    final builder = MqttClientPayloadBuilder();
    builder.addString(pingMessage);

    client.subscribe("video/request/ping/$clientId", MqttQos.atMostOnce);

    client.publishMessage("video/request/ping", MqttQos.atMostOnce, builder.payload!);

    String? bestEdgeId;
    int responses = 0;
    List<EdgeData> dataEdges = [];


    final Completer<void> responseCompleter = Completer<void>();

    late StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> subscription;

    subscription = client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final topic = message.topic;

        if (topic == "video/request/ping/$clientId") {
          try {
            final payload = MqttPublishPayload.bytesToStringAsString(
                (message.payload as MqttPublishMessage).payload.message
            );

            final Map<String, dynamic> edgeDataJson = jsonDecode(payload);


            if (edgeDataJson['status'] == 'ok' && edgeDataJson.containsKey('edge_id')) {
              final edgeData = EdgeData.fromJson(edgeDataJson);
              dataEdges.add(edgeData);
              responses++;


              print("Received response from edge ${edgeData.edgeId}");

/// a canger a 3
              if (responses > 2 && !responseCompleter.isCompleted) {
                responseCompleter.complete();
              }
            }
          } catch (e) {
            print("Error processing edge response: $e");
          }
        }
      }
    });


    final startTime = DateTime.now();
    const timeout = Duration(seconds: 3);
    const minWaitTime = Duration(seconds: 1);

    try {

      await Future.any([
        responseCompleter.future,
        Future.delayed(timeout),
      ]);


      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minWaitTime) {
        await Future.delayed(minWaitTime - elapsed);
      }


      if (responses < 2 && DateTime.now().difference(startTime) < timeout) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

    } catch (e) {
      print("Error waiting for responses: $e");
    } finally {
// TODO : a revoir
      subscription.cancel();
      client.unsubscribe("video/request/ping/$clientId");
    }

    // Evaluate responses
    if (responses >= 1) {
      List<MapEntry<String, double>> scoredEdges = [];

      for (final edgeData in dataEdges) {
        final score = calculateScore(edgeData);
        scoredEdges.add(MapEntry(edgeData.edgeId, score));
      }

      // Sort by score (lower is better)
      scoredEdges.sort((a, b) => a.value.compareTo(b.value));

      if (scoredEdges.isNotEmpty) {
        bestEdgeId = scoredEdges.first.key;
        print("Selected best edge: $bestEdgeId");
      }
    }
    print("le edge choisi est : $bestEdgeId");
    subscription.cancel();
    client.unsubscribe("video/request/ping/$clientId");
    return bestEdgeId;
  }
}

// Usage example:
// final edgeSelector = EdgeSelector(mqttClient);
// final bestEdge = await edgeSelector.chooseBestEdge("client123");