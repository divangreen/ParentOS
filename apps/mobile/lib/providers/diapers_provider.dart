import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diaper.dart';
import '../services/api_client.dart';
import '../services/diapers_api.dart';
import 'auth_provider.dart';
import 'children_provider.dart';

sealed class DiapersState {
  const DiapersState();
}

class DiapersLoading extends DiapersState {
  const DiapersLoading();
}

class DiapersLoaded extends DiapersState {
  const DiapersLoaded(this.diapers, this.wetCount, this.dirtyCount);
  final List<Diaper> diapers;
  final int wetCount;
  final int dirtyCount;
}

class DiapersError extends DiapersState {
  const DiapersError(this.message);
  final String message;
}

final diapersApiProvider = Provider<DiapersApi>((ref) => DiapersApi());

class DiapersController extends Notifier<DiapersState> {
  late final DiapersApi _api;
  String? _childId;

  @override
  DiapersState build() {
    _api = ref.watch(diapersApiProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final activeChild = childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    _childId = activeChild?.id;

    if (_childId != null) {
      _load(_childId!);
    }
    return const DiapersLoading();
  }

  Future<void> _load(String childId) async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const DiapersError('Not signed in');
      return;
    }
    try {
      final (diapers, wetCount, dirtyCount) =
          await _api.listDiapers(accessToken: accessToken, childId: childId);
      state = DiapersLoaded(diapers, wetCount, dirtyCount);
    } on ApiException catch (e) {
      state = DiapersError(e.message);
    }
  }

  /// "type tap = auto-save" -- logs immediately, no confirmation form.
  Future<void> logDiaper(String type) async {
    final childId = _childId;
    if (childId == null) {
      state = const DiapersError('No active child');
      return;
    }
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const DiapersError('Not signed in');
      return;
    }

    try {
      await _api.createDiaper(accessToken: accessToken, childId: childId, type: type);
      await _load(childId);
    } on ApiException catch (e) {
      state = DiapersError(e.message);
      rethrow;
    }
  }
}

final diapersControllerProvider = NotifierProvider<DiapersController, DiapersState>(
  DiapersController.new,
);
