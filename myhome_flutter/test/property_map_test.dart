import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/domain/location_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/location_picker_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/property_map.dart';
import 'package:myhome_flutter/features/properties/presentation/property_photo.dart';
import 'fake_property_repository.dart';
import 'sales_chat_test.dart' show financialApp;

class TestLocationRepository implements LocationRepository {
  int requests = 0;
  bool denied = false;
  @override
  Future<PropertyLocation> currentLocation() async {
    requests++;
    if (denied) throw const LocationFailure('locationDenied');
    return const PropertyLocation(30.1, 31.2);
  }

  @override
  Future<MapConfiguration> configuration() async => const MapConfiguration();
  @override
  Future<PropertyLocation?> parseLink(String link) async => null;
}

class TestTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/branding/app-icon.png');
}

class FailedTile extends Fake implements TileImage {}

class PrivatePhotosRepository extends FakePropertyRepository {
  int privateRequests = 0, publicRequests = 0;
  @override
  Future<List<int>> privateImage(String id) async {
    privateRequests++;
    return File('assets/branding/app-icon.png').readAsBytesSync();
  }

  @override
  String photoUrl(String id) {
    publicRequests++;
    return super.photoUrl(id);
  }
}

void main() {
  test(
    'coordinates are independent, bounded and round trip with seven decimals',
    () {
      final point = PropertyLocation.fromValues({
        'latitude': '30.1234567',
        'longitude': '31.7654321',
      })!;
      expect(point.toJson(), {
        'latitude': '30.1234567',
        'longitude': '31.7654321',
      });
      for (final data in [
        <String, dynamic>{'latitude': '30'},
        {'latitude': 'NaN', 'longitude': '31'},
        {'latitude': '0', 'longitude': '31'},
        {'latitude': '30', 'longitude': '180'},
      ]) {
        expect(PropertyLocation.fromValues(data), isNull);
      }
    },
  );
  test(
    'location access is explicit, denial preserves selected property pin',
    () async {
      final repo = TestLocationRepository()..denied = true;
      final cubit = LocationPickerCubit(repo);
      addTearDown(cubit.close);
      expect(repo.requests, 0);
      cubit.choose(const PropertyLocation(30, 31));
      expect(repo.requests, 0);
      await cubit.locate();
      expect(repo.requests, 1);
      expect(cubit.state.error, 'locationDenied');
      expect(cubit.state.selected!.latitude, 30);
      cubit.choose(const PropertyLocation(0, 0));
      expect(cubit.state.error, 'locationOutside');
      expect(cubit.state.selected!.latitude, 30);
    },
  );
  test('successful device selection updates both coordinates', () async {
    final repo = TestLocationRepository();
    final cubit = LocationPickerCubit(repo);
    addTearDown(cubit.close);
    await cubit.locate();
    expect(cubit.state.selected!.toJson(), {
      'latitude': '30.1000000',
      'longitude': '31.2000000',
    });
  });
  testWidgets(
    'map tap selects a point; dragging its marker changes the saved coordinates',
    (tester) async {
      final point = ValueNotifier<PropertyLocation?>(null);
      addTearDown(point.dispose);
      await tester.pumpWidget(
        financialApp(
          SizedBox(
            height: 450,
            child: ValueListenableBuilder(
              valueListenable: point,
              builder: (_, value, _) => PropertyMap(
                selected: value,
                tileProvider: TestTiles(),
                onSelected: (value) => point.value = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(point.value, isNull);
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(point.value!.valid, isTrue);
      final original = point.value!;
      await tester.drag(
        find.byKey(const Key('draggablePropertyPin')),
        const Offset(60, 35),
      );
      await tester.pumpAndSettle();
      expect(point.value!.latitude, isNot(original.latitude));
      expect(point.value!.longitude, isNot(original.longitude));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tile failure preserves the pin and visible attribution and offers manual retry',
    (tester) async {
      await tester.pumpWidget(
        financialApp(
          SizedBox(
            height: 450,
            child: PropertyMap(
              selected: const PropertyLocation(30, 31),
              tileProvider: TestTiles(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tiles = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tiles.panBuffer, 0);
      expect(
        tiles.tileProvider.headers['User-Agent'],
        contains('com.myhome.app'),
      );
      tiles.errorTileCallback!(
        FailedTile(),
        Exception('offline'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Map tiles could not load'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join('|'),
      );
      expect(find.byKey(const Key('draggablePropertyPin')), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'property markers remain clickable without opening property details automatically',
    (tester) async {
      final semantics = tester.ensureSemantics();
      String? selected;
      await tester.pumpWidget(
        financialApp(
          SizedBox(
            height: 450,
            child: PropertyMap(
              properties: const [
                MapPropertyPin(
                  'one',
                  'First property',
                  PropertyLocation(30, 31),
                ),
              ],
              tileProvider: TestTiles(),
              onProperty: (id) => selected = id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.bySemanticsLabel('First property'));
      await tester.pumpAndSettle();
      expect(selected, 'one');
      semantics.dispose();
    },
  );
  testWidgets(
    'pending property photos load with the authorized repository, never a public URL',
    (tester) async {
      final repo = PrivatePhotosRepository();
      await tester.pumpWidget(
        financialApp(
          SizedBox(
            height: 190,
            child: PropertyPhoto(
              id: 'pending-photo',
              repository: repo,
              private: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.privateRequests, 1);
      expect(repo.publicRequests, 0);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
