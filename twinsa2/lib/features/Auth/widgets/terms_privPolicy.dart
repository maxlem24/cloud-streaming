import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';


Future<void> showLegalPanel(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Terms & Privacy',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(anim);

      final media = MediaQuery.of(ctx);
      final width = math.min(480.0, media.size.width * 0.9);
      final topPad = media.padding.top + 24;

      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: offset,
          child: Padding(
            padding: EdgeInsets.only(top: topPad, bottom: 24, right: 24),
            child: SizedBox(
              width: width,
              child: const _TermsPrivacyPanel(),
            ),
          ),
        ),
      );
    },
  );
}

class _TermsPrivacyPanel extends StatelessWidget {
  const _TermsPrivacyPanel();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Terms & Privacy', style: theme.titleLarge),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close, color: theme.bodySmall.color),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),

                // “Tabs” light
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _ChipPill(label: 'Terms of Service'),
                      _ChipPill(label: 'Privacy Policy'),
                      _ChipPill(label: 'Community Guidelines'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Section(
                          title: '1. Your Account',
                          text:
                          'You are responsible for the activity on your account. '
                              'Use a strong password and keep your credentials safe. '
                              'Streaming content must follow our Community Guidelines.',
                        ),
                        const _Section(
                          title: '2. Content & Licenses',
                          text:
                          'By streaming, you grant us a non-exclusive license to host and transmit your content. '
                              'You must own the rights to what you stream or have permission.',
                        ),
                        const _Section(
                          title: '3. Privacy',
                          text:
                          'We collect minimal data to operate the service (account, usage, device info). '
                              'See the Privacy Policy for details on purposes, retention, and your rights (access, deletion, portability).',
                        ),
                        const _Section(
                          title: '4. Safety & Moderation',
                          text:
                          'We may limit or remove content that violates the law or our policies, including DMCA takedown procedures.',
                        ),
                        const _Section(
                          title: '5. Liability',
                          text:
                          'The service is provided “as is” to the extent permitted by law. '
                              'We are not liable for indirect or consequential damages.',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Last updated: 25 Sep 2025',
                          style: theme.bodySmall.override(
                            color: theme.bodySmall.color!.withOpacity(.7),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // CTA row
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                              child: FFButtonWidget(
                                text: 'Close',
                                onPressed: () => Navigator.of(context).maybePop(),
                                options: FFButtonOptions(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 60),
                                  iconPadding: EdgeInsets.zero,
                                  color: theme.primary,
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(10),
                                  textStyle: theme.titleSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Text(label, style: theme.bodySmall),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.titleMedium),
          const SizedBox(height: 6),
          Text(text, style: theme.bodySmall),
        ],
      ),
    );
  }
}
