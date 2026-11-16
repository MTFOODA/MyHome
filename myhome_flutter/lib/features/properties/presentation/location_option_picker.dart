import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_icon.dart';
import '../domain/property_repository.dart';

class LocationOptionPicker extends StatelessWidget {
  final List<LocationOption> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  const LocationOptionPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final current = options.where((o) => o.id == selected).firstOrNull;
    String name(LocationOption item) => ar ? item.nameAr : item.nameEn;
    return OutlinedButton(
      onPressed: options.isEmpty
          ? null
          : () async {
              final query = TextEditingController();
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (sheetContext) => StatefulBuilder(
                  builder: (context, set) {
                    final filtered = options
                        .where(
                          (o) => '${o.nameAr} ${o.nameEn}'
                              .toLowerCase()
                              .contains(query.text.trim().toLowerCase()),
                        )
                        .toList();
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * .78,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                key: const Key('areaQuickSearch'),
                                controller: query,
                                decoration: InputDecoration(
                                  labelText: words(context, 'searchArea'),
                                  prefixIcon: const AppIcon(
                                    Icons.search_rounded,
                                  ),
                                ),
                                onChanged: (_) => set(() {}),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, index) => ListTile(
                                  key: ValueKey(
                                    'location-option-${filtered[index].id}',
                                  ),
                                  title: Text(name(filtered[index])),
                                  selected: filtered[index].id == selected,
                                  onTap: () => Navigator.pop(
                                    sheetContext,
                                    filtered[index].id,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
              if (result != null && context.mounted) onChanged(result);
              // The sheet's closing animation may still reference its text field.
              await Future<void>.delayed(const Duration(milliseconds: 300));
              query.dispose();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                current == null ? words(context, 'area') : name(current),
              ),
            ),
            const AppIcon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
