import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/property_repository.dart';

class OwnerListingsState {
  final List<PropertySummary> items;
  final bool loading, loadingMore, failed, moreFailed;
  final int total;
  final String? cursor, changing;
  const OwnerListingsState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.failed = false,
    this.moreFailed = false,
    this.total = 0,
    this.cursor,
    this.changing,
  });
}

class OwnerListingsCubit extends Cubit<OwnerListingsState> {
  final PropertyRepository repository;
  final String group;
  String query = '', scope = 'current', availability = 'all';
  int _generation = 0;
  bool _mutating = false;
  OwnerListingsCubit(this.repository, this.group)
    : super(const OwnerListingsState());
  Future<void> search({
    String? text,
    String? selectedScope,
    String? selectedAvailability,
  }) async {
    if (isClosed) return;
    query = text ?? query;
    scope = selectedScope ?? scope;
    availability = selectedAvailability ?? availability;
    final request = ++_generation;
    emit(const OwnerListingsState(loading: true));
    try {
      final page = await repository.ownerPage(
        group,
        scope: scope,
        query: query,
        availability: availability,
      );
      if (!isClosed && request == _generation) {
        emit(
          OwnerListingsState(
            items: page.items,
            total: page.total,
            cursor: page.nextCursor,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && request == _generation) {
        emit(const OwnerListingsState(failed: true));
      }
    }
  }

  Future<void> more() async {
    final previous = state;
    if (previous.loading ||
        previous.loadingMore ||
        _mutating ||
        previous.cursor == null) {
      return;
    }
    final request = _generation;
    emit(
      OwnerListingsState(
        items: previous.items,
        total: previous.total,
        cursor: previous.cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await repository.ownerPage(
        group,
        scope: scope,
        query: query,
        availability: availability,
        cursor: previous.cursor,
      );
      if (!isClosed && request == _generation) {
        final unique = {
          for (final item in [...previous.items, ...page.items]) item.id: item,
        };
        emit(
          OwnerListingsState(
            items: unique.values.toList(),
            total: page.total,
            cursor: page.nextCursor,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && request == _generation) {
        emit(
          OwnerListingsState(
            items: previous.items,
            total: previous.total,
            cursor: previous.cursor,
            moreFailed: true,
          ),
        );
      }
    }
  }

  Future<bool> change(String id, String target) async {
    if (_mutating || isClosed) return false;
    _mutating = true;
    final request = _generation;
    final previous = state;
    emit(
      OwnerListingsState(
        items: previous.items,
        total: previous.total,
        cursor: previous.cursor,
        changing: id,
      ),
    );
    try {
      await repository.changeAvailability(id, target);
      await search();
      return true;
    } catch (_) {
      if (!isClosed && request == _generation) emit(previous);
      return false;
    } finally {
      _mutating = false;
    }
  }
}
