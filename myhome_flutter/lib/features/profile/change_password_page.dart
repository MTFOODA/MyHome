import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/operator_strings.dart';
import '../../core/widgets/app_layout.dart';
import '../auth/domain/auth_repository.dart';
import '../auth/presentation/auth_cubit.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false, _hidden = true;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().repository.changePassword(
        _current.text,
        _next.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(operatorText(context, 'passwordChanged'))),
      );
      Navigator.pop(context);
    } on PasswordChangeFailure catch (error) {
      if (mounted) setState(() => _error = error.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'NETWORK_ERROR');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    scene: ArchitecturalScene.balconies,
    appBar: AppBar(title: Text(operatorText(context, 'changePassword'))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in [
                  ('currentPassword', _current),
                  ('newPassword', _next),
                  ('confirmPassword', _confirm),
                ]) ...[
                  TextFormField(
                    key: ValueKey(entry.$1),
                    controller: entry.$2,
                    obscureText: _hidden,
                    enabled: !_busy,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: operatorText(context, entry.$1),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) => entry.$1 == 'confirmPassword'
                        ? (value != _next.text
                              ? operatorText(context, 'passwordMismatch')
                              : null)
                        : ((value ?? '').length <
                                      (entry.$1 == 'currentPassword' ? 1 : 8) ||
                                  utf8.encode(value ?? '').length > 72
                              ? operatorText(
                                  context,
                                  entry.$1 == 'currentPassword'
                                      ? 'currentPasswordRequired'
                                      : 'PASSWORD_INVALID',
                                )
                              : null),
                  ),
                  const SizedBox(height: 20),
                ],
                IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  tooltip: operatorText(
                    context,
                    _hidden ? 'showPassword' : 'hidePassword',
                  ),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      operatorText(context, _error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('savePassword'),
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(operatorText(context, 'save')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
