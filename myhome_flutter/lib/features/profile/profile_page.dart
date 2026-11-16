import '../../core/widgets/app_layout.dart';
import '../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/locale_config.dart';
import '../../core/config/settings_cubit.dart';
import '../auth/presentation/auth_cubit.dart';
import '../auth/presentation/auth_page.dart';
import '../auth/presentation/intents_page.dart';
import '../../core/config/marketplace_strings.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onSignIn;
  const ProfilePage({super.key, required this.onSignIn});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<AuthCubit>().state;
    final account = state.account;
    final busy = state.status == AuthStatus.busy;
    final settings = context.watch<SettingsCubit>().state;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.readingWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (account == null) ...[
                  const AppIcon(Icons.person_outline, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    l.guestTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(l.guestSubtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onSignIn, child: Text(l.signIn)),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const IntentsPage(settings: true),
                            ),
                          ),
                    icon: const AppIcon(Icons.manage_accounts_outlined),
                    label: Text(words(context, 'roles')),
                  ),
                  if (account.activeIntent != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        words(context, account.activeIntent!),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      account.name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    account.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleLabel(context, account.role),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(l.fullName),
                          subtitle: Text(account.name),
                          leading: const AppIcon(Icons.person_outline),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: Text(l.email),
                          subtitle: Text(
                            account.email,
                            textDirection: TextDirection.ltr,
                          ),
                          leading: const AppIcon(Icons.mail_outline),
                        ),
                      ],
                    ),
                  ),
                  if (account.role == 'owner') ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIcon(
                                  account.ownerVerified
                                      ? Icons.verified_outlined
                                      : Icons.shield_outlined,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    account.ownerVerified
                                        ? l.verified
                                        : l.unverified,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(l.verificationNotice),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (state.failure != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          authError(context, state.failure!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => context.read<AuthCubit>().refreshProfile(),
                    icon: const AppIcon(Icons.refresh),
                    label: Text(l.refreshProfile),
                  ),
                ],
                const SizedBox(height: 32),
                Text(l.settings, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const AppIcon(Icons.language_rounded),
                        title: Text(l.language),
                        trailing: TextButton(
                          key: const Key('changeLanguage'),
                          onPressed: () =>
                              context.read<SettingsCubit>().toggleLanguage(),
                          child: Text(
                            settings.locale.languageCode == 'ar'
                                ? 'English'
                                : 'العربية',
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l.appearance),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ThemeMode.values
                                  .map(
                                    (mode) => ChoiceChip(
                                      label: Text(switch (mode) {
                                        ThemeMode.system => l.systemTheme,
                                        ThemeMode.light => l.lightTheme,
                                        ThemeMode.dark => l.darkTheme,
                                      }),
                                      selected: settings.themeMode == mode,
                                      onSelected: (_) => context
                                          .read<SettingsCubit>()
                                          .setTheme(mode),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (account != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('logout'),
                    onPressed: busy
                        ? null
                        : () => context.read<AuthCubit>().logout(),
                    icon: const AppIcon(Icons.logout),
                    label: Text(l.signOut),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
