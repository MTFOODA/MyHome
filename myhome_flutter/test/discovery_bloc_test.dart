import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/discovery_bloc.dart';
import 'fake_property_repository.dart';

class SlowRepository extends FakePropertyRepository {
  final first = Completer<PropertyResults>(),
      second = Completer<PropertyResults>();
  int count = 0;
  @override
  Future<PropertyResults> discover(Map<String, dynamic> filters, int page) =>
      ++count == 1 ? first.future : second.future;
}

void main() {
  test(
    'an older search response cannot overwrite a newer filter result',
    () async {
      final repository = SlowRepository();
      final bloc = DiscoveryBloc(repository);
      bloc.add(SearchProperties({'category': 'private_rental'}));
      await Future<void>.delayed(Duration.zero);
      bloc.add(SearchProperties({'category': 'sale_cash'}));
      await Future<void>.delayed(Duration.zero);
      repository.second.complete(const PropertyResults([], 0, 2));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.results?.page, 2);
      repository.first.complete(const PropertyResults([testProperty], 1, 1));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.results?.page, 2);
      await bloc.close();
    },
  );
}
