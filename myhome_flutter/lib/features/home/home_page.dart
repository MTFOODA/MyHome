import '../../core/widgets/app_layout.dart';
import '../../core/config/operator_strings.dart';
import '../sales/domain/sales_repository.dart';
import '../sales/presentation/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/app.dart';
import '../../core/config/locale_config.dart';
import '../../core/config/marketplace_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/app_icon.dart';
import '../auth/presentation/auth_cubit.dart';
import '../profile/profile_page.dart';
import '../properties/domain/property_repository.dart';
import '../properties/presentation/discovery_page.dart';
import '../properties/presentation/property_details_page.dart';
import '../properties/presentation/property_list_page.dart';
import '../properties/presentation/listing_page.dart';
import '../properties/presentation/owner_portfolio_page.dart';
import '../properties/presentation/my_groups_page.dart';
import '../chat/presentation/contact_pages.dart';
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
  AdminDashboardCubit? _dashboard;
  String? _dashboardActor;
  @override
  void dispose() {
    _dashboard?.close();
    super.dispose();
  }

  Future<void> _queue(String key) async {
    final Widget page = key == 'property_reviews'
        ? AdminReviewPage(repository: context.read<PropertyRepository>())
        : key == 'eligibility_reviews'
        ? const EligibilityReviewsPage()
        : const SalesListPage();
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    _dashboard?.load();
  }

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
    final account = context.watch<AuthCubit>().state.account;
    final actor = account?.role == 'admin' ? account!.id : null;
    if (_dashboardActor != actor) {
      _dashboard?.close();
      _dashboard = null;
      _dashboardActor = actor;
      if (actor != null) {
        try {
          _dashboard = AdminDashboardCubit(context.read<SalesRepository>())
            ..start();
        } catch (_) {}
      }
    }
    return StreamBuilder<AdminDashboardState>(
      stream: _dashboard?.stream,
      initialData: _dashboard?.state,
      builder: (context, snapshot) =>
          _shell(context, snapshot.data?.counts ?? const {}),
    );
  }

  Widget _shell(BuildContext context, Map<String, int> counts) {
    final l = context.l10n;
    final auth = context.watch<AuthCubit>().state;
    final account = auth.account;
    final repo = context.read<PropertyRepository>();
    final admin = account?.role == 'admin';
    final tabs = [
      'home',
      if (account?.canFindRoommates ?? false) 'roommates',
      if (!admin) 'favorites',
      'account',
    ];
    final current = tabs.contains(_tab) ? _tab : 'home';
    final labels = {
      'home': admin ? operatorText(context, 'dashboard') : l.home,
      'roommates': words(context, 'roommates'),
      'favorites': l.favorites,
      'account': l.account,
    };
    final icons = {
      'home': admin ? Icons.dashboard_outlined : Icons.home_outlined,
      'roommates': Icons.people_outline,
      'favorites': Icons.favorite_border,
      'account': Icons.person_outline,
    };
    Future<void> select(String tab) async {
      if ((tab == 'favorites') && !await requireSignIn(context)) return;
      if (mounted) setState(() => _tab = tab);
    }

    return AppScaffold(
      scene: current == 'home'
          ? ArchitecturalScene.corner
          : ArchitecturalScene.courtyard,
      onDrawerChanged: (open) {
        if (open) _dashboard?.load();
      },
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
          if (account == null && AppLayout.width(context) < 400)
            IconButton(
              key: const Key('openSignIn'),
              tooltip: l.signIn,
              onPressed: () => requireSignIn(context),
              icon: const AppIcon(Icons.login_rounded),
            )
          else if (account == null)
            TextButton.icon(
              key: const Key('openSignIn'),
              onPressed: () => requireSignIn(context),
              icon: const AppIcon(Icons.login_rounded),
              label: Text(l.signIn),
            ),
          if (account != null)
            IconButton(
              key: const Key('openProfile'),
              tooltip: l.account,
              onPressed: () => select('account'),
              icon: const AppIcon(Icons.account_circle_outlined),
            ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
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
                  leading: ColorSymbol(icons[tab]!),
                  title: Text(labels[tab]!),
                  trailing: admin && tab == 'home'
                      ? ReviewBadge(counts['pending_total'] ?? 0)
                      : null,
                  selected: current == tab,
                  onTap: () {
                    Navigator.pop(context);
                    select(tab);
                  },
                ),
              if (account?.canManageProperties ?? false)
                ListTile(
                  key: const Key('drawerAddProperty'),
                  leading: const FeatureSymbol('home'),
                  title: Text(words(context, 'addProperty')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => ListingPage(repository: repo),
                      ),
                    );
                  },
                ),
              if (account != null && !admin)
                ListTile(
                  key: const Key('drawerManageProperties'),
                  leading: const FeatureSymbol('home'),
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
              if (account != null && !admin)
                ListTile(
                  key: const Key('drawerGroups'),
                  leading: const ColorSymbol(Icons.groups_outlined),
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
                  leading: const ColorSymbol(Icons.handshake_outlined),
                  title: Text(salesText(context, 'deals')),
                  trailing: admin
                      ? ReviewBadge(counts['deal_actions'] ?? 0)
                      : null,
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
                  leading: const ColorSymbol(Icons.receipt_long_outlined),
                  title: Text(salesText(context, 'financeHistory')),
                  trailing: admin
                      ? ReviewBadge(counts['payment_reviews'] ?? 0)
                      : null,
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
                  leading: const ColorSymbol(Icons.manage_accounts_outlined),
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
                  leading: const ColorSymbol(Icons.gavel_outlined),
                  title: Text(salesText(context, 'eligibility')),
                  trailing: admin
                      ? ReviewBadge(counts['eligibility_reviews'] ?? 0)
                      : null,
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
              if (account != null && !admin)
                ListTile(
                  key: const Key('drawerPropertyMessages'),
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(words(context, 'propertyMessages')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactListPage(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const ColorSymbol(Icons.help_outline),
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
                  leading: const ColorSymbol(Icons.fact_check_outlined),
                  title: Text(words(context, 'adminQueue')),
                  trailing: ReviewBadge(counts['property_reviews'] ?? 0),
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
                leading: const ColorSymbol(Icons.info_outline),
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
                  'home' =>
                    admin
                        ? (_dashboard == null
                              ? Center(
                                  child: Text(
                                    operatorText(context, 'dashboardFailed'),
                                  ),
                                )
                              : AdminDashboard(
                                  cubit: _dashboard!,
                                  onQueue: _queue,
                                ))
                        : DiscoveryPage(
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
              icon: const FeatureSymbol('home', size: 34),
              label: Text(words(context, 'addProperty')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexOf(current),
        onDestinationSelected: (index) => select(tabs[index]),
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                key: ValueKey('navigation-$tab'),
                icon: ColorSymbol(icons[tab]!, size: 20),
                label: labels[tab]!,
              ),
            )
            .toList(),
      ),
    );
  }
}
