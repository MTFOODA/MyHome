import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/app_layout.dart';
import '../../core/config/locale_config.dart';
import '../../core/config/marketplace_strings.dart';
import 'guide_content.dart';
import 'introduction_page.dart';

class InfoPage extends StatelessWidget {
  final bool about;
  const InfoPage({super.key, this.about = false});
  @override
  Widget build(BuildContext context) => AppScaffold(
    scene: about ? ArchitecturalScene.balconies : ArchitecturalScene.courtyard,
    appBar: AppBar(
      title: Text(about ? context.l10n.about : context.l10n.guide),
    ),
    body: SingleChildScrollView(
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
                const SizedBox(height: 24),
                Text(
                  guideText(context, about ? 'about' : 'current'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                if (about)
                  Text(
                    guideText(context, 'aboutBody'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.7),
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const Key('replayIntroduction'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const IntroductionPage(),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(guideText(context, 'replay')),
                ),
                const SizedBox(height: 24),
                for (final entry in [
                  'browse',
                  'list',
                  'documents',
                  'pricing',
                  'connect',
                  'shared',
                  'privacy',
                ].indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GuideExplanation(topic: entry.$2, section: entry.$1),
                  ),
                if (about) ...[
                  Text(
                    words(context, 'dataCredits'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(words(context, 'dataCreditsBody')),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://github.com/open-admin-data/egypt-administrative-divisions',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Open Admin Data · CC BY 4.0'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://creativecommons.org/licenses/by/4.0/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('CC BY 4.0'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
