import 'package:flutter/material.dart';

/// Theme catalog for Code Breaker — the Detective's Vault material world.
///
/// Every theme stays physical: real woods, brass/copper/silver, ivory,
/// felt linings and lacquered wooden pegs. Variety comes from different
/// woods, metal accents and jewel-tone peg palettes. No neon anywhere.
class VaultThemeDef {
  final String id;
  final String name;
  final Color woodDark;
  final Color woodMid;
  final Color woodDeep;
  final Color accent; // brass / copper / silver …
  final Color accentLight;
  final Color accentDark;
  final Color ivory;
  final Color felt;
  final Color holeDark; // empty socket color
  final List<Color> pegColors; // 8 lacquer colors
  final List<String> pegNames;

  const VaultThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.felt,
    required this.holeDark,
    required this.pegColors,
    required this.pegNames,
  });
}

class VaultThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'mahogany',
    'midnight',
    'emerald',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static VaultThemeDef byId(String id, {VaultThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all[0];
  }

  static const List<VaultThemeDef> all = [
    VaultThemeDef(
      id: 'classic',
      name: 'Classic Vault',
      woodDark: Color(0xFF3B2416),
      woodMid: Color(0xFF5C3A21),
      woodDeep: Color(0xFF241309),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      felt: Color(0xFF1E4D3B),
      holeDark: Color(0xFF1C0F06),
      pegColors: [
        Color(0xFFE5484D),
        Color(0xFFFF9F2E),
        Color(0xFFFFD60A),
        Color(0xFF30D158),
        Color(0xFF0A84FF),
        Color(0xFFBF5AF2),
        Color(0xFFFF6482),
        Color(0xFF64D2FF),
      ],
      pegNames: [
        'Ruby',
        'Amber',
        'Gold',
        'Jade',
        'Sapphire',
        'Violet',
        'Rose',
        'Lagoon'
      ],
    ),
    VaultThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      woodDark: Color(0xFF4A1F14),
      woodMid: Color(0xFF6E2F1C),
      woodDeep: Color(0xFF2B1009),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF8F1E2),
      felt: Color(0xFF3D1F2E),
      holeDark: Color(0xFF220C05),
      pegColors: [
        Color(0xFFC0392B),
        Color(0xFFD35400),
        Color(0xFFF1C40F),
        Color(0xFF1E8449),
        Color(0xFF2980B9),
        Color(0xFF7D3C98),
        Color(0xFFE84393),
        Color(0xFF16A085),
      ],
      pegNames: [
        'Garnet',
        'Ember',
        'Candle',
        'Fern',
        'Steel',
        'Amethyst',
        'Blush',
        'Seafoam'
      ],
    ),
    VaultThemeDef(
      id: 'midnight',
      name: 'Midnight Den',
      woodDark: Color(0xFF1C2438),
      woodMid: Color(0xFF2C3A55),
      woodDeep: Color(0xFF101624),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2EEE4),
      felt: Color(0xFF1B2A4A),
      holeDark: Color(0xFF0A0E1A),
      pegColors: [
        Color(0xFFD64545),
        Color(0xFFE67E22),
        Color(0xFFF7DC6F),
        Color(0xFF3FB97F),
        Color(0xFF4A90D9),
        Color(0xFF9B59B6),
        Color(0xFFEC87BF),
        Color(0xFF5DADE2),
      ],
      pegNames: [
        'Lantern',
        'Torch',
        'Moon',
        'Moss',
        'Tide',
        'Dusk',
        'Petal',
        'Glacier'
      ],
    ),
    VaultThemeDef(
      id: 'emerald',
      name: 'Emerald Study',
      woodDark: Color(0xFF2E3B22),
      woodMid: Color(0xFF4A5A34),
      woodDeep: Color(0xFF1A2312),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      felt: Color(0xFF0F3D2E),
      holeDark: Color(0xFF121A0C),
      pegColors: [
        Color(0xFFB03A2E),
        Color(0xFFCA6F1E),
        Color(0xFFD4AC0D),
        Color(0xFF229954),
        Color(0xFF2E86C1),
        Color(0xFF8E44AD),
        Color(0xFFD988BC),
        Color(0xFF48C9B0),
      ],
      pegNames: [
        'Claret',
        'Copper',
        'Ochre',
        'Clover',
        'River',
        'Plum',
        'Orchid',
        'Mint'
      ],
    ),
    VaultThemeDef(
      id: 'ivory',
      name: 'Ivory Hall',
      woodDark: Color(0xFFEFE3C8),
      woodMid: Color(0xFFE2D0A6),
      woodDeep: Color(0xFFC9B586),
      accent: Color(0xFF9A7B1E),
      accentLight: Color(0xFFD4AF37),
      accentDark: Color(0xFF6E5514),
      ivory: Color(0xFF2E2118),
      felt: Color(0xFF2E5A44),
      holeDark: Color(0xFFB89E6E),
      pegColors: [
        Color(0xFFA31621),
        Color(0xFFB5541A),
        Color(0xFFC9A227),
        Color(0xFF1B7A4D),
        Color(0xFF1D4E9E),
        Color(0xFF6C3483),
        Color(0xFFB03A5B),
        Color(0xFF2E86AB),
      ],
      pegNames: [
        'Seal',
        'Saddle',
        'Medal',
        'Laurel',
        'Ink',
        'Fig',
        'Wine',
        'Harbor'
      ],
    ),
    VaultThemeDef(
      id: 'cherry',
      name: 'Cherrywood Parlor',
      woodDark: Color(0xFF54271C),
      woodMid: Color(0xFF7A3B26),
      woodDeep: Color(0xFF331209),
      accent: Color(0xFFC98A2B),
      accentLight: Color(0xFFF0C87E),
      accentDark: Color(0xFF8A5A16),
      ivory: Color(0xFFF8EFE0),
      felt: Color(0xFF4A2430),
      holeDark: Color(0xFF280D04),
      pegColors: [
        Color(0xFFE74C3C),
        Color(0xFFF39C12),
        Color(0xFFF9E04B),
        Color(0xFF27AE60),
        Color(0xFF3498DB),
        Color(0xFF8E44AD),
        Color(0xFFFF6B9D),
        Color(0xFF1ABC9C),
      ],
      pegNames: [
        'Cherry',
        'Honey',
        'Straw',
        'Apple',
        'Sky',
        'Grape',
        'Candy',
        'Pond'
      ],
    ),
    VaultThemeDef(
      id: 'copper',
      name: 'Copper Workshop',
      woodDark: Color(0xFF3A2A1E),
      woodMid: Color(0xFF5A4030),
      woodDeep: Color(0xFF241710),
      accent: Color(0xFFD08050),
      accentLight: Color(0xFFF0B88A),
      accentDark: Color(0xFF96562E),
      ivory: Color(0xFFF5ECE0),
      felt: Color(0xFF26343A),
      holeDark: Color(0xFF1B110A),
      pegColors: [
        Color(0xFFD35400),
        Color(0xFFE67E22),
        Color(0xFFF1C40F),
        Color(0xFF16A085),
        Color(0xFF2980B9),
        Color(0xFF8E44AD),
        Color(0xFFE84393),
        Color(0xFF2ECC71),
      ],
      pegNames: [
        'Rust',
        'Bronze',
        'Ingot',
        'Patina',
        'Rivet',
        'Anvil',
        'Bloom',
        'Flux'
      ],
    ),
    VaultThemeDef(
      id: 'sandstone',
      name: 'Sandstone Casbah',
      woodDark: Color(0xFF8A6B48),
      woodMid: Color(0xFFA8875E),
      woodDeep: Color(0xFF6B4F33),
      accent: Color(0xFF7A4E1E),
      accentLight: Color(0xFFC99A5B),
      accentDark: Color(0xFF54360F),
      ivory: Color(0xFF2E2114),
      felt: Color(0xFF3E5A4C),
      holeDark: Color(0xFF54402A),
      pegColors: [
        Color(0xFFB03A2E),
        Color(0xFFD35400),
        Color(0xFFD4AC0D),
        Color(0xFF1E8449),
        Color(0xFF1A5276),
        Color(0xFF6C3483),
        Color(0xFFA93226),
        Color(0xFF148F77),
      ],
      pegNames: [
        'Dune',
        'Spice',
        'Sun',
        'Oasis',
        'Well',
        'Fig',
        'Henna',
        'Palm'
      ],
    ),
    VaultThemeDef(
      id: 'obsidian',
      name: 'Obsidian Vault',
      woodDark: Color(0xFF151312),
      woodMid: Color(0xFF26221F),
      woodDeep: Color(0xFF0B0A09),
      accent: Color(0xFFB08D3E),
      accentLight: Color(0xFFE3C878),
      accentDark: Color(0xFF7A6128),
      ivory: Color(0xFFF0EADC),
      felt: Color(0xFF2A1F33),
      holeDark: Color(0xFF050505),
      pegColors: [
        Color(0xFFE74C3C),
        Color(0xFFE67E22),
        Color(0xFFF4D03F),
        Color(0xFF2ECC71),
        Color(0xFF5DADE2),
        Color(0xFFAF7AC5),
        Color(0xFFF1948A),
        Color(0xFF76D7C4),
      ],
      pegNames: [
        'Flint',
        'Coal',
        'Spark',
        'Serpent',
        'Frost',
        'Shade',
        'Ember',
        'Mist'
      ],
    ),
    VaultThemeDef(
      id: 'teak',
      name: 'Teak & Leather',
      woodDark: Color(0xFF5C3D1E),
      woodMid: Color(0xFF7A5528),
      woodDeep: Color(0xFF3D2812),
      accent: Color(0xFFA3762E),
      accentLight: Color(0xFFDBB365),
      accentDark: Color(0xFF6E4E18),
      ivory: Color(0xFFF6F0E2),
      felt: Color(0xFF4E2E1E),
      holeDark: Color(0xFF2E1E0C),
      pegColors: [
        Color(0xFFC0392B),
        Color(0xFFCA6F1E),
        Color(0xFFF0C419),
        Color(0xFF229954),
        Color(0xFF2E86C1),
        Color(0xFF7D3C98),
        Color(0xFFD988BC),
        Color(0xFF45B39D),
      ],
      pegNames: [
        'Saddle',
        'Brass',
        'Corn',
        'Sage',
        'Denim',
        'Plum',
        'Lace',
        'Bayou'
      ],
    ),
    VaultThemeDef(
      id: 'rosewood',
      name: 'Rosewood Study',
      woodDark: Color(0xFF3E1E28),
      woodMid: Color(0xFF5C2E3E),
      woodDeep: Color(0xFF281018),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFEFD48A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF7F0E4),
      felt: Color(0xFF24382E),
      holeDark: Color(0xFF1E0C12),
      pegColors: [
        Color(0xFFE74C3C),
        Color(0xFFE67E22),
        Color(0xFFF7DC6F),
        Color(0xFF27AE60),
        Color(0xFF3498DB),
        Color(0xFF9B59B6),
        Color(0xFFEC87BF),
        Color(0xFF1ABC9C),
      ],
      pegNames: [
        'Briar',
        'Tawny',
        'Parchment',
        'Ivy',
        'Lake',
        'Heather',
        'Blossom',
        'Reed'
      ],
    ),
    VaultThemeDef(
      id: 'honey',
      name: 'Honey Oak',
      woodDark: Color(0xFF9A6B34),
      woodMid: Color(0xFFB98644),
      woodDeep: Color(0xFF75511F),
      accent: Color(0xFF5E3F14),
      accentLight: Color(0xFF9A7438),
      accentDark: Color(0xFF402A0B),
      ivory: Color(0xFF2A1D0C),
      felt: Color(0xFF2F4A3A),
      holeDark: Color(0xFF5E3F1A),
      pegColors: [
        Color(0xFFA93226),
        Color(0xFFB5541A),
        Color(0xFFB7950B),
        Color(0xFF1E8449),
        Color(0xFF1A5276),
        Color(0xFF6C3483),
        Color(0xFF922B4C),
        Color(0xFF117A65),
      ],
      pegNames: [
        'Brick',
        'Cider',
        'Wheat',
        'Moss',
        'Slate',
        'Thistle',
        'Mulberry',
        'Pine'
      ],
    ),
  ];
}

/// Peg styles — physical carving/finish variants for the lacquer pegs.
/// First 4 are free; the rest are PRO.
class PegStyles {
  static const names = [
    'Classic',
    'Marble',
    'Gem',
    'Turned Wood',
    'Brass Stud',
    'Pearl',
    'Jade Carved',
    'Obsidian',
  ];
  static bool isPro(int i) => i >= 4;
}
