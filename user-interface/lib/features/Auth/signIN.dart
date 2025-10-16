// lib/signIN.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import 'widgets/auth_shared_widget.dart';
import 'widgets/terms_privPolicy.dart';
import 'logIn.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

typedef _HeroPanel = AuthHeroPanel;
typedef _TextField = AuthTextField;


// ============================
//   SIGN IN PAGE
// ============================
class SignINPage extends StatefulWidget {
  const SignINPage({super.key});

  static String routeName = 'SignIN';
  static String routePath = '/signin';

  @override
  State<SignINPage> createState() => _SignINPageState();
}

class _SignINPageState extends State<SignINPage> {
  late final _model = SignINModel();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscure = true;
  bool _agree = true;

  bool _loading = false;
  String? _error;

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/catalogue');
      } else {
        if (!mounted) return;
        _error = "Échec de l'inscription.";
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
  void dispose() {
    _model.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: _HeroPanel(
              headline: "Let's Get\nStarted!",
              subhead:
                  "Create your account to go live and\nstart streaming in seconds.",
            ),
          ),
          // Right form card
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  elevation: 0,
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create Account', style: theme.titleLarge),
                              const SizedBox(height: 18),
                              _TextField(
                                controller: _usernameController,
                                label: 'Username',
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              _TextField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _email,
                              ),
                              const SizedBox(height: 12),
                              _TextField(
                                controller: _passwordController,
                                label: 'Password',
                                obscure: _obscure,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 18,
                                      color: theme.bodySmall.color),
                                ),
                                validator: _password,
                              ),
                              const SizedBox(height: 8),
                              FormField<bool>(
                                initialValue: _agree,
                                validator: (v) => (v ?? false) ? null : 'You must accept the Terms to continue',
                                builder: (state) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: state.value ?? false,
                                            onChanged: (v) {
                                              setState(() => _agree = v ?? false);
                                              state.didChange(v ?? false); // <— informe le FormField
                                            },
                                            side: BorderSide(color: theme.primary.withOpacity(.3)),
                                            fillColor: MaterialStateProperty.all(theme.primary),
                                            checkColor: theme.white,
                                          ),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text('I agree with ', style: theme.bodySmall),
                                              InkWell(
                                                onTap: () => showLegalPanel(context).then((_) {
                                                  setState(() => _agree = true);
                                                  state.didChange(true);
                                                }),
                                                child: Text(
                                                  'Terms and Privacy Policy',
                                                  style: theme.bodySmall.override(
                                                    color: theme.primary,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (state.hasError)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 12, top: 6),
                                          child: Text(
                                            state.errorText!,
                                            style: theme.bodySmall.override(color:Theme.of(context).colorScheme.error, ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              FFButtonWidget(
                                text: _loading ? '...' : 'Create account',
                                onPressed: _loading ? null : _handleSignIn,
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
                                  borderSide: BorderSide(color: theme.white.withOpacity(.12)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Already have an account? ",
                                      style: theme.bodySmall),
                                  InkWell(
                                    onTap: () => Navigator.of(context)
                                        .pushReplacementNamed(
                                            LoginPage.routePath),
                                    child: Text('Log in',
                                        style: theme.bodySmall.override(
                                            color: theme.primary,
                                            decoration:
                                                TextDecoration.underline)),
                                  )
                                ],
                              ),
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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _email(String? v) {
    if (_required(v) != null) return 'Required';
    final emailRx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRx.hasMatch(v!.trim()) ? null : 'Enter a valid email';
  }

  String? _password(String? v) =>
      (v != null && v.length >= 8) ? null : 'Min 8 characters';
}

class SignINModel extends FlutterFlowModel<SignINPage> {}
