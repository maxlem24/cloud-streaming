// lib/auth_shared_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';


class AuthHeroPanel extends StatelessWidget {
  final String headline;
  final String subhead;
  const AuthHeroPanel({super.key, required this.headline, required this.subhead});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [

        Container(
          decoration:  BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [//Color(0xFF11111A),
                theme.primary,
               theme.bgSoft,
                theme.primary,],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 380,
            height: 520,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/');
                            print("logo Clicked !!");
                          },
                          child: Image.asset(
                            'assets/images/twinsa_logo_bg.png',
                            height: 100,
                            width: 100,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "TW'INSA",
                          style: theme.titleMedium.override(
                            font: GoogleFonts.interTight(fontWeight: FontWeight.w800),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      headline,
                      style: theme.headlineLarge.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.w800),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(subhead, style: theme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      style: theme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.bodySmall,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:  BorderSide(color: theme.primary, width: 1.4),
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: theme.bodySmall),
        ),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const AuthSocialButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FFButtonWidget(
      text: label,
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      options: FFButtonOptions(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        iconPadding: const EdgeInsets.only(right: 8),
        color: Colors.white.withOpacity(.06),
        textStyle: theme.bodyMedium,
        elevation: 0,
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
        iconColor: Colors.white,
      ),
    );
  }
}

class AuthSocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const AuthSocialIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(.12)),
        ),
        padding: const EdgeInsets.all(14),
      ),
    );
  }
}
