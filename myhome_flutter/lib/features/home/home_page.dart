import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/app.dart';
import '../../core/config/locale_config.dart';
import '../../core/config/marketplace_strings.dart';
import '../../core/config/settings_cubit.dart';
import '../../core/widgets/brand_logo.dart';
import '../auth/presentation/auth_cubit.dart';
import '../profile/profile_page.dart';
import '../properties/domain/property_repository.dart';
import '../properties/presentation/discovery_page.dart';
import '../properties/presentation/property_details_page.dart';
import '../properties/presentation/property_list_page.dart';
import '../properties/presentation/listing_page.dart';
import '../properties/presentation/owner_portfolio_page.dart';
import '../properties/presentation/my_groups_page.dart';
import '../sales/presentation/sales_pages.dart';
import '../sales/presentation/sales_admin_page.dart';
import '../sales/presentation/sales_strings.dart';
import '../properties/presentation/admin_review_page.dart';
import '../search/search_page.dart';
import '../support/info_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _tab = 'home';
  Future<void> _details(String id) async {
    if (!await requireSignIn(context) || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PropertyDetailsPage(
          id: id,
          repository: context.read<PropertyRepository>(),
        ),
      ),
    );
  }

  Future<void> _save(String id) async {
    if (!await requireSignIn(context) || !mounted) return;
    try {
      await context.read<PropertyRepository>().save(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(words(context, 'saved'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(words(context, 'saveError'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthCubit>().state;
    final account = auth.account;
    final repo = context.read<PropertyRepository>();
    final tabs = [
      'home',
      if (account?.canFindRoommates ?? false) 'roommates',
      'favorites',
      'account',
    ];
    final current = tabs.contains(_tab) ? _tab : 'home';
    final labels = {
      'home': l.home,
      'roommates': words(context, 'roommates'),
      'favorites': l.favorites,
      'account': l.account,
    };
    final icons = {
      'home': Icons.home_outlined,
      'roommates': Icons.people_outline,
      'favorites': Icons.favorite_border,
      'account': Icons.person_outline,
    };
    Future<void> select(String tab) async {
      if ((tab == 'favorites') && !await requireSignIn(context)) return;
      if (mounted) setState(() => _tab = tab);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandIcon(size: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.appName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.language,
            onPressed: () => context.read<SettingsCubit>().toggleLanguage(),
            icon: const Icon(Icons.translate),
          ),
          if (account == null)
            TextButton(
              key: const Key('openSignIn'),
              onPressed: () => requireSignIn(context),
              child: Text(l.signIn),
            ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandIcon(size: 44),
                    const SizedBox(height: 12),
                    Text(
                      l.appName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(l.tagline),
                  ],
                ),
              ),
              for (final tab in tabs)
                ListTile(
                  leading: Icon(icons[tab]),
                  title: Text(labels[tab]!),
                  selected: current == tab,
                  onTap: () {
                    Navigator.pop(context);
                    select(tab);
                  },
                ),
              if (account != null)
                ListTile(
                  leading: const Icon(Icons.add_home_work_outlined),
                  title: Text(words(context, 'manageProperties')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => OwnerPortfolioPage(
                          repository: repo,
                          onDetails: _details,
                        ),
                      ),
                    );
                  },
                ),
              if (account != null)
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(words(context, 'myGroups')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MyGroupsPage(repository: repo),
                      ),
                    );
                  },
                ),
              if (account != null) ...[
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(salesText(context, 'deals')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SalesListPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(salesText(context, 'financeHistory')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const SalesListPage(financialHistory: true),
                      ),
                    );
                  },
                ),
              ],
              if (account?.role == 'admin')
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(salesText(context, 'salesAdmin')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SalesAdminPage(),
                      ),
                    );
                  },
                ),
              if (account?.role == 'admin' ||
                  account?.staffRole == 'document_reviewer')
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(salesText(context, 'eligibility')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const EligibilityReviewsPage(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l.guide),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const InfoPage()),
                  );
                },
              ),
              if (account?.role == 'admin')
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(words(context, 'adminQueue')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AdminReviewPage(repository: repo),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.about),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const InfoPage(about: true),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (auth.status == AuthStatus.restoring)
            const LinearProgressIndicator(),
          if (auth.status == AuthStatus.unavailable)
            MaterialBanner(
              content: Text(l.sessionUnavailable),
              actions: [
                TextButton(
                  onPressed: () => context.read<AuthCubit>().restore(),
                  child: Text(l.retry),
                ),
              ],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(current),
                child: switch (current) {
                  'home' => DiscoveryPage(
                    repository: repo,
                    onDetails: _details,
                    onSave: _save,
                  ),
                  'roommates' => SearchPage(repository: repo),
                  'favorites' => PropertyListPage(
                    repository: repo,
                    onDetails: _details,
                    embedded: true,
                  ),
                  _ => ProfilePage(onSignIn: () => requireSignIn(context)),
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          (account?.canManageProperties ?? false) && current == 'home'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => ListingPage(repository: repo),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(words(context, 'addProperty')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexOf(current),
        onDestinationSelected: (index) => select(tabs[index]),
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(icons[tab]),
                label: labels[tab]!,
              ),
            )
            .toList(),
      ),
    );
  }
}
