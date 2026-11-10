import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/wordmark.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

/// Four pages, swipeable, then out of the way for good.
///
/// The illustration on each page is built from the app's own shapes — the
part 'widgets/onboarding_pages.dart';

/// sticker cards, dots and checkmarks you will actually meet — rather than
/// stock artwork, so onboarding is a preview of the thing rather than an advert
/// for it. No mascot, no character: the brief rules those out and the shapes
/// carry it fine.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_Page>[
    _Page(
      color: 0,
      headline: 'Count the days,\nnot the failures.',
      body: 'Pick something you are stepping away from, and notsince keeps '
          'the tally. That is the whole idea.',
      art: _Art.count,
    ),
    _Page(
      color: 2,
      headline: 'Slipped?\nThe count just restarts.',
      body: 'No red, no streak broken, no telling-off. The run you had moves '
          'into your history and a new one begins.',
      art: _Art.reset,
    ),
    _Page(
      color: 1,
      headline: 'Wake up to it,\nwrite it down.',
      body: 'An alarm that rings through silent, and somewhere to keep the '
          'notes and tasks that go with it.',
      art: _Art.tools,
    ),
    _Page(
      color: 4,
      headline: 'Nothing leaves\nyour phone.',
      body: 'No account, no sync, no analytics. There is no server to send '
          'anything to, so nothing is sent.',
      art: _Art.private,
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    // Deliberately not awaited: leaving onboarding should not wait on a disk
    // write. Hive updates in memory synchronously and persists behind us, so
    // the flag is already true for anything that reads it next.
    ref.read(appPrefsProvider).setOnboarded();
    widget.onDone();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final accent = ns.crayon(_pages[_page].color);

    return Scaffold(
      // The whole page eases to the next card's colour as you swipe, so moving
      // between pages feels like one continuous thing rather than four screens.
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        color: ns.crayonTint(_pages[_page].color),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    // Expanded rather than Spacer: on a 320dp screen the
                    // wordmark and the Skip button together are 1.6dp wider
                    // than the line, so the wordmark has to be the one that
                    // gives.
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Wordmark(fontSize: 24),
                      ),
                    ),
                    if (!_isLast)
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _PageView(page: _pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 28 : 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  i == _page ? accent : ns.paper,
                              border: Sticker.thinOutline(ns.ink),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    StickerButton(
                      color: accent,
                      foreground: ns.ink,
                      onPressed: _next,
                      child: Text(_isLast ? 'Set up my first habit' : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Art { count, reset, tools, private }

