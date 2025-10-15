// lib/features/Settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/widgets/app_sidebar.dart';
import '/widgets/ui_atoms.dart';


// TODO(DEVICES): Implémenter la détection des devices
// - Utiliser camera package pour lister les caméras
// - Utiliser flutter_sound ou record package pour les micros
// - Sauvegarder les préférences dans SharedPreferences ou DB


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const String routeName = 'Settings';
  static const String routePath = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // @override
  // void initState() {
  //   super.initState();
  //   _loadAvailableDevices();
  //   _loadUserSettings();
  // }


  String _selectedCamera = 'HD Webcam (Built-in)';
  String _selectedAudioInput = 'Microphone (Default)';
  String _selectedAudioOutput = 'Speakers (Default)';
  String _streamQuality = '1080p';
  bool _enableEchoCancellation = true;
  bool _enableNoiseSuppression = true;
  double _micVolume = 0.8;

  // TODO(API): Remplacer par les devices réels
  final List<String> _availableCameras = [
    'HD Webcam (Built-in)',
    'External USB Camera',
    'Virtual Camera',
  ];

  // TODO(API): Remplacer par les devices audio réels
  final List<String> _availableAudioInputs = [
    'Microphone (Default)',
    'External USB Mic',
    'Headset Microphone',
  ];

  final List<String> _availableAudioOutputs = [
    'Speakers (Default)',
    'Headphones',
    'External Speakers',
  ];

  final List<String> _streamQualities = [
    '720p',
    '1080p',
    '1440p',
    '4K',
  ];

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
              const AppSidebar(currentKey: 'settings'),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stream Settings',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ===== CAMERA SECTION =====
                                _SectionHeader(
                                  icon: Icons.videocam_rounded,
                                  title: 'Camera',
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                                _SettingsCard(
                                  theme: theme,
                                  child: Column(
                                    children: [
                                      _DropdownSetting(
                                        label: 'Camera Device',
                                        value: _selectedCamera,
                                        items: _availableCameras,
                                        onChanged: (val) {
                                          setState(() => _selectedCamera = val!);
                                          // TODO(CAMERA): Appliquer le changement de caméra
                                          // _applyCameraChange(val);
                                        },
                                        theme: theme,
                                      ),
                                      const Divider(height: 24),
                                      _DropdownSetting(
                                        label: 'Stream Quality',
                                        value: _streamQuality,
                                        items: _streamQualities,
                                        onChanged: (val) {
                                          setState(() => _streamQuality = val!);
                                          // TODO(SETTINGS): Sauvegarder dans la DB
                                        },
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 16),
                                      _TestButton(
                                        label: 'Test Camera',
                                        icon: Icons.play_circle_outline,
                                        onPressed: () {
                                          // TODO(CAMERA): Ouvrir preview caméra
                                          _showCameraPreview();
                                        },
                                        theme: theme,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ===== AUDIO INPUT SECTION =====
                                _SectionHeader(
                                  icon: Icons.mic_rounded,
                                  title: 'Audio Input',
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                                _SettingsCard(
                                  theme: theme,
                                  child: Column(
                                    children: [
                                      _DropdownSetting(
                                        label: 'Microphone',
                                        value: _selectedAudioInput,
                                        items: _availableAudioInputs,
                                        onChanged: (val) {
                                          setState(() => _selectedAudioInput = val!);
                                          // TODO(AUDIO): Appliquer le changement de micro
                                        },
                                        theme: theme,
                                      ),
                                      const Divider(height: 24),
                                      _SliderSetting(
                                        label: 'Microphone Volume',
                                        value: _micVolume,
                                        onChanged: (val) {
                                          setState(() => _micVolume = val);
                                          // TODO(AUDIO): Appliquer le changement de volume
                                        },
                                        theme: theme,
                                      ),
                                      const Divider(height: 24),
                                      _SwitchSetting(
                                        label: 'Echo Cancellation',
                                        value: _enableEchoCancellation,
                                        onChanged: (val) {
                                          setState(() => _enableEchoCancellation = val);
                                          // TODO(AUDIO): Appliquer le filtre
                                        },
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 12),
                                      _SwitchSetting(
                                        label: 'Noise Suppression',
                                        value: _enableNoiseSuppression,
                                        onChanged: (val) {
                                          setState(() => _enableNoiseSuppression = val);
                                          // TODO(AUDIO): Appliquer le filtre
                                        },
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 16),
                                      _TestButton(
                                        label: 'Test Microphone',
                                        icon: Icons.graphic_eq_rounded,
                                        onPressed: () {
                                          // TODO(AUDIO): Ouvrir test micro avec visualisation
                                          _showMicTest();
                                        },
                                        theme: theme,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ===== AUDIO OUTPUT SECTION =====
                                _SectionHeader(
                                  icon: Icons.volume_up_rounded,
                                  title: 'Audio Output',
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                                _SettingsCard(
                                  theme: theme,
                                  child: Column(
                                    children: [
                                      _DropdownSetting(
                                        label: 'Output Device',
                                        value: _selectedAudioOutput,
                                        items: _availableAudioOutputs,
                                        onChanged: (val) {
                                          setState(() => _selectedAudioOutput = val!);
                                          // TODO(AUDIO): Appliquer le changement de sortie audio
                                        },
                                        theme: theme,
                                      ),
                                      const SizedBox(height: 16),
                                      _TestButton(
                                        label: 'Test Speakers',
                                        icon: Icons.surround_sound_rounded,
                                        onPressed: () {
                                          // TODO(AUDIO): Jouer un son de test
                                          _playTestSound();
                                        },
                                        theme: theme,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // ===== SAVE BUTTON =====
                                Center(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      // TODO(DATABASE): Sauvegarder tous les paramètres
                                      _saveSettings();
                                    },
                                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                                    label: Text(
                                      'Save Settings',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
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

  // TODO(CAMERA): Implémenter la preview caméra
  void _showCameraPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Preview'),
        content: const Text('TODO: Implement camera preview'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // TODO(AUDIO): Implémenter le test micro avec visualisation
  void _showMicTest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Test'),
        content: const Text('TODO: Implement mic test with audio visualization'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // TODO(AUDIO): Implémenter le test son
  void _playTestSound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Play test sound')),
    );
  }

  // TODO(DATABASE): Sauvegarder tous les paramètres
  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: FlutterFlowTheme.of(context).primary.withOpacity(.9),
        content: const Text(
          'Settings saved successfully!',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ===== WIDGETS RÉUTILISABLES =====

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.interTight(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.white,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.theme,
    required this.child,
  });

  final FlutterFlowTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.bg.withOpacity(.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.withOpacity(.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.accent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.bgSoft,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primary.withOpacity(.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primary.withOpacity(.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primary.withOpacity(.5), width: 1.5),
              ),
            ),
            dropdownColor: theme.bg,
            icon: Icon(Icons.arrow_drop_down, color: theme.primary),
          ),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: theme.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.inter(
                color: theme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.primary.withOpacity(.2),
            thumbColor: theme.primary,
            overlayColor: theme.primary.withOpacity(.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0,
            max: 1,
          ),
        ),
      ],
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  const _SwitchSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.accent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primary,
          activeTrackColor: theme.primary.withOpacity(.5),
        ),
      ],
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primary,
        side: BorderSide(color: theme.primary.withOpacity(.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}