import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep.dart';
import '../services/api_client.dart';
import '../services/sleeps_api.dart';
import 'auth_provider.dart';
import 'children_provider.dart';

sealed class SleepsState {
  const SleepsState();
}

class SleepsLoading extends SleepsState {
  const SleepsLoading();
}

class SleepsLoaded extends SleepsState {
  const SleepsLoaded(this.sleeps, this.totalMinutesToday);
  final List<Sleep> sleeps;
  final int totalMinutesToday;

  Sleep? get lastSleep => sleeps.isEmpty ? null : sleeps.first;
}

class SleepsError extends SleepsState {
  const SleepsError(this.message);
  final String message;
}

final sleepsApiProvider = Provider<SleepsApi>((ref) => SleepsApi());

class SleepsController extends Notifier<SleepsState> {
  late final SleepsApi _api;
  String? _childId;

  @override
  SleepsState build() {
    _api = ref.watch(sleepsApiProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final activeChild = childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    _childId = activeChild?.id;

    if (_childId != null) {
      _load(_childId!);
    }
    return const SleepsLoading();
  }

  Future<void> _load(String childId) async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const SleepsError('Not signed in');
      return;
    }
    try {
      final (sleeps, totalMinutesToday) = await _api.listSleeps(accessToken: accessToken, childId: childId);
      state = SleepsLoaded(sleeps, totalMinutesToday);
    } on ApiException catch (e) {
      state = SleepsError(e.message);
    }
  }

  Future<void> logSleep({
    required String type,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final childId = _childId;
    if (childId == null) {
      state = const SleepsError('No active child');
      return;
    }
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const SleepsError('Not signed in');
      return;
    }

    try {
      await _api.createSleep(
        accessToken: accessToken,
        childId: childId,
        type: type,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      await _load(childId);
    } on ApiException catch (e) {
      state = SleepsError(e.message);
      rethrow;
    }
  }
}

final sleepsControllerProvider = NotifierProvider<SleepsController, SleepsState>(SleepsController.new);
