import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/vault_themes.dart';

/// Persisted settings + stats for Code Breaker. Survives app restarts.
///
/// Stores: audio toggles, renameable player names (2 slots: detective +
/// partner/code-maker), difficulty tier, theme/appearance choices (incl.
/// custom theme colors), Pro unlock state, and lifetime stats.
///
/// Player names live in ONE JSON string — NEVER setStringList (Android's
/// SharedPreferences stores StringLists as an unordered StringSet and would
/// scramble name order on every restart). A legacy list key is migrated once.
class VaultSettings extends ChangeNotifier {
  static const _kMusic = 'cb_music_on';
  static const _kSfx = 'cb_sfx_on';
  static const _kVolume = 'cb_volume';
  static const _kNamesLegacy = 'cb_player_names'; // legacy unordered key
  static const _kNamesOldJson =
      'cb_player_names_json'; // prior working-tree key (unshipped)
  /// Order-safe player-name storage: ONE JSON string, setString only.
  static const _kNamesJson = 'codebreaker_player_names_json';
  static const _kDifficulty = 'cb_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kTheme = 'cb_theme_id';
  static const _kPegStyle = 'cb_peg_style';
  static const _kWins = 'cb_wins';
  static const _kGames = 'cb_games_played';
  static const _kBestTries = 'cb_best_tries';
  static const _kStreak = 'cb_streak';
  static const _kDailyDate = 'cb_daily_date'; // 'yyyy-MM-dd' of last daily
  static const _kDailyWon = 'cb_daily_won';
  static const _kIsPro = 'cb_is_pro';
  static const _kSeed = 'cb_seed'; // custom challenge seed
  static const _kCustomPrefix = 'cb_custom_';

  static const defaultNames = ['Detective', 'Partner'];
  static const difficultyNames = ['Easy', 'Medium', 'Hard'];
  /// Difficulty tiers: code length / color count / guess rows.
  /// Easy: 4 pegs, 6 colors, 10 rows. Medium: 5 pegs, 7 colors, 12 rows.
  /// Hard: 6 pegs, 8 colors, 14 rows (PRO).
  static const difficultySpecs = [
    [4, 6, 10],
    [5, 7, 12],
    [6, 8, 14],
  ];

  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  List<String> playerNames = List.of(defaultNames);
  int difficulty = 0; // easy default
  String themeId = 'classic';
  int pegStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestTries = 0; // fewest tries to crack (0 = none yet)
  int streak = 0;
  String? dailyDate;
  bool dailyWon = false;
  bool isPro = true; // everything unlocked — no Pro version
  String customSeed = '';

  /// Custom theme colors (ARGB ints). Defaults mirror the Classic Vault.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF3B2416,
    'woodMid': 0xFF5C3A21,
    'woodDeep': 0xFF241309,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF5EFE0,
    'felt': 0xFF1E4D3B,
    'holeDark': 0xFF1C0F06,
    'pc0': 0xFFE5484D,
    'pc1': 0xFFFF9F2E,
    'pc2': 0xFFFFD60A,
    'pc3': 0xFF30D158,
    'pc4': 0xFF0A84FF,
    'pc5': 0xFFBF5AF2,
    'pc6': 0xFFFF6482,
    'pc7': 0xFF64D2FF,
  };

  static const List<String> _pegNameFallback = [
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight'
  ];

  /// Builds the user-designed custom theme from stored colors.
  VaultThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return VaultThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      felt: c('felt'),
      holeDark: c('holeDark'),
      pegColors: [for (int i = 0; i < 8; i++) c('pc$i')],
      pegNames: _pegNameFallback,
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Player names: prefer the order-safe JSON key. One-time migration from
    // any older key (the unshipped working-tree JSON key, then the legacy
    // StringList — Android stores StringLists as an unordered StringSet, so
    // it may already be scrambled; that is exactly the bug this replaces).
    final namesRaw =
        p.getString(_kNamesJson) ?? p.getString(_kNamesOldJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNamesLegacy);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    themeId = p.getString(_kTheme) ?? 'classic';
    pegStyle = (p.getInt(_kPegStyle) ?? 0).clamp(0, PegStyles.names.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestTries = p.getInt(_kBestTries) ?? 0;
    streak = p.getInt(_kStreak) ?? 0;
    dailyDate = p.getString(_kDailyDate);
    dailyWon = p.getBool(_kDailyWon) ?? false;
    isPro = true; // everything unlocked
    customSeed = p.getString(_kSeed) ?? '';
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNamesOldJson); // drop the prior working-tree key
    await p.remove(_kNamesLegacy); // drop the legacy unordered key for good
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kPegStyle, pegStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestTries, bestTries);
    await p.setInt(_kStreak, streak);
    if (dailyDate == null) {
      await p.remove(_kDailyDate);
    } else {
      await p.setString(_kDailyDate, dailyDate!);
    }
    await p.setBool(_kDailyWon, dailyWon);
    await p.setBool(_kIsPro, isPro);
    await p.setString(_kSeed, customSeed);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || VaultThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (PegStyles.isPro(pegStyle)) {
      pegStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    d = d.clamp(0, 2);
    if (!isPro && d > 1) return; // Hard is PRO
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || VaultThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPegStyle(int v) async {
    v = v.clamp(0, PegStyles.names.length - 1);
    if (!isPro && PegStyles.isPro(v)) return;
    pegStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setCustomSeed(String s) async {
    customSeed = s.trim();
    notifyListeners();
    await _save();
  }

  /// Today's daily-challenge key ('yyyy-MM-dd').
  static String todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  bool get dailyDone => dailyDate == todayKey();

  Future<void> recordDaily({required bool won}) async {
    dailyDate = todayKey();
    dailyWon = won;
    await recordGame(humanWon: won, tries: won ? 1 : 0, daily: true);
  }

  /// Record a finished game. [humanWon] true when the cracking side won.
  Future<void> recordGame(
      {required bool humanWon, required int tries, bool daily = false}) async {
    gamesPlayed++;
    if (humanWon) {
      wins++;
      streak++;
      if (!daily && tries > 0 && (bestTries == 0 || tries < bestTries)) {
        bestTries = tries;
      }
    } else {
      streak = 0;
    }
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    wins = 0;
    gamesPlayed = 0;
    bestTries = 0;
    streak = 0;
    notifyListeners();
    await _save();
  }
}
