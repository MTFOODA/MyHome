import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import 'auth_cubit.dart';
import 'auth_page.dart';

class IntentsPage extends StatefulWidget {
  final bool settings;
  const IntentsPage({super.key, this.settings = false});
  @override
  State<IntentsPage> createState() => _IntentsPageState();
}

class _IntentsPageState extends State<IntentsPage> {
  late Set<String> _selected;
  String? _active;
  String _persona = 'regular';
  @override
  void initState() {
    super.initState();
    final account = context.read<AuthCubit>().state.account!;
    _selected = account.intents.toSet();
    _active = account.activeIntent;
    _persona = account.housingPersona;
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
                    for (final intent in [
                      'owner_sale_cash',
                      'owner_sale_installments',
                      'owner_private_rental',
                      'owner_shared_rental',
                      'buyer_cash',
                      'buyer_installments',
                      'tenant_private',
                      'tenant_shared',
                    ])
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
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: CheckboxListTile(
                              key: ValueKey('intent_$intent'),
                              title: Text(words(context, intent)),
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
                    const SizedBox(height: 16),
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
                    if (state.failure != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(authError(context, state.failure!)),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('saveIntents'),
                      onPressed: busy || _selected.isEmpty || _active == null
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
