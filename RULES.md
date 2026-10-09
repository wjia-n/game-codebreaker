# Code Breaker — Rules of the Vault

## 1. Objective
Crack the vault's secret peg code before the rows run out. In code-maker
modes, the setter's objective is to build a code that survives; the
cracker's objective is to solve it.

## 2. Setup
- A secret code of N pegs is chosen from C colors (N/C per difficulty —
  see §7). Duplicate colors in the code are allowed.
- The cracker sees only empty rows; the secret stays hidden until the game ends.
- Solo/Daily: the vault picks the secret (Daily is seeded from the calendar
  date — everyone gets the same code that day).
- You Set, Bot Cracks: the human picks the secret; the bot cracks it.
- 2-Player Code-Maker: player 1 picks the secret, then passes the device to
  player 2, who cracks it.

## 3. Turn order
- Solo/Daily/2-Player: the cracker builds one guess per row, top row first.
- You Set, Bot Cracks: the bot places one full guess per round, peg by peg,
  with a thinking beat between rounds.

## 4. Legal moves
- Place a peg of any tray color into an empty socket of the active row.
- Tap a placed peg to lift it back out.
- Submit the guess with **Check** only when every socket of the active row
  is filled.

## 5. Illegal moves
- Checking an incomplete row (the button refuses with a warning sound).
- Editing any row other than the active one.
- Editing after the game is over.
- Any input while pegs/pins are animating (input is locked by construction).

## 6. Captures
None. Code Breaker has no capture mechanic: guesses are never removed from
the board, and feedback pins are scoring markers (§8), not captures.

## 7. Special rules
- **Difficulty tiers** — Easy: 4 pegs, 6 colors, 10 rows. Medium: 5 pegs,
  7 colors, 12 rows. Hard: 6 pegs, 8 colors, 14 rows (PRO only).
- **Daily challenge** — the secret is seeded from today's date; every
  player gets the same code that day. One result per day counts.
- **Custom seed** — a human-set seed makes the vault generate the same
  secret on any device, for friendly challenges.
- **Bot pacing** — in You Set, Bot Cracks the bot places its guess peg by
  peg with a thinking beat between rounds; every move is visible, nothing
  auto-resolves silently.
- **Pause & watchdog** — pausing freezes all phase timers and resumes the
  exact phase; a watchdog timer recovers any phase found without a live
  timer, so the game can never freeze mid-animation (see §12).

## 8. Scoring
After each submitted guess the vault reveals one pin per peg, left to right:
- ⚫ **black pin** — right color in the right place.
- ⚪ **white pin** — right color in the wrong place.
- No pin — that color does not occur (unmatched) in the secret.
Pins are placed by peg count, not by position — a pin does NOT mark which peg
it refers to.

Scoring is the standard Mastermind count:
1. Count exact-position matches first (black pins).
2. From the remaining pegs, count color matches irrespective of position
   (white pins), each secret peg consumed at most once.
3. All-blacks (N black pins) = code cracked.

## 9. Winning conditions
- The cracker wins by producing all black pins on any row within the row limit.
- In code-maker modes the setter wins if the cracker exhausts all rows.

## 10. Draw conditions
None — every game ends in a win or a loss.

## 11. AI strategy
- **Easy:** mostly random probes with light use of feedback memory.
- **Medium:** picks a random code consistent with all feedback received.
- **Hard:** minimax-lite — from codes consistent with all feedback, picks the
  guess minimizing the worst-case number of remaining candidates.

## 12. Edge cases
- A guess of all one color is legal and scores correctly.
- If the code space is exhausted by contradictory feedback (impossible under
  correct scoring), the bot falls back to random guesses.
- Pausing freezes all phase timers; resume continues the exact phase.
- Backgrounding pauses audio; it resumes where it left off.
- The watchdog recovers any phase found without a live timer (see §7).

## 13. Test cases
1. `score([0,1,2,3],[0,1,2,3])` → [4,0].
2. `score([3,2,1,0],[0,1,2,3])` → [0,4].
3. `score([0,0,1,1],[0,1,2,3])` → [1,1] (one exact, one misplaced).
4. `score([0,0,0,0],[1,2,3,4])` → [0,0].
5. `score([1,1,2,2],[1,2,1,2])` → [2,2].
6. New game starts in `placing` (solo) or `secretSet` (code-maker modes).
7. `check()` with an incomplete row is ignored.
8. After all-blacks, phase is `over` and `crackerWon` is true.
9. After the last row without all-blacks, phase is `over` and `crackerWon` is false.
10. Bot in vsBot mode always produces a full-length guess.
11. `confirmSecret()` with an incomplete draft is ignored.
12. Player names round-trip through JSON in order (never a StringList).
13. Watchdog: a phase with no live timer always advances or waits for legal
    human input — never freezes.
