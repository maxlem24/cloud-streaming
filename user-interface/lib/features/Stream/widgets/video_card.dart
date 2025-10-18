import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class VideoCard extends StatefulWidget {
  const VideoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isLive,
    this.creatorName,
    this.uploadDate,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isLive;
  final String? creatorName;
  final String? uploadDate;
  final VoidCallback? onTap;

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.bg,
                t.bgSoft,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hover ? t.primary.withOpacity(.3) : Colors.white.withOpacity(.1),
              width: 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // === Badge LIVE ===
              if (widget.isLive)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: t.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // === Contenu principal ===
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Créateur
                    if (widget.creatorName != null) ...[
                      Text(
                        widget.creatorName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Sous-titre + date
                    Text(
                      widget.uploadDate != null
                          ? '${widget.subtitle} • ${widget.uploadDate}'
                          : widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.white.withOpacity(.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // === Overlay au survol ===
              if (_hover)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isLive ? Icons.play_circle_filled : Icons.play_arrow_rounded,
                            color: t.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isLive ? 'Watch' : 'Play',
                            style: TextStyle(
                              color: t.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
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
    );
  }
}