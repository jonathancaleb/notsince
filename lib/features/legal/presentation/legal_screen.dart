import 'package:flutter/material.dart';
import 'package:notsince/core/app_info/app_info.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/features/legal/presentation/legal_text.dart';

/// Renders the policy text.
///
/// Paragraphs whose first line has no sentence-ending punctuation are treated
/// as headings, which keeps the source text plain and editable rather than
/// making the policies a widget tree someone has to hand-edit.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  static Future<void> openPrivacy(BuildContext context) => _open(
        context,
        LegalText.privacyTitle,
        LegalText.privacy,
      );

  static Future<void> openTerms(BuildContext context) => _open(
        context,
        LegalText.termsTitle,
        LegalText.terms,
      );

  static Future<void> _open(BuildContext context, String title, String body) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final blocks = body.trim().split('\n\n');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          for (final block in blocks) ...[
            _Block(text: block.trim()),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 8),
          StickerCard(
            color: ns.tint,
            padding: const EdgeInsets.all(16),
            child: Text(
              '${AppInfo.name} ${AppInfo.version}  ·  ${AppInfo.packageId}',
              style: AppType.muted(ns),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final first = lines.first;
    final isHeading = lines.length > 1 &&
        !first.endsWith('.') &&
        !first.startsWith('•') &&
        first.length < 60;

    if (!isHeading) {
      return Text(text, style: AppType.footnote);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(first, style: AppType.subtitle),
        const SizedBox(height: 6),
        Text(
          lines.skip(1).join('\n'),
          style: AppType.footnote,
        ),
      ],
    );
  }
}
