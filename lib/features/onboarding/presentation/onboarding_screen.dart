import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sticker.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/wordmark.dart';

/// Four pages, swipeable, then out of the way for good.
///
/// The illustration on each page is built from the app's own shapes â€” the
/// sticker cards, dots and checkmarks you will actually meet â€” rather than
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

class _Page {
  const _Page({
    required this.color,
    required this.headline,
    required this.body,
    required this.art,
  });

  final int color;
  final String headline;
  final String body;
  final _Art art;
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The illustration takes whatever room the text leaves and scales to
          // fit it. A fixed height only works on the phone it was measured on:
          // the same card needs 151dp of a 142dp box on a 360x760 screen, and
          // less again on anything shorter.
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _Illustration(art: page.art, color: page.color),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page.headline,
            style: AppType.counter(30).copyWith(height: 1.15),
          ),
          const SizedBox(height: 14),
          Text(page.body, style: AppType.bodyText),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Built from the app's own components rather than drawn artwork.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.art, required this.color});

  final _Art art;
  final int color;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final accent = ns.crayon(color);

    switch (art) {
      case _Art.count:
        return Center(
          child: Transform.rotate(
            angle: -0.03,
            child: StickerCard(
              color: ns.paper,
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ðŸº', style: AppType.glyph(26)),
                  const SizedBox(height: 4),
                  Text('12', style: AppType.counter(84)),
                  Text('days', style: AppType.subtitle),
                ],
              ),
            ),
          ),
        );

      case _Art.reset:
        // Two cards: the run that ended, and the one that started.
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Opacity(
                  opacity: 0.6,
                  child: StickerCard(
                    color: ns.paper,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('34', style: AppType.counter(44)),
                        Text('kept',
                            style: AppType.muted(ns)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 26, color: ns.ink),
              const SizedBox(width: 6),
              Transform.rotate(
                angle: 0.05,
                child: StickerCard(
                  color: accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('0', style: AppType.counter(52)),
                      Text('again',
                          style: AppType.small),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case _Art.tools:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.04,
                child: StickerCard(
                  color: ns.alarmTint,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ðŸ””', style: AppType.glyph(22)),
                      const SizedBox(width: 12),
                      Text('06:30', style: AppType.counter(34)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Transform.rotate(
                angle: 0.05,
                child: StickerCard(
                  color: ns.noteTag('yellow'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ns.ink,
                          border: Sticker.thinOutline(ns.ink),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 15, color: ns.paper),
                      ),
                      const SizedBox(width: 12),
                      Text('Call the dentist',
                          style: AppType.cardSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case _Art.private:
        return Center(
          child: Transform.rotate(
            angle: 0.02,
            child: StickerCard(
              color: ns.paper,
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      border: Sticker.outline(ns.ink),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded,
                        size: 30, color: ns.ink),
                  ),
                  const SizedBox(height: 14),
                  Text('on this phone',
                      style: AppType.cardLead),
                  const SizedBox(height: 2),
                  Text('and nowhere else',
                      style: AppType.muted(ns)),
                ],
              ),
            ),
          ),
        );
    }
  }
}
