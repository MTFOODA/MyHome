import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/settings_cubit.dart';
import '../../core/config/locale_config.dart';
import '../../core/widgets/app_layout.dart';
import '../../core/widgets/brand_logo.dart';
import 'guide_content.dart';

class IntroductionGate extends StatefulWidget {
  final Widget child;
  const IntroductionGate({super.key, required this.child});
  @override
  State<IntroductionGate> createState() => _IntroductionGateState();
}

class _IntroductionGateState extends State<IntroductionGate> {
  late bool _done;
  @override
  void initState() {
    super.initState();
    _done =
        context.read<SettingsCubit>().preferences.getBool('intro.v1') ?? false;
  }

  @override
  Widget build(BuildContext context) => _done
      ? widget.child
      : IntroductionPage(
          onFinished: () async {
            await context.read<SettingsCubit>().preferences.setBool(
              'intro.v1',
              true,
            );
            if (mounted) setState(() => _done = true);
          },
        );
}

class IntroductionPage extends StatefulWidget {
  final VoidCallback? onFinished;
  const IntroductionPage({super.key, this.onFinished});
  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final _pages = PageController();
  int _index = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _slide(BuildContext context, String key) => LayoutBuilder(
    builder: (context, box) {
      return SingleChildScrollView(
        key: ValueKey('intro-$key'),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Text(
                  guideText(context, 'welcome'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                if (key == 'browse') const GuidePresenters(height: 260),
                if (key != 'browse')
                  GuideExplanation(
                    topic: key,
                    section: key == 'list' ? 2 : 1,
                    compact: true,
                  ),
                const SizedBox(height: 24),
                if (key == 'browse') ...[
                  Text(
                    guideText(context, key),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    guideText(context, '${key}Body'),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandIcon(size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.l10n.appName, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('skipIntroduction'),
          onPressed: _finish,
          child: Text(guideText(context, 'skip')),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (index) => setState(() => _index = index),
              children: [
                for (final key in ['browse', 'list', 'connect'])
                  _slide(context, key),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.all(4),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 420,
                  child: FilledButton.icon(
                    key: const Key('nextIntroduction'),
                    onPressed: () {
                      if (_index == 2) {
                        _finish();
                      } else {
                        if (MediaQuery.disableAnimationsOf(context)) {
                          _pages.jumpToPage(_index + 1);
                        } else {
                          _pages.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      }
                    },
                    icon: Icon(
                      _index == 2 ? Icons.home_outlined : Icons.arrow_forward,
                    ),
                    label: Text(
                      guideText(context, _index == 2 ? 'start' : 'next'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
