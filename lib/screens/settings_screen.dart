import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/vault_design.dart';
import '../theme/vault_themes.dart';

/// Settings: music/SFX toggles, volume slider, stats reset.
class SettingsScreen extends StatefulWidget {
  final VaultAudio audio;
  final VaultSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VaultThemeDef get _t => VaultThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Vault.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  VaultCard(
                    theme: t,
                    title: 'Sound',
                    child: Column(
                      children: [
                        _SwitchRow(
                          theme: t,
                          label: 'Music',
                          value: s.musicOn,
                          onChanged: (v) {
                            widget.audio.click();
                            s.setMusic(v);
                            widget.audio.configure(
                              musicOn: v,
                              sfxOn: s.sfxOn,
                              volume: s.volume,
                            );
                            if (v) widget.audio.startMenuMusic();
                          },
                        ),
                        _SwitchRow(
                          theme: t,
                          label: 'Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) {
                            s.setSfx(v);
                            widget.audio.configure(
                              musicOn: s.musicOn,
                              sfxOn: v,
                              volume: s.volume,
                            );
                            widget.audio.click();
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.volume_up,
                                color: t.accentLight, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                activeColor: t.accent,
                                inactiveColor:
                                    t.accent.withValues(alpha: 0.3),
                                onChanged: (v) {
                                  s.setVolume(v);
                                  widget.audio.configure(
                                    musicOn: s.musicOn,
                                    sfxOn: s.sfxOn,
                                    volume: v,
                                  );
                                },
                                onChangeEnd: (_) => widget.audio.click(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  VaultCard(
                    theme: t,
                    title: 'Records',
                    child: Column(
                      children: [
                        Text(
                          'Cases: ${s.gamesPlayed}   •   Solved: ${s.wins}\n'
                          'Best: ${s.bestTries > 0 ? '${s.bestTries} tries' : '—'}   •   Streak: ${s.streak}',
                          style: Vault.body(14, theme: t),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        VaultButton(
                          label: 'Reset records',
                          width: 200,
                          fontSize: 15,
                          theme: t,
                          onTap: () {
                            widget.audio.click();
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: t.woodMid,
                                title: Text('Reset records?',
                                    style: Vault.display(20, theme: t)),
                                content: Text(
                                    'Your solved cases and streaks will be cleared.',
                                    style: Vault.body(14, theme: t)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      widget.audio.click();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Keep them',
                                        style: Vault.label(14, theme: t)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      widget.audio.click();
                                      s.resetStats();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Reset',
                                        style: Vault.label(14,
                                            theme: t,
                                            color:
                                                const Color(0xFFE08A8A))),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Vault.label(12, theme: t)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final VaultThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Vault.body(16, theme: theme)),
          ),
          Switch(
            value: value,
            activeThumbColor: theme.accentLight,
            activeTrackColor: theme.accent,
            inactiveThumbColor: theme.ivory.withValues(alpha: 0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
