import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feeding.dart';
import '../services/api_client.dart';
import '../services/feedings_api.dart';
import 'auth_provider.dart';
import 'children_provider.dart';

sealed class FeedingsState {
  const FeedingsState();
}

class FeedingsLoading extends FeedingsState {
  const FeedingsLoading();
}

class FeedingsLoaded extends FeedingsState {
  const FeedingsLoaded(this.feedings);
  final List<Feeding> feedings;

  int get todayCount => feedings.length;

  Feeding? get lastFeeding => feedings.isEmpty ? null : feedings.first;
}

class FeedingsError extends FeedingsState {
  const FeedingsError(this.message);
  final String message;
}

final feedingsApiProvider = Provider<FeedingsApi>((ref) => FeedingsApi());

class FeedingsController extends Notifier<FeedingsState> {
  late final FeedingsApi _api;
  String? _childId;

  @override
  FeedingsState build() {
    _api = ref.watch(feedingsApiProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final activeChild = childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    _childId = activeChild?.id;

    if (_childId != null) {
      _load(_childId!);
    }
    return const FeedingsLoading();
  }

  Future<void> _load(String childId) async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const FeedingsError('Not signed in');
      return;
    }
    try {
      final feedings = await _api.listFeedings(accessToken: accessToken, childId: childId);
      state = FeedingsLoaded(feedings);
    } on ApiException catch (e) {
      state = FeedingsError(e.message);
    }
  }

  Future<void> logFeeding({
    required String type,
    String? side,
    int? durationMinutes,
    int? volumeMl,
    String? milkType,
  }) async {
    final childId = _childId;
    if (childId == null) {
      state = const FeedingsError('No active child');
      return;
    }
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const FeedingsError('Not signed in');
      return;
    }

    // Optimistic update: show the new feeding immediately, then reconcile with the server.
    final previous = state;
    if (previous is FeedingsLoaded) {
      final optimistic = Feeding(
        id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        side: side,
        durationMinutes: durationMinutes,
        volumeMl: volumeMl,
        milkType: milkType,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      state = FeedingsLoaded([optimistic, ...previous.feedings]);
    }

    try {
      await _api.createFeeding(
        accessToken: accessToken,
        childId: childId,
        type: type,
        side: side,
        durationMinutes: durationMinutes,
        volumeMl: volumeMl,
        milkType: milkType,
      );
      await _load(childId);
    } on ApiException catch (e) {
      state = previous is FeedingsLoaded ? previous : FeedingsError(e.message);
      rethrow;
    }
  }
}

final feedingsControllerProvider = NotifierProvider<FeedingsController, FeedingsState>(
  FeedingsController.new,
);
