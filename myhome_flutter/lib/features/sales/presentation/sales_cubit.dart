import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/sales_repository.dart';

class SalesState {
  final Map<String, dynamic>? deal;
  final bool busy;
  final String? error;
  const SalesState({this.deal, this.busy = false, this.error});
}

class SalesCubit extends Cubit<SalesState> {
  final SalesRepository repository;
  final String id;
  int _generation = 0;
  bool _mutating = false;
  SalesCubit(this.repository, this.id) : super(const SalesState());
  Future<void> load() async {
    if (isClosed) return;
    final request = ++_generation;
    final previous = state.deal;
    emit(SalesState(deal: previous, busy: true));
    try {
      final data = await repository.detail(id);
      if (!isClosed && request == _generation) emit(SalesState(deal: data));
    } on SalesFailure catch (e) {
      if (!isClosed && request == _generation) {
        emit(SalesState(deal: previous, error: e.code));
      }
    } catch (_) {
      if (!isClosed && request == _generation) {
        emit(SalesState(deal: previous, error: 'NETWORK_ERROR'));
      }
    }
  }

  Future<bool> act(Future<void> Function() action) async {
    if (isClosed || _mutating) return false;
    _mutating = true;
    final previous = state.deal;
    emit(SalesState(deal: previous, busy: true));
    try {
      await action();
      await load();
      return state.error == null;
    } on SalesFailure catch (e) {
      if (!isClosed) emit(SalesState(deal: previous, error: e.code));
      return false;
    } catch (_) {
      if (!isClosed) emit(SalesState(deal: previous, error: 'NETWORK_ERROR'));
      return false;
    } finally {
      _mutating = false;
    }
  }
}
