import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/codebreaker_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/vault_design.dart';
import '../theme/vault_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Detective's Vault edition.
/// Logo, PLAY, mode setup (mode / difficulty / seed), theme picker,
/// renameable players, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final VaultAudio audio;
  final VaultSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();
  CBMode _mode = CBMode.solo;

  VaultSettings get _s => widget.settings;
  VaultThemeDef get _t =>
      VaultThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  /// Mode setup cards call this; defined here so `_ModeCard` can reach it.
  void setMode(CBMode m) {
    if (_mode == m) return;
    setState(() => _mode = m);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Vault.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  Future<void> _share() async {
    widget.audio.click();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Can you crack the vault? Play Code Breaker with me! '
              'https://play.google.com/store/apps/details?id=com.gameswajiha.codebreaker',
        ),
      );
    } catch (_) {}
  }

  String get _modeLabel {
    switch (_mode) {
      case CBMode.solo:
        return 'Solo Case';
      case CBMode.vsBot:
        return 'You Set, Bot Cracks';
      case CBMode.codemaker:
        return '2-Player Code-Maker';
      case CBMode.daily:
        return 'Daily Challenge';
    }
  }

  void _play() {
    widget.audio.gameStart();
    final s = _s;
    final seed = _mode == CBMode.daily
        ? VaultSettings.todayKey().hashCode
        : (s.customSeed.isNotEmpty ? s.customSeed.hashCode : null);
    final cracker = _mode == CBMode.codemaker ? s.playerNames[1] : s.playerNames[0];
    final setter = s.playerNames[0];
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engineFactory: () => CodebreakerEngine(
          mode: _mode,
          difficulty: s.difficulty,
          crackerName: cracker,
          setterName: setter,
          seed: seed,
        ),
        audio: widget.audio,
        settings: s,
        mode: _mode,
        modeLabel: '$_modeLabel • ${VaultSettings.difficultyNames[s.difficulty]}',
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/codebreaker_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Code Breaker', style: Vault.display(44, theme: t)),
                  Text(
                    'THE DETECTIVE\'S VAULT EDITION',
                    style: Vault.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  VaultButton(label: '▶  Open a Case', onTap: _play, theme: t),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: widget.audio,
                          settings: _s,
                          store: _store,
                        ),
                      ));
                    },
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          t.accent.withValues(alpha: 0.9),
                          t.accentDark,
                        ]),
                        border: Border.all(
                            color: t.accentLight, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '☕  Tip Jar',
                        style: Vault.label(17,
                            theme: t, color: t.woodDeep),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _share,
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Cases: ${_s.gamesPlayed}   •   Solved: ${_s.wins}${_s.bestTries > 0 ? '   •   Best: ${_s.bestTries} tries' : ''}${_s.streak > 1 ? '   •   🔥${_s.streak}' : ''}',
                      style: Vault.label(12, theme: t),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, VaultThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.woodMid, t.woodDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Vault.display(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• The vault hides a secret peg code.',
                  '• Pick pegs from the tray, then tap Check.',
                  '• ⚫ = right color, right place.',
                  '• ⚪ = right color, wrong place.',
                  '• Crack it before the rows run out!',
                  '• Daily Challenge: one seeded code per day.',
                  '• You Set, Bot Cracks: hide a code and watch the bot solve it.',
                  '• 2-Player: one player hides, the other cracks.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Vault.body(14, theme: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: VaultButton(
                    label: 'Got it!',
                    width: 180,
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final VaultThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.woodMid, theme.woodDeep],
              ),
              border: Border.all(color: theme.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: theme.accentLight, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Vault.label(12, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: game mode, difficulty tier, custom seed.
class _ModeCard extends StatelessWidget {
  final VaultThemeDef theme;
  const _ModeCard({required this.theme});

  static const modeLabels = {
    CBMode.solo: 'Solo',
    CBMode.vsBot: 'Bot Cracks',
    CBMode.codemaker: '2-Player',
    CBMode.daily: 'Daily',
  };

  Future<void> _goPro(BuildContext context, _MenuScreenState screen) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: screen.widget.audio,
        settings: screen._s,
        store: screen._store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    return VaultCard(
      theme: theme,
      title: 'Case Setup',
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final m in CBMode.values)
                _Chip(
                  theme: theme,
                  label: modeLabels[m]!,
                  selected: screen._mode == m,
                  onTap: () {
                    audio.click();
                    screen.setMode(m);
                  },
                ),
            ],
          ),
          if (screen._mode == CBMode.daily)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.dailyDone
                    ? (s.dailyWon
                        ? '✅ Today\'s vault cracked. Come back tomorrow!'
                        : '❌ Today\'s vault beat you. Tomorrow\'s waits.')
                    : '📅 One seeded code per day — same for everyone.',
                style: Vault.body(13,
                    theme: theme,
                    color: theme.ivory.withValues(alpha: 0.75)),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Difficulty:', style: Vault.body(15, theme: theme)),
              const SizedBox(width: 10),
              for (int d = 0; d < 3; d++)
                _Chip(
                  theme: theme,
                  label:
                      '${d == 2 && !s.isPro ? '🔒 ' : ''}${VaultSettings.difficultyNames[d]}',
                  selected: s.difficulty == d,
                  onTap: () async {
                    audio.click();
                    if (d == 2 && !s.isPro) {
                      await _goPro(context, screen);
                      return;
                    }
                    s.setDifficulty(d);
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            () {
              final spec = VaultSettings.difficultySpecs[s.difficulty];
              return '${spec[0]} pegs • ${spec[1]} colors • ${spec[2]} rows';
            }(),
            style: Vault.label(12, theme: theme),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Seed:', style: Vault.body(14, theme: theme)),
              const SizedBox(width: 10),
              Expanded(
                child: _SeedField(
                  theme: theme,
                  initial: s.customSeed,
                  onDone: (v) => s.setCustomSeed(v),
                ),
              ),
            ],
          ),
          Text(
            'Same seed = same secret. Challenge a friend!',
            style: Vault.body(12,
                theme: theme, color: theme.ivory.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SeedField extends StatefulWidget {
  final VaultThemeDef theme;
  final String initial;
  final ValueChanged<String> onDone;
  const _SeedField(
      {required this.theme, required this.initial, required this.onDone});

  @override
  State<_SeedField> createState() => _SeedFieldState();
}

class _SeedFieldState extends State<_SeedField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: widget.theme.accent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _c,
        style: Vault.body(14, theme: widget.theme),
        maxLength: 24,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'e.g. friday-night',
          hintStyle: Vault.body(13,
              theme: widget.theme,
              color: widget.theme.ivory.withValues(alpha: 0.4)),
        ),
        onSubmitted: widget.onDone,
        onEditingComplete: () => widget.onDone(_c.text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme / appearance picker: 12 themes + custom creator, 8 peg styles.
class _ThemeCard extends StatelessWidget {
  final VaultThemeDef theme;
  const _ThemeCard({required this.theme});

  Future<void> _goPro(BuildContext context, _MenuScreenState screen) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: screen.widget.audio,
        settings: screen._s,
        store: screen._store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    final isPro = s.isPro;
    return VaultCard(
      theme: theme,
      title: 'Vault Style',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final th in VaultThemes.all)
                _ThemeTile(
                  theme: theme,
                  th: th,
                  selected: s.themeId == th.id,
                  locked: VaultThemes.isProTheme(th.id) && !isPro,
                  onTap: () {
                    audio.click();
                    if (VaultThemes.isProTheme(th.id) && !isPro) {
                      _goPro(context, screen);
                      return;
                    }
                    s.setTheme(th.id);
                  },
                ),
              // Custom theme tile (PRO).
              _ThemeTile(
                theme: theme,
                th: s.customTheme,
                selected: s.themeId == 'custom',
                locked: !isPro,
                custom: true,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    _goPro(context, screen);
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: audio,
                      settings: s,
                    ),
                  ));
                },
              ),
            ],
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔒 ${VaultThemes.all.length - VaultThemes.freeThemeIds.length} more vaults in PRO',
                style: Vault.label(12, theme: theme),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Peg style:', style: Vault.body(15, theme: theme)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < PegStyles.names.length; i++)
                _Chip(
                  theme: theme,
                  label:
                      '${PegStyles.isPro(i) && !isPro ? '🔒 ' : ''}${PegStyles.names[i]}',
                  selected: s.pegStyle == i,
                  onTap: () {
                    audio.click();
                    if (PegStyles.isPro(i) && !isPro) {
                      _goPro(context, screen);
                      return;
                    }
                    s.setPegStyle(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final VaultThemeDef theme;
  final VaultThemeDef th;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.th,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: th.woodDeep.withValues(alpha: 0.7),
              border: Border.all(
                color: selected
                    ? th.accentLight
                    : th.accent.withValues(alpha: 0.35),
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in th.pegColors.take(6))
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                              color: th.accentLight, width: 1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  custom ? '🎨 My Creation' : th.name,
                  style: Vault.label(10, theme: th),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (locked)
            Container(
              width: 96,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child: Icon(Icons.lock,
                  color: theme.accentLight, size: 22),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Rename the two player slots (detective + partner/code-maker).
class _NamesCard extends StatelessWidget {
  final VaultThemeDef theme;
  const _NamesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    const labels = ['🕵️ Detective', '🤝 Partner'];
    return VaultCard(
      theme: theme,
      title: 'Player Names',
      child: Column(
        children: [
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(labels[i],
                        style: Vault.body(14, theme: theme)),
                  ),
                  Expanded(
                    child: _NameField(
                      theme: theme,
                      index: i,
                      initial: s.playerNames[i],
                      onSave: (v) => s.setPlayerName(i, v),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'The detective cracks; the partner sets the code in 2-player modes.',
            style: Vault.body(12,
                theme: theme, color: theme.ivory.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Player-name field: saves on EVERY keystroke (order-safe JSON string),
/// commits on keyboard-done AND on focus loss (never just keyboard-done —
/// Android keyboards often dismiss without submitting).
class _NameField extends StatefulWidget {
  final VaultThemeDef theme;
  final int index;
  final String initial;
  final ValueChanged<String> onSave;
  const _NameField(
      {required this.theme,
      required this.index,
      required this.initial,
      required this.onSave});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    _focus.addListener(_onFocus);
  }

  /// Commit the current text when the field loses focus (tab away, tap away,
  /// keyboard dismiss without Done).
  void _onFocus() {
    if (!_focus.hasFocus) widget.onSave(_c.text);
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    // Never fight the user's typing: only sync when the committed value
    // differs from what's on screen.
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    widget.onSave(_c.text); // final commit before the widget goes away
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border:
            Border.all(color: widget.theme.accent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _c,
        focusNode: _focus,
        style: Vault.body(15, theme: widget.theme),
        maxLength: 14,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'Name',
          hintStyle: Vault.body(14,
              theme: widget.theme,
              color: widget.theme.ivory.withValues(alpha: 0.4)),
        ),
        onChanged: widget.onSave, // every keystroke
        onSubmitted: widget.onSave, // keyboard done
        onEditingComplete: () => widget.onSave(_c.text),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar (IAP).
class _SupportCard extends StatelessWidget {
  final VaultThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = screen.widget.audio;
    return VaultCard(
      theme: theme,
      title: 'Support Wajiha',
      child: Column(
        children: [
          Text(
            'Code Breaker is 100% free. If it made you smile, a small tip keeps the vault open!',
            style: Vault.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final tips = [
              store.coffeeProduct,
              store.chocolateProduct,
            ].whereType<ProductDetails>().toList();
            if (!store.storeReady) {
              return Text(
                store.error ?? 'Loading…',
                style: Vault.body(13,
                    theme: theme,
                    color: theme.ivory.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              );
            }
            if (tips.isEmpty) {
              return Text('Tips coming soon.',
                  style: Vault.body(13,
                      theme: theme,
                      color: theme.ivory.withValues(alpha: 0.6)));
            }
            return Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _Chip(
                    theme: theme,
                    label: p.id == StoreService.chocolateId
                        ? '🍫 ${p.price}'
                        : '☕ ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Chip extends StatelessWidget {
  final VaultThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: Vault.label(13,
              theme: theme, color: selected ? theme.woodDeep : theme.ivory),
        ),
      ),
    );
  }
}
