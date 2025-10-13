import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/widgets/ui_atoms.dart';

/// --- Contrôleur interne : centralise l'état "expanded" de la sidebar ---
class AppSidebarController extends ChangeNotifier {
  AppSidebarController._();
  static final AppSidebarController I = AppSidebarController._();

  bool _expanded = true; // état global en mémoire
  bool get expanded => _expanded;

  void setExpanded(bool v) {
    if (_expanded == v) return;
    _expanded = v;
    notifyListeners();
    // _save(); // <- décommente si tu veux persister (voir bloc SharedPreferences)
  }

  void toggle() => setExpanded(!_expanded);

// === (Optionnel) Persistance avec SharedPreferences ===
// import 'package:shared_preferences/shared_preferences.dart';
// static const _k = 'sidebar_expanded';
// static Future<void> init() async {
//   final p = await SharedPreferences.getInstance();
//   I._expanded = p.getBool(_k) ?? true;
// }
// Future<void> _save() async {
//   final p = await SharedPreferences.getInstance();
//   await p.setBool(_k, _expanded);
// }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentKey,
    this.expanded,            // optionnel : si null, on utilise le contrôleur
    this.onToggleExpanded,    // optionnel : si null, on utilise ctrl.toggle
    this.minWidth = 84,
    this.maxWidth = 260,
  });

  final String currentKey;
  final bool? expanded;
  final VoidCallback? onToggleExpanded;
  final double minWidth;
  final double maxWidth;

  static const _top = <_NavItem>[
    _NavItem('home', Icons.home_rounded, 'Accueil'),
    _NavItem('videos', Icons.video_library_rounded, 'Vidéos'),
    _NavItem('live', Icons.live_tv_rounded, 'Live'),
    _NavItem('go_live', Icons.podcasts_rounded, 'Go Live'),
  ];
  static const _bottom = <_NavItem>[
    _NavItem('settings', Icons.settings_rounded, 'Paramètres'),
    _NavItem('profile', Icons.person_rounded, 'Profile'),
  ];

  void _navigate(BuildContext context, String key) {
    String? route;
    switch (key) {
      case 'home':
        route = '/catalogue';
        break;
      case 'videos':
        route = '/videos';
        break;
      case 'live':
        route = '/lives';
        break;
      case 'go_live':
        route = '/go-live'; // TODO
        break;
      case 'settings':
        route = '/settings'; // TODO
        break;
      case 'profile':
        route = '/profile';
        break;
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (route != null && current != route) {
      if (route == '/catalogue') {
        // Catalogue = racine, on vide la pile
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
      } else {
        Navigator.of(context).pushNamed(route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ctrl = AppSidebarController.I;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final bool isExpanded = expanded ?? ctrl.expanded; // non-null
        final double width =
        (isExpanded ? maxWidth : minWidth).clamp(68, 420).toDouble();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: const SizedBox.expand(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.bgSoft, theme.bg],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withOpacity(.10),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.35),
                      blurRadius: 24,
                      offset: const Offset(6, 0),
                    )
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isExpanded ? 12 : 8,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 12 : 6,
                        ),
                        child: _Header(
                          expanded: isExpanded,
                          titleStyle: theme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                          ),
                          onToggleExpanded:
                          onToggleExpanded ?? ctrl.toggle, // FIX
                        ),
                      ),
                      SizedBox(height: isExpanded ? 12 : 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 8 : 4,
                          ),
                          children: [
                            if (isExpanded)
                              const _SectionLabel(text: 'Parcourir'),
                            for (final it in _top)
                              _SidebarItem(
                                item: it,
                                expanded: isExpanded,
                                selected: it.key == currentKey,
                                accent: theme.primary,
                                onTap: () => _navigate(context, it.key),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 8 : 4,
                        ),
                        child: Divider(
                          height: isExpanded ? 14 : 10,
                          thickness: 1,
                          color: Colors.white.withOpacity(.08),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 8 : 4,
                        ),
                        child: Column(
                          children: [
                            if (isExpanded)
                              const _SectionLabel(text: 'Compte'),
                            for (final it in _bottom)
                              _SidebarItem(
                                item: it,
                                expanded: isExpanded,
                                selected: it.key == currentKey,
                                accent: theme.primary,
                                onTap: () => _navigate(context, it.key),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.expanded,
    required this.titleStyle,
    required this.onToggleExpanded,
  });

  final bool expanded;
  final TextStyle titleStyle;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return GlassBar(
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (expanded)
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Image.asset(
                      'assets/images/twinsa_logo_bg.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "TW'INSA",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const Spacer(),
            InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.0,
          color: Colors.white.withOpacity(.45),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _NavItem item;
  final bool expanded;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withOpacity(.82);
    final bgHover = Colors.white.withOpacity(.06);
    final bgSelected = Colors.white.withOpacity(.10);

    final row = Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.selected ? 3 : 0,
          height: double.infinity,
          margin: EdgeInsets.only(
            left: widget.expanded ? 2 : 0,
            right: widget.expanded ? 10 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: widget.selected
                ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.accent, widget.accent.withOpacity(.35)],
            )
                : null,
          ),
        ),
        Flexible(
          flex: widget.expanded ? 0 : 1,
          child: Align(
            alignment:
            widget.expanded ? Alignment.centerLeft : Alignment.center,
            child: Icon(
              widget.item.icon,
              size: 20,
              color: widget.selected ? widget.accent : base,
            ),
          ),
        ),
        if (widget.expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.selected ? widget.accent : base,
                fontWeight:
                widget.selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: .1,
              ),
            ),
          ),
        ],
      ],
    );

    final itemCore = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: widget.expanded ? 44 : 40,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 0 : 2),
      decoration: BoxDecoration(
        color: widget.selected
            ? bgSelected
            : (_hover ? bgHover : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: row,
    );

    final clickable = InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.white.withOpacity(.08),
      highlightColor: Colors.transparent,
      child: itemCore,
    );

    final withHover = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: clickable,
    );

    return widget.expanded
        ? withHover
        : Tooltip(
      message: widget.item.label,
      waitDuration: const Duration(milliseconds: 350),
      child: withHover,
    );
  }
}

class _NavItem {
  const _NavItem(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
}
