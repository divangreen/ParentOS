import '../models/child.dart';
import 'api_client.dart';

class ChildrenApi {
  ChildrenApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Child> createChild({
    required String accessToken,
    required String name,
    required DateTime dateOfBirth,
    double? birthWeightKg,
  }) async {
    final json = await _client.post(
      '/children',
      accessToken: accessToken,
      body: {
        'name': name,
        'date_of_birth': _dateOnly(dateOfBirth),
        'birth_weight_kg': ?birthWeightKg,
      },
    );
    return Child.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Child>> listChildren({required String accessToken}) async {
    final json = await _client.get('/children', accessToken: accessToken) as Map<String, dynamic>;
    return (json['children'] as List)
        .map((row) => Child.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Child> getChild({required String accessToken, required String childId}) async {
    final json = await _client.get('/children/$childId', accessToken: accessToken);
    return Child.fromJson(json as Map<String, dynamic>);
  }

  Future<Child> updateChild({
    required String accessToken,
    required String childId,
    String? name,
    DateTime? dateOfBirth,
    double? birthWeightKg,
  }) async {
    final json = await _client.patch(
      '/children/$childId',
      accessToken: accessToken,
      body: {
        'name': ?name,
        'date_of_birth': ?(dateOfBirth != null ? _dateOnly(dateOfBirth) : null),
        'birth_weight_kg': ?birthWeightKg,
      },
    );
    return Child.fromJson(json as Map<String, dynamic>);
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
