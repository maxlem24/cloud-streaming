import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';


/// 3 etapes : 1 mail -> 2 code -> 3 autorisation de changement de mot de passe
Future<void> showResetPasswordPanel(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Reset Password',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(anim);
      final media = MediaQuery.of(ctx);
      final width = math.min(460.0, media.size.width * 0.9);
      final topPad = media.padding.top + 24;

      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: offset,
          child: Padding(
            padding: EdgeInsets.only(top: topPad, bottom: 24, right: 24),
            child: SizedBox(width: width, child: const _ResetPasswordPanel()),
          ),
        ),
      );
    },
  );
}

class _ResetPasswordPanel extends StatefulWidget {
  const _ResetPasswordPanel();

  @override
  State<_ResetPasswordPanel> createState() => _ResetPasswordPanelState();
}

class _ResetPasswordPanelState extends State<_ResetPasswordPanel> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _codeC = TextEditingController();
  final _newPwdC = TextEditingController();
  final _confirmPwdC = TextEditingController();

  int _step = 0; // 0=email, 1=code, 2=new pwd, 3=success
  bool _busy = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailC.dispose();
    _codeC.dispose();
    _newPwdC.dispose();
    _confirmPwdC.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _email(String? v) {
    if (_required(v) != null) return 'Required';
    final rx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return rx.hasMatch(v!.trim()) ? null : 'Enter a valid email';
  }
  String? _code(String? v) {
    if (_required(v) != null) return 'Required';
    return (v!.trim().length >= 4) ? null : 'Code must be at least 4 digits';
  }
  String? _pwd(String? v) => (v != null && v.length >= 6) ? null : 'Min 6 characters';

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // TODO: call your backend to send reset code
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _step = 1);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // TODO: verify code server-side
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _step = 2);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // confirm match
    if (_newPwdC.text != _confirmPwdC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // TODO: change password with email + code + new password
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _step = 3);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
              border: Border.all(color: Colors.white.withOpacity(.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _step == 0
                                ? 'Reset Password'
                                : _step == 1
                                ? 'Verify Code'
                                : _step == 2
                                ? 'Set New Password'
                                : 'All set!',
                            style: theme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.close, color: theme.bodySmall.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: Color(0x1FFFFFFF)),
                    const SizedBox(height: 10),

                    // Steps indicators (light)
                    Row(
                      children: [
                        _StepDot(index: 0, active: _step >= 0),
                        _StepDivider(),
                        _StepDot(index: 1, active: _step >= 1),
                        _StepDivider(),
                        _StepDot(index: 2, active: _step >= 2),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content
                    if (_step == 0) ...[
                      _HintText('Enter your account email to receive a verification code.'),
                      const SizedBox(height: 12),
                      _FieldShell(
                        child: TextFormField(
                          controller: _emailC,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: _email,
                          enabled: !_busy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PrimaryRow(
                        busy: _busy,
                        primaryText: 'Send Code',
                        onPrimary: _sendCode,
                      ),
                    ] else if (_step == 1) ...[
                      _HintText('We sent a 6-digit code to ${_emailC.text}.'),
                      const SizedBox(height: 12),
                      _FieldShell(
                        child: TextFormField(
                          controller: _codeC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Verification Code'),
                          validator: _code,
                          enabled: !_busy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PrimaryRow(
                        busy: _busy,
                        primaryText: 'Verify',
                        onPrimary: _verifyCode,
                        secondaryText: 'Resend',
                        onSecondary: _sendCode,
                      ),
                    ] else if (_step == 2) ...[
                      _HintText('Choose a new password for your account.'),
                      const SizedBox(height: 12),
                      _FieldShell(
                        child: TextFormField(
                          controller: _newPwdC,
                          obscureText: _obscure1,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure1 = !_obscure1),
                              icon: Icon(
                                _obscure1 ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: theme.bodySmall.color,
                              ),
                            ),
                          ),
                          validator: _pwd,
                          enabled: !_busy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FieldShell(
                        child: TextFormField(
                          controller: _confirmPwdC,
                          obscureText: _obscure2,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              icon: Icon(
                                _obscure2 ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: theme.bodySmall.color,
                              ),
                            ),
                          ),
                          validator: _pwd,
                          enabled: !_busy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PrimaryRow(
                        busy: _busy,
                        primaryText: 'Change Password',
                        onPrimary: _changePassword,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Icon(Icons.check_circle, size: 48, color: theme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Your password has been updated.\nYou can now log in.',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FFButtonWidget(
                        text: 'Back to Login',
                        onPressed: () => Navigator.of(context).maybePop(),
                        options: FFButtonOptions(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal:60),
                          iconPadding: EdgeInsets.zero,
                          color: theme.primary,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(10),
                          textStyle: theme.titleSmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ————— UI helpers —————

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: child,
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      text,
      style: theme.bodySmall.override(
        color: theme.bodySmall.color!.withOpacity(.85),
      ),
    );
  }
}

class _PrimaryRow extends StatelessWidget {
  const _PrimaryRow({
    required this.busy,
    required this.primaryText,
    required this.onPrimary,
    this.secondaryText,
    this.onSecondary,
  });
  final bool busy;
  final String primaryText;
  final VoidCallback onPrimary;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: FFButtonWidget(
            text: primaryText,
            onPressed: busy ? null : onPrimary,
            options: FFButtonOptions(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal:60),
              iconPadding: EdgeInsets.zero,
              color: theme.primary,
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              textStyle: theme.titleSmall,
            ),
          ),
        ),
        if (secondaryText != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: FFButtonWidget(
              text: secondaryText!,
              onPressed: busy ? null : onSecondary,
              options: FFButtonOptions(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal:60),
                iconPadding: EdgeInsets.zero,
                color: Colors.transparent,
                elevation: 0,
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(.18)),
                textStyle: theme.titleSmall,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active});
  final int index;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? theme.primary : Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Text('${index + 1}',
          style: theme.bodySmall.override(
            color: active ? Colors.white : theme.bodySmall.color,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}

class _StepDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 2, color: Colors.white.withOpacity(0.12)),
    );
  }
}
