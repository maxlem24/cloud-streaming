import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/widgets/app_sidebar.dart';
import '/widgets/ui_atoms.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const String routeName = 'Profile';
  static const String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _avatarBytes;


  final _bio = TextEditingController(text: 'Just streaming for fun 🎮');
  final _liveTitle = TextEditingController(text: 'My Awesome Stream');

  final TextEditingController _emailCtrl = TextEditingController(text: '');
  final TextEditingController _usernameCtrl = TextEditingController(text: '');
  bool _loading = true;
  bool get _isLoggedIn => _email?.isNotEmpty == true;

  String? _email;
  String? _username;


  @override
  void initState() {
    super.initState();
    _hydrateUser();

  }


  Future<void> _hydrateUser() async {
    final user = AuthService.instance.currentUser;
    _email = user?.email;
    _emailCtrl.text = _email ?? '';
    _username = user?.userMetadata?['username'] as String?;
    _usernameCtrl.text = _username ?? '';
    setState(() {
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/catalogue', (r) => false);
  }


  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _avatarBytes = result.files.first.bytes);
    }
  }

  @override
  void dispose() {
    _bio.dispose();
    _liveTitle.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bgSoft,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackdrop(),
          Row(
            children: [
              const AppSidebar(currentKey: 'profile'),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: _loading
                        ? const Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Settings',
                          style: GoogleFonts.interTight(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: theme.white,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // connected
                        if (_isLoggedIn)
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // ===== Avatar + Username =====
                                  Center(
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 60,
                                              backgroundColor: theme.surfaceAlt,
                                              backgroundImage: _avatarBytes != null
                                                  ? MemoryImage(_avatarBytes!)
                                                  : null,
                                              child: _avatarBytes == null
                                                  ? Icon(Icons.person_rounded,
                                                  size: 64, color: theme.white)
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 4,
                                              child: InkWell(
                                                onTap: _pickImage,
                                                borderRadius: BorderRadius.circular(30),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: theme.primary,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.primary.withOpacity(.5),
                                                        blurRadius: 8,
                                                      )
                                                    ],
                                                  ),
                                                  child: Icon(Icons.edit_rounded,
                                                      size: 18, color: theme.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _username!,
                                          style: GoogleFonts.inter(
                                            color: theme.accent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  _ProfileInput(
                                    label: 'Email',
                                    controller: _emailCtrl,
                                    hint: 'Your email',
                                    theme: theme,
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileInput(
                                    label: 'Username',
                                    controller: _usernameCtrl,
                                    hint: 'Your username',
                                    theme: theme,
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileInput(
                                    label: 'Bio',
                                    controller: _bio,
                                    hint: 'Tell something about yourself...',
                                    theme: theme,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileInput(
                                    label: 'Live Title',
                                    controller: _liveTitle,
                                    hint: 'What’s your next stream about?',
                                    theme: theme,
                                  ),

                                  const SizedBox(height: 30),

                                  // ===== Save =====
                                  Align(
                                    alignment: Alignment.center,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                            theme.primary.withOpacity(.9),
                                            content: const Text(
                                              'Profile updated successfully!',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.save_rounded,
                                          color: Colors.white),
                                      label: Text(
                                        'Save Changes',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  Align(
                                    alignment: Alignment.center,
                                    child: OutlinedButton.icon(
                                      onPressed: _logout,
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Se déconnecter'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(.12),
                                        ),
                                        foregroundColor: theme.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // AUTH <<<
                                ],
                              ),
                            ),
                          ),

                        // not connected
                        if (!_isLoggedIn)
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_outline, size: 72),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Pour une expérience personnalisée,\nveuillez vous inscrire ou vous connecter.',
                                      style: GoogleFonts.interTight(
                                        color: theme.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 22),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Log In
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pushNamed(context, '/login'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 6,
                                          ),
                                          child: Text(
                                            'Log In',
                                            style: theme.titleMedium.override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w700,
                                                fontStyle:
                                                theme.titleMedium.fontStyle,
                                              ),
                                              color: theme.bg,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pushNamed(context, '/signin'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 6,
                                          ),
                                          child: Text(
                                            'Create Account',
                                            style: theme.titleMedium.override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w700,
                                                fontStyle:
                                                theme.titleMedium.fontStyle,
                                              ),
                                              color: theme.bg,
                                            ),
                                          ),
                                        ),
                                      ],
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Input réutilisable =====
class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.label,
    required this.controller,
    required this.hint,
    required this.theme,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final FlutterFlowTheme theme;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isReadOnly = label.toLowerCase() == 'email'; // AUTH >>> rendre email non éditable

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            color: theme.accent,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly, // AUTH >>>
          style: GoogleFonts.inter(color: theme.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.white.withOpacity(.35)),
            filled: true,
            fillColor: theme.bg.withOpacity(.6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary.withOpacity(.2), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary.withOpacity(.5), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
