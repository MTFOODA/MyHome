import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/widgets/brand_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/locale_config.dart';
import '../../../core/config/settings_cubit.dart';
import '../../../core/config/theme_config.dart';
import '../domain/auth_repository.dart';
import 'auth_cubit.dart';

String authError(BuildContext context, AuthFailure failure) {
  final l = context.l10n;
  return switch (failure) {
    AuthFailure.credentials => l.credentialsError,
    AuthFailure.emailInUse => l.emailInUseError,
    AuthFailure.network => l.networkError,
    AuthFailure.rateLimited => l.rateLimitError,
    AuthFailure.validation => l.validationError,
    AuthFailure.storage => l.storageError,
    AuthFailure.server => l.serverError,
  };
}

String roleLabel(BuildContext context, String role) {
  final l = context.l10n;
  return switch (role) {
    'student' => l.roleStudent,
    'expatriate' => l.roleExpatriate,
    'owner' => l.roleOwner,
    'maintenance_provider' => l.roleProvider,
    'admin' => l.roleAdmin,
    _ => l.roleUser,
  };
}

class AuthPage extends StatefulWidget {
  final VoidCallback onGuest;
  const AuthPage({super.key, required this.onGuest});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false, _obscure = true, _obscureConfirm = true;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().submit(
      email: _email.text,
      password: _password.text,
      name: _register ? _name.text : null,
      role: 'user',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final busy = state.status == AuthStatus.busy;
        return Scaffold(
          body: Stack(
            children: [
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 330,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: ThemeConfig.teal,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: AutofillGroup(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (Navigator.canPop(context))
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onPressed: busy
                                      ? null
                                      : () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => context
                                    .read<SettingsCubit>()
                                    .toggleLanguage(),
                                icon: const Icon(Icons.translate, size: 18),
                                label: Text(
                                  Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ar'
                                      ? 'English'
                                      : 'العربية',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const BrandWordmark(),
                            const SizedBox(height: 6),
                            Text(
                              l.tagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD4E5E6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _register
                                            ? l.createAccount
                                            : l.welcomeBack,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _register
                                            ? l.registerSubtitle
                                            : l.signInSubtitle,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      if (_register) ...[
                                        TextFormField(
                                          key: const Key('name'),
                                          controller: _name,
                                          enabled: !busy,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          maxLength: 100,
                                          decoration: InputDecoration(
                                            labelText: l.fullName,
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                          validator: (value) =>
                                              (value?.trim().length ?? 0) < 2 ||
                                                  value!.trim().length > 100
                                              ? l.invalidName
                                              : null,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      TextFormField(
                                        key: const Key('email'),
                                        controller: _email,
                                        enabled: !busy,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textDirection: TextDirection.ltr,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: l.email,
                                          prefixIcon: const Icon(
                                            Icons.mail_outline,
                                          ),
                                        ),
                                        validator: (value) =>
                                            value == null ||
                                                value.trim().length > 254 ||
                                                !RegExp(
                                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                                ).hasMatch(value.trim())
                                            ? l.invalidEmail
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        key: const Key('password'),
                                        controller: _password,
                                        enabled: !busy,
                                        obscureText: _obscure,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        textDirection: TextDirection.ltr,
                                        autofillHints: [
                                          _register
                                              ? AutofillHints.newPassword
                                              : AutofillHints.password,
                                        ],
                                        textInputAction: _register
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        onFieldSubmitted: (_) {
                                          if (!_register) _submit();
                                        },
                                        decoration: InputDecoration(
                                          labelText: l.password,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon: IconButton(
                                            tooltip: _obscure
                                                ? l.showPassword
                                                : l.hidePassword,
                                            onPressed: () => setState(
                                              () => _obscure = !_obscure,
                                            ),
                                            icon: Icon(
                                              _obscure
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return l.requiredField;
                                          }
                                          if (_register &&
                                              (value.length < 8 ||
                                                  utf8.encode(value).length >
                                                      72)) {
                                            return l.invalidPassword;
                                          }
                                          return null;
                                        },
                                      ),
                                      if (_register) ...[
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          key: const Key('confirm'),
                                          controller: _confirm,
                                          enabled: !busy,
                                          obscureText: _obscureConfirm,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          textDirection: TextDirection.ltr,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: l.confirmPassword,
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                            suffixIcon: IconButton(
                                              tooltip: _obscureConfirm
                                                  ? l.showPassword
                                                  : l.hidePassword,
                                              onPressed: () => setState(
                                                () => _obscureConfirm =
                                                    !_obscureConfirm,
                                              ),
                                              icon: Icon(
                                                _obscureConfirm
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                              ),
                                            ),
                                          ),
                                          validator: (value) =>
                                              value != _password.text
                                              ? l.passwordMismatch
                                              : null,
                                        ),
                                      ],
                                      if (state.failure != null) ...[
                                        const SizedBox(height: 16),
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            authError(context, state.failure!),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      FilledButton(
                                        key: const Key('submitAuth'),
                                        onPressed: busy ? null : _submit,
                                        child: busy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                _register ? l.signUp : l.signIn,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(_register ? l.haveAccount : l.noAccount),
                                TextButton(
                                  key: const Key('toggleAuth'),
                                  onPressed: busy
                                      ? null
                                      : () {
                                          context
                                              .read<AuthCubit>()
                                              .clearError();
                                          setState(() {
                                            _register = !_register;
                                            _password.clear();
                                            _confirm.clear();
                                          });
                                          _form.currentState?.reset();
                                        },
                                  child: Text(
                                    _register ? l.signIn : l.createAccount,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: busy ? null : widget.onGuest,
                              child: Text(l.continueGuest),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.passwordHelp,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
