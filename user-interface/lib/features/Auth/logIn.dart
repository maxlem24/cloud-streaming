// lib/logIn.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import 'widgets/auth_shared_widget.dart';
import 'widgets/reset_password.dart';
import 'signIN.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

typedef _HeroPanel = AuthHeroPanel;
typedef _TextField = AuthTextField;
typedef _OrDivider = AuthOrDivider;
typedef _SocialButton = AuthSocialButton;
typedef _SocialIconButton = AuthSocialIconButton;

// ============================
//  LOGIN PAGE
// ============================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _model = LoginModel();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _keepLogged = true;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _model.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/catalogue');
      } else {
        if (!mounted) return;
        _error = "Échec de l'authentification.";
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _error = e.message;
    } catch (e) {
      if (!mounted) return;
      _error = 'Une erreur est survenue. Réessaie.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: _HeroPanel(
              headline: 'Welcome\nback!',
              subhead: 'Jump into your dashboard and\nstart streaming live.',
            ),
          ),
          // Left form
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Login', style: theme.titleLarge),
                              const SizedBox(height: 18),
                              _TextField(
                                controller: _emailController,
                                label: 'Email Address',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Required';
                                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
                                  if (!ok) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _TextField(
                                controller: _passwordController,
                                label: 'Password',
                                obscure: _obscure,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: theme.bodySmall.color,
                                  ),
                                ),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) return 'Required';
                                  if (value.length < 8) return 'At least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _keepLogged,
                                    onChanged: (v) => setState(() => _keepLogged = v ?? false),
                                    side: BorderSide(color: Colors.white.withOpacity(.3)),
                                    fillColor: MaterialStateProperty.all(theme.primary),
                                    checkColor: Colors.white,
                                  ),
                                  Text('Keep me logged in', style: theme.bodySmall),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => showResetPasswordPanel(context),
                                    child: Text(
                                      'Forgot password?',
                                      style: theme.bodySmall.override(color: theme.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_error != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                                ),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FFButtonWidget(
                                    text: _loading ? '...' : 'Log In',
                                    onPressed: _loading ? null : _handleLogin,
                                    options: FFButtonOptions(
                                      height: 35,
                                      padding: const EdgeInsets.symmetric(horizontal: 60),
                                      iconPadding: EdgeInsets.zero,
                                      color: theme.primary,
                                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                        ),
                                      ),
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ", style: theme.bodySmall),
                                  InkWell(
                                    onTap: () => Navigator.of(context).pushReplacementNamed(SignINPage.routePath),
                                    child: Text(
                                      'Create account',
                                      style: theme.bodySmall.override(
                                        color: theme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginModel extends FlutterFlowModel<LoginPage> {}
