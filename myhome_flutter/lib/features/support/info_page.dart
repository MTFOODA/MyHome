import '../../core/widgets/property_illustration.dart';
import 'package:flutter/material.dart';
import '../../core/config/locale_config.dart';
import '../../core/widgets/brand_logo.dart';

class InfoPage extends StatelessWidget {
  final bool about;
  const InfoPage({super.key, this.about = false});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(about ? l.about : l.guide)),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (about)
                    const BrandWordmark(width: 240)
                  else
                    AppImageIcon(
                      Icons.explore_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  const SizedBox(height: 24),
                  Text(
                    about ? l.tagline : l.guideSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (about)
                    Text(
                      l.aboutBody,
                      style: const TextStyle(fontSize: 16, height: 1.8),
                    )
                  else
                    for (final item in [
                      (Icons.search, l.guideSearch, l.guideSearchBody),
                      (
                        Icons.compare_arrows,
                        l.guideCompare,
                        l.guideCompareBody,
                      ),
                      (
                        Icons.verified_user_outlined,
                        l.guideConnect,
                        l.guideConnectBody,
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppImageIcon(
                                  item.$1,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  item.$2,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.$3,
                                  style: const TextStyle(height: 1.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
