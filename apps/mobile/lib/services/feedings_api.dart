import '../models/feeding.dart';
import 'api_client.dart';

class FeedingsApi {
  FeedingsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Feeding> createFeeding({
    required String accessToken,
    required String childId,
    required String type,
    String? side,
    int? durationMinutes,
    int? volumeMl,
    String? milkType,
  }) async {
    final json = await _client.post(
      '/children/$childId/feedings',
      accessToken: accessToken,
      body: {
        'type': type,
        'side': ?side,
        'duration_minutes': ?durationMinutes,
        'volume_ml': ?volumeMl,
        'milk_type': ?milkType,
      },
    );
    return Feeding.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Feeding>> listFeedings({required String accessToken, required String childId}) async {
    final json =
        await _client.get('/children/$childId/feedings', accessToken: accessToken) as Map<String, dynamic>;
    return (json['feedings'] as List).map((row) => Feeding.fromJson(row as Map<String, dynamic>)).toList();
  }
}
