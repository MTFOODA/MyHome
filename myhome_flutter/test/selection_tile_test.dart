import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/widgets/choice_artwork.dart';
import 'package:myhome_flutter/core/widgets/selection_tile.dart';

void main() {
  testWidgets(
    'picture selection toggles on press with no checkbox and exposes its state',
    (tester) async {
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) => SelectionTile(
                label: 'Furnished',
                artwork: 'furnished',
                selected: selected,
                onChanged: (value) => set(() => selected = value),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Radio<bool>), findsNothing);
      expect(find.byType(ChoiceArtwork), findsOneWidget);
      await tester.tap(find.text('Furnished'));
      await tester.pumpAndSettle();
      expect(selected, true);
      expect(
        tester.widget<SelectionTile>(find.byType(SelectionTile)).selected,
        true,
      );
      await tester.tap(find.text('Furnished'));
      await tester.pumpAndSettle();
      expect(selected, false);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'choice artwork has a real alpha channel and transparent surroundings',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final data = await rootBundle.load(ChoiceArtwork.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final pixels = (await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var transparent = 0;
      for (var i = 3; i < pixels.lengthInBytes; i += 4) {
        if (pixels.getUint8(i) == 0) transparent++;
      }
      expect(
        transparent / (frame.image.width * frame.image.height),
        greaterThan(.1),
      );
      frame.image.dispose();
      codec.dispose();
    },
  );
}
