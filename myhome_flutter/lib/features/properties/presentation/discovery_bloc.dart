import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/property_repository.dart';

sealed class DiscoveryEvent {}

class SearchProperties extends DiscoveryEvent {
  final Map<String, dynamic> filters;
  final int page;
  SearchProperties(this.filters, [this.page = 1]);
}

class DiscoveryState {
  final bool loading;
  final PropertyResults? results;
  final bool failed;
  const DiscoveryState({
    this.loading = false,
    this.results,
    this.failed = false,
  });
}

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final PropertyRepository repository;
  int _request = 0;
  DiscoveryBloc(this.repository) : super(const DiscoveryState()) {
    on<SearchProperties>((event, emit) async {
      final request = ++_request;
      emit(DiscoveryState(loading: true, results: state.results));
      try {
        final results = await repository.discover(event.filters, event.page);
        if (request == _request) emit(DiscoveryState(results: results));
      } catch (_) {
        if (request == _request) {
          emit(DiscoveryState(failed: true, results: state.results));
        }
      }
    });
  }
}
