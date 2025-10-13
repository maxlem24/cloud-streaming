import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/widgets/app_sidebar.dart';
import '/widgets/ui_atoms.dart'; // AnimatedBackdrop

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static const String routeName = 'Profile';
  static const String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _avatarBytes; // web-friendly

  // TODO(you): Remplacer ces valeurs par les données backend/auth (user courant)
  final _username = TextEditingController(text: 'EpicGamer'); // ex: currentUser.username
  final _bio = TextEditingController(text: 'Just streaming for fun 🎮'); // ex: currentUser.bio
  final _liveTitle = TextEditingController(text: 'My Awesome Stream'); // ex: currentUser.liveTitle
  bool _liveNotifs = true; // ex: currentUser.liveNotificationsEnabled

  @override
  void initState() {
    super.initState();
    // TODO(you): Si l'utilisateur n'est pas connecté, rediriger vers /login
    // final isLoggedIn = await AuthService.instance.isLoggedIn();
    // if (!isLoggedIn && mounted) Navigator.of(context).pushReplacementNamed('/login');

    // TODO(you): Charger les infos du profil depuis ton backend (ou provider)
    // final user = await ProfileService.instance.fetchMe();
    // setState(() {
    //   _username.text = user.username;
    //   _bio.text = user.bio ?? '';
    //   _liveTitle.text = user.liveTitle ?? '';
    //   _liveNotifs = user.liveNotificationsEnabled ?? true;
    //   _avatarBytes = await ProfileService.instance.fetchAvatarBytes(user.id); // optionnel
    // });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // IMPORTANT pour Web: récupère bytes
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _avatarBytes = result.files.first.bytes);

      // TODO(you): Uploader l'avatar vers ton backend/storage
      // final file = result.files.first;
      // await ProfileService.instance.uploadAvatar(
      //   bytes: file.bytes!,
      //   filename: file.name,
      //   contentType: file.extension, // ex: 'png'/'jpg'
      // );
      // Optionnel: rafraîchir l'URL de l'avatar après upload.
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    _liveTitle.dispose();
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
                    child: Column(
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
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // ===== Avatar =====
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
                                                ? const Icon(Icons.person_rounded,
                                                size: 64, color: Colors.white70)
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
                                        '@${_username.text}',
                                        style: GoogleFonts.inter(
                                          color: theme.accent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // ===== Champs =====
                                _ProfileInput(
                                  label: 'Username',
                                  controller: _username,
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
                                const SizedBox(height: 18),

                                // ===== Section options (ex: notifications) =====
                                // TODO(you): décommenter/adapter si tu gères des préférences live, etc.
                                // Container(
                                //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                //   decoration: BoxDecoration(
                                //     color: theme.surfaceAlt.withOpacity(.6),
                                //     borderRadius: BorderRadius.circular(10),
                                //     border: BorderSide(color: theme.primary.withOpacity(.2)),
                                //   ).toBoxDecoration(),
                                //   child: Row(
                                //     children: [
                                //       Icon(Icons.notifications_active_rounded, color: theme.primary, size: 22),
                                //       const SizedBox(width: 10),
                                //       Expanded(
                                //         child: Text(
                                //           'Live Notifications',
                                //           style: GoogleFonts.inter(
                                //             color: theme.white,
                                //             fontWeight: FontWeight.w600,
                                //             fontSize: 14,
                                //           ),
                                //         ),
                                //       ),
                                //       Switch(
                                //         activeColor: theme.primary,
                                //         value: _liveNotifs,
                                //         onChanged: (v) => setState(() => _liveNotifs = v),
                                //       ),
                                //     ],
                                //   ),
                                // ),

                                const SizedBox(height: 30),

                                // ===== Save =====
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      // TODO(you): Appeler ton service pour persister le profil
                                      // await ProfileService.instance.updateProfile(
                                      //   username: _username.text.trim(),
                                      //   bio: _bio.text.trim(),
                                      //   liveTitle: _liveTitle.text.trim(),
                                      //   liveNotificationsEnabled: _liveNotifs,
                                      //   avatarBytes: _avatarBytes, // si tu souhaites l'envoyer ici
                                      // );

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: theme.primary.withOpacity(.9),
                                          content: const Text(
                                            'Profile updated successfully!',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.save_rounded, color: Colors.white),
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
                              ],
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
          style: GoogleFonts.inter(color: theme.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.white.withOpacity(.35)),
            filled: true,
            fillColor: theme.bg.withOpacity(.6), // aligné sur tes pages
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
