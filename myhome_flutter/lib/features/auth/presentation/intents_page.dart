import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import 'auth_cubit.dart';
import 'auth_page.dart';
import '../../../core/widgets/property_illustration.dart';

class IntentsPage extends StatefulWidget {
  final bool settings;
  const IntentsPage({super.key, this.settings = false});
  @override
  State<IntentsPage> createState() => _IntentsPageState();
}

class _IntentsPageState extends State<IntentsPage> {
  static const _groups = {
    'owner': [
      'owner_sale_cash',
      'owner_sale_installments',
      'owner_private_rental',
      'owner_shared_rental',
    ],
    'seeker': [
      'buyer_cash',
      'buyer_installments',
      'tenant_private',
      'tenant_shared',
    ],
  };
  final Set<String> _families = {};
  late Set<String> _selected;
  String? _active;
  String _persona = 'regular';
  @override
  void initState() {
    super.initState();
    final account = context.read<AuthCubit>().state.account!;
    _selected = account.intents.toSet();
    for (final group in _groups.entries) {
      if (group.value.any(_selected.contains)) _families.add(group.key);
    }
    _active = account.activeIntent;
    _persona = account.housingPersona;
  }

  void _toggleFamily(String family) => setState(() {
    if (!_families.add(family)) {
      _families.remove(family);
      _selected.removeAll(_groups[family]!);
      if (!_selected.contains(_active)) _active = _selected.firstOrNull;
    }
  });

  Widget _familyCard(String family, bool busy, double width) {
    final selected = _families.contains(family);
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('family_$family'),
            borderRadius: BorderRadius.circular(20),
            onTap: busy ? null : () => _toggleFamily(family),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  PropertyIllustration(
                    family == 'owner' ? 'home' : 'location',
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          words(context, '${family}Family'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(words(context, '${family}FamilyHint')),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    onChanged: busy ? null : (_) => _toggleFamily(family),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
    listener: (context, state) {
      if (widget.settings &&
          state.status == AuthStatus.signedIn &&
          state.failure == null) {
        Navigator.pop(context);
      }
    },
    builder: (context, state) {
      final busy = state.status == AuthStatus.busy;
      return Scaffold(
        appBar: AppBar(
          title: Text(words(context, 'roles')),
          automaticallyImplyLeading: widget.settings,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      words(context, 'rolesHint'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final family in _groups.keys)
                            _familyCard(
                              family,
                              busy,
                              constraints.maxWidth >= 600
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final family in _groups.keys)
                      if (_families.contains(family)) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            words(context, '${family}Types'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final intent in _groups[family]!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                color: _selected.contains(intent)
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                child: CheckboxListTile(
                                  key: ValueKey('intent_$intent'),
                                  secondary: PropertyIllustration(
                                    intent,
                                    size: 40,
                                  ),
                                  title: Text(
                                    words(
                                      context,
                                      family == 'owner'
                                          ? intent.substring(6)
                                          : intent,
                                    ),
                                  ),
                                  value: _selected.contains(intent),
                                  onChanged: busy
                                      ? null
                                      : (checked) => setState(() {
                                          if (checked!) {
                                            _selected.add(intent);
                                            _active ??= intent;
                                          } else {
                                            _selected.remove(intent);
                                            if (_active == intent) {
                                              _active = _selected.firstOrNull;
                                            }
                                          }
                                        }),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 16),
                    if (_selected.length > 1) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(_active),
                        initialValue: _active,
                        decoration: InputDecoration(
                          labelText: words(context, 'activeMode'),
                        ),
                        isExpanded: true,
                        items: _selected
                            .map(
                              (intent) => DropdownMenuItem(
                                value: intent,
                                child: Text(words(context, intent)),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => _active = value),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_selected.contains('tenant_shared')) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _persona,
                        decoration: InputDecoration(
                          labelText: words(context, 'persona'),
                        ),
                        items: ['regular', 'student', 'expatriate']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(words(context, value)),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => _persona = value!),
                      ),
                    ],
                    if (state.failure != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(authError(context, state.failure!)),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('saveIntents'),
                      onPressed:
                          busy ||
                              _selected.isEmpty ||
                              _active == null ||
                              _families.any(
                                (family) =>
                                    !_groups[family]!.any(_selected.contains),
                              )
                          ? null
                          : () => context.read<AuthCubit>().updateIntents(
                              _selected.toList(),
                              _active!,
                              _persona,
                            ),
                      child: busy
                          ? const CircularProgressIndicator()
                          : Text(words(context, 'continue')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
