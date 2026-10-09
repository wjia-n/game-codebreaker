import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/vault_design.dart';
import '../theme/vault_themes.dart';

/// Custom vault creator (PRO): pick every material color + the 8 peg colors.
class CustomThemeScreen extends StatefulWidget {
  final VaultAudio audio;
  final VaultSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  VaultThemeDef get _t => widget.settings.customTheme;

  static const _materialKeys = [
    ('woodDark', 'Deep wood'),
    ('woodMid', 'Mid wood'),
    ('woodDeep', 'Darkest wood'),
    ('accent', 'Brass accent'),
    ('accentLight', 'Bright brass'),
    ('accentDark', 'Dark brass'),
    ('ivory', 'Ivory'),
    ('felt', 'Felt lining'),
    ('holeDark', 'Sockets'),
  ];

  static const _swatches = [
    0xFF3B2416,
    0xFF5C3A21,
    0xFF241309,
    0xFF4A1F14,
    0xFF1C2438,
    0xFF2E3B22,
    0xFFEFE3C8,
    0xFFC9A227,
    0xFFE8CE7A,
    0xFF8A6D1A,
    0xFFD08050,
    0xFFC0C6D4,
    0xFFF5EFE0,
    0xFF2E2118,
    0xFF1E4D3B,
    0xFF3D1F2E,
    0xFFE5484D,
    0xFFFF9F2E,
    0xFFFFD60A,
    0xFF30D158,
    0xFF0A84FF,
    0xFFBF5AF2,
    0xFFFF6482,
    0xFF64D2FF,
    0xFF151312,
    0xFFB08D3E,
    0xFF8A6B48,
    0xFF5C2E3E,
  ];

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
          title:
              Text('My Vault Creator', style: Vault.display(20, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) {
              final theme = s.customTheme;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Column(
                  children: [
                    // Live preview.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          theme.woodMid,
                          theme.woodDeep,
                        ]),
                        border:
                            Border.all(color: theme.accent, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 4; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Peg(
                                color: theme.pegColors[i],
                                style: s.pegStyle,
                                size: 40,
                                theme: theme,
                              ),
                            ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              FeedbackPin(kind: 1, size: 14, theme: theme),
                              const SizedBox(height: 4),
                              FeedbackPin(kind: 2, size: 14, theme: theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    VaultCard(
                      theme: theme,
                      title: 'Materials',
                      child: Column(
                        children: [
                          for (final e in _materialKeys)
                            _ColorRow(
                              theme: theme,
                              label: e.$2,
                              keyName: e.$1,
                              current: s.customColors[e.$1]!,
                              onPick: (v) {
                                widget.audio.click();
                                s.setCustomColor(e.$1, v);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    VaultCard(
                      theme: theme,
                      title: 'Peg Colors',
                      child: Column(
                        children: [
                          for (int i = 0; i < 8; i++)
                            _ColorRow(
                              theme: theme,
                              label: 'Peg ${i + 1}',
                              keyName: 'pc$i',
                              current: s.customColors['pc$i']!,
                              onPick: (v) {
                                widget.audio.click();
                                s.setCustomColor('pc$i', v);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    VaultButton(
                      label: 'Reset to classic',
                      width: 220,
                      fontSize: 15,
                      theme: theme,
                      onTap: () {
                        widget.audio.click();
                        s.resetCustomColors();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final VaultThemeDef theme;
  final String label;
  final String keyName;
  final int current;
  final ValueChanged<int> onPick;
  const _ColorRow({
    required this.theme,
    required this.label,
    required this.keyName,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(current),
                  border: Border.all(
                      color: theme.accentLight, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Vault.body(14, theme: theme)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in _CustomThemeScreenState._swatches)
                GestureDetector(
                  onTap: () => onPick(v),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(v),
                      border: Border.all(
                        color: v == current
                            ? theme.accentLight
                            : Colors.black.withValues(alpha: 0.4),
                        width: v == current ? 3 : 1,
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
