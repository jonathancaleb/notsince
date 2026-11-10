part of '../onboarding_screen.dart';

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
    // The illustration takes whatever room the text leaves and scales to fit
    // it. When even the text alone does not fit (a short screen, large text,
    // a wordy headline in the pen face) the page scrolls instead of clipping.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: AppType.displayLarge.copyWith(height: 1.1),
                ),
                const SizedBox(height: 14),
                Text(page.body, style: AppType.bodyText),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
                  Text('🍺', style: AppType.glyph(26)),
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
              DoodleIcon(Icons.arrow_forward_rounded,
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
                      Text('🔔', style: AppType.glyph(22)),
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
                        child: DoodleIcon(Icons.check_rounded,
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
                    child: DoodleIcon(Icons.lock_rounded,
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
