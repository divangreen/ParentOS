import '../models/diaper.dart';
import 'api_client.dart';

class DiapersApi {
  DiapersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Diaper> createDiaper({
    required String accessToken,
    required String childId,
    required String type,
    DateTime? loggedAt,
  }) async {
    final json = await _client.post(
      '/children/$childId/diapers',
      accessToken: accessToken,
      body: {
        'type': type,
        'logged_at': ?loggedAt?.toUtc().toIso8601String(),
      },
    );
    return Diaper.fromJson(json as Map<String, dynamic>);
  }

  Future<(List<Diaper>, int, int)> listDiapers({required String accessToken, required String childId}) async {
    final json =
        await _client.get('/children/$childId/diapers', accessToken: accessToken) as Map<String, dynamic>;
    final diapers = (json['diapers'] as List).map((row) => Diaper.fromJson(row as Map<String, dynamic>)).toList();
    return (diapers, json['wet_count'] as int, json['dirty_count'] as int);
  }
}
