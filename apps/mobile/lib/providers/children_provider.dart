import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/child.dart';
import '../services/api_client.dart';
import '../services/children_api.dart';
import 'auth_provider.dart';

sealed class ChildrenState {
  const ChildrenState();
}

class ChildrenLoading extends ChildrenState {
  const ChildrenLoading();
}

class ChildrenLoaded extends ChildrenState {
  const ChildrenLoaded(this.children);
  final List<Child> children;

  /// MVP assumes a single active child per account (newborn tracking) --
  /// the most recently added one.
  Child? get activeChild => children.isEmpty ? null : children.last;
}

class ChildrenError extends ChildrenState {
  const ChildrenError(this.message);
  final String message;
}

final childrenApiProvider = Provider<ChildrenApi>((ref) => ChildrenApi());

class ChildrenController extends Notifier<ChildrenState> {
  late final ChildrenApi _childrenApi;

  @override
  ChildrenState build() {
    _childrenApi = ref.watch(childrenApiProvider);
    final authState = ref.watch(authControllerProvider);

    if (authState is AuthAuthenticated) {
      _load();
    }
    return const ChildrenLoading();
  }

  Future<void> _load() async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const ChildrenError('Not signed in');
      return;
    }
    try {
      final children = await _childrenApi.listChildren(accessToken: accessToken);
      state = ChildrenLoaded(children);
    } on ApiException catch (e) {
      state = ChildrenError(e.message);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addChild({
    required String name,
    required DateTime dateOfBirth,
    double? birthWeightKg,
  }) async {
    final accessToken = await ref.read(tokenStorageProvider).readAccessToken();
    if (accessToken == null) {
      state = const ChildrenError('Not signed in');
      return;
    }
    try {
      await _childrenApi.createChild(
        accessToken: accessToken,
        name: name,
        dateOfBirth: dateOfBirth,
        birthWeightKg: birthWeightKg,
      );
      await _load();
    } on ApiException catch (e) {
      state = ChildrenError(e.message);
      rethrow;
    }
  }
}

final childrenControllerProvider = NotifierProvider<ChildrenController, ChildrenState>(
  ChildrenController.new,
);
