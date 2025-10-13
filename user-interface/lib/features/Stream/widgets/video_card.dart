// lib/features/videos/widgets/video_card.dart
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class VideoCard extends StatefulWidget {
  const VideoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.coverUrl,
    this.creatorName,
    this.creatorAvatar,
    this.viewCount,
    this.rating,
    this.onTap,
    this.isLive = false,
  });

  final String title;
  final String subtitle;
  final String coverUrl;
  final String? creatorName;
  final String? creatorAvatar;
  final String? viewCount;
  final String? rating;
  final VoidCallback? onTap;
  final bool isLive;

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with SingleTickerProviderStateMixin {
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
          // Pas de border radius, pas de clip
          // Fond de secours (le temps que l'image charge)
          color: t.surface, // violet nuit profond
          // La taille est imposée par le parent (Grid/AspectRatio). Ici on remplit tout.
          child: Stack(
            fit: StackFit.expand,
            children: [
              // === Image plein cadre ===
              Positioned.fill(
                child: Image.network(
                  widget.coverUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // === Badge LIVE (simple) ===
              if (widget.isLive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _LiveBadgeSimple(),
                ),

              // === Badge Note (simple, haut droite) ===
              if (widget.rating != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: t.white.withOpacity(.85),
                    child: Text(
                      widget.rating!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // === Dégradé bas + textes ===
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xCC000000),
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.7],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Créateur (optionnel)
                      if (widget.creatorName != null)
                        Row(
                          children: [
                            if (widget.creatorAvatar != null)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(widget.creatorAvatar!),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(.30),
                                    width: 1,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.creatorName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.white.withOpacity(.92),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 2),

                      // Sous-titre + vues
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.viewCount != null
                                  ? '${widget.subtitle} • ${widget.viewCount} views'
                                  : widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.white.withOpacity(.75),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // === Overlay discret au survol ===
              if (_hover)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(.18),
                    alignment: Alignment.center,
                    child: Wrap(
                      spacing: 12,
                      children: [
                        _SolidButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Play',
                          onTap: widget.onTap,
                          fg: t.white,
                          bg: t.primary.withOpacity(.9),
                        ),
                        _SolidButton(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          onTap: widget.onTap,
                          fg: t.white,
                          bg: t.accent.withOpacity(.35),
                        ),
                      ],
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

/// Bouton plein (sobre)
class _SolidButton extends StatelessWidget {
  const _SolidButton({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge LIVE très simple (couleur fixe lisible)
class _LiveBadgeSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFFE53935),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
