import '../models/sleep.dart';
import 'api_client.dart';

class SleepsApi {
  SleepsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Sleep> createSleep({
    required String accessToken,
    required String childId,
    required String type,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final json = await _client.post(
      '/children/$childId/sleeps',
      accessToken: accessToken,
      body: {
        'type': type,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
      },
    );
    return Sleep.fromJson(json as Map<String, dynamic>);
  }

  Future<(List<Sleep>, int)> listSleeps({required String accessToken, required String childId}) async {
    final json =
        await _client.get('/children/$childId/sleeps', accessToken: accessToken) as Map<String, dynamic>;
    final sleeps = (json['sleeps'] as List).map((row) => Sleep.fromJson(row as Map<String, dynamic>)).toList();
    return (sleeps, json['total_minutes_today'] as int);
  }
}
