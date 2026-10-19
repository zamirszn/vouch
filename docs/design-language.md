# Vouch design language

The interface is built as a direct study of Slava Kornilov's app shots
(Dribbble, GeexArts), then adapted to Vouch's single-promise product. It is not
a Material theme: the app has no `MaterialApp`, `ThemeData`, `ColorScheme`,
Material icon font or Material widget. Everything is drawn with widgets and
`CustomPainter`s in `lib/components/` against tokens in `lib/design/`.

The study stills, frames and videos live in `/design-reference/` on the
designer's machine. That directory is gitignored and never committed; this
document records the conclusions, not the copyrighted material.

## Principles

1. **Atmosphere before chrome.** Each screen sits on a full-bleed gradient
   field with a slow breathing aura, a horizon glow and fine grain. The field
   carries the day's state: pending (indigo/violet), kept (emerald/mint),
   missed (crimson/rose), rest (graphite).
2. **One loud thing.** A single oversized, tightly-tracked headline anchors
   every screen. Supporting copy is small, muted and generous with line height.
3. **Glass, not cards.** Panels use 6–10% white fill, a 1px hairline, a large
   radius (20–36) and a soft glow instead of a drop shadow.
4. **Measured, not decorated.** Numbers are the ornament: dot-matrix digits,
   vertical rulers, mono annotations (`(002) / THE RECORD`), numbered section
   rules. Labels are uppercased Space Mono.
5. **Alive, then quiet.** Entrances stagger in under 700 ms; presses spring;
   values settle. Ambient loops breathe and never compete with content.
   Reduced motion removes movement without removing layout or meaning.

## Tokens

`lib/design/vouch_tokens.dart`

| Token | Values |
|---|---|
| canvas | `#08090B` dark · `#E9E9E7` light |
| ink / muted / faint | `#F6F6F2` / `#A2A5AE` / `#63666F` |
| accent | signal yellow `#E8FF3A` |
| kept / missed / pending | mint `#67F5B5` / coral `#FF5C5C` / violet `#8C7BFF` |
| line / lineStrong | 12% white / 24% white |
| space | 4-based scale, 22 gutter, 48 minimum tap target |
| radii | small 14, medium 20, card 28, large 34, sheet 36, pill 999 |
| durations | fast 180 ms, base 320 ms, slow 600 ms |

`lib/design/vouch_theme.dart` exposes a Material-free `VouchThemeData` through
`VouchScope.of(context)`; `VouchScaffold` re-scopes the active tone per screen.

## Type

`lib/design/vouch_type.dart`

- **Instrument Sans** (variable): display, titles, body. Weights 600–700,
  tight tracking, `height` 0.94–1.0 for headlines.
- **Space Mono**: labels, annotations, timestamps, dot-matrix companions.
- Scale: `hero` 54 (screens use 40–52), `display` 42, `title` 27,
  `cardTitle` 19, `body` 15, `caption` 13, `label` 11.

## Motion

`lib/design/vouch_motion.dart` wraps motor:

| Token | Use |
|---|---|
| `enter` / `enterFast` | staggered section reveals |
| `exit` | dismissals, tab content |
| `press` / `release` | every `Pressable` |
| `value` | counters, rulers, dots |
| `drag` / `scroll` | scroll-linked emphasis |
| `ambient` | breathing aura and glows |
| `spin` | loaders |

`VouchMotion.reduced(context)` returns a static resolver when the platform
requests reduced motion. Looping sequences never settle, so tests pump frames
instead of `pumpAndSettle`.

## Components (`lib/components/`)

`GradientField`, `GlassCard`, `VouchScaffold`, `VouchTopBar` (plus back/close
bars), `VouchNavShell`, `VouchButton`/`CircleAction`, `Pressable`, `VouchField`
(EditableText), `VouchSwitch`, `VouchSheet`/`showVouchPanel`, `VouchDialog`/
`showVouchConfirm`, `VouchToast`, `VouchLoader`, `VouchIcon` (33 painted
glyphs), `DotMatrixNumber`, `VerticalRuler`, `StatTile`/`StatusChip`,
`WeekStrip`, `SectionLabel`, `Reveal`.

Sheets built on the primitives: mark, note editor, day detail, contact, time
wheel and timezone picker. There is no `showModalBottomSheet`,
`showTimePicker`, `SnackBar`, `CircularProgressIndicator`, `TextField` or
`Icons.*` in the app.

## Screen mapping

| Screen | Anchor of the composition |
|---|---|
| Splash | giant `VOUCH` word, mono status line |
| Auth | giant two-line promise, feature panel, pill sign-in |
| Onboarding | two role cards with numbered arrows |
| Create / Join | frosted stacked form panels, mono section rules |
| Waiting | per-character invite tiles, expiry dot, share cluster |
| Schedule | week-strip pattern, large clock card, custom reel picker |
| Today — owner | dot-matrix streak + ruler hero, note, week strip |
| Today — witness | question headline, kept/missed status cards, contact circles |
| History | month heat-map, three stat tiles, recent ledger |
| Settings | OS-like glass rows, appearance pills, demo switch |
| Sheets | bottom dialogs with grab handle, frosted surface, footer actions |

## Verification

- `grep -r "package:flutter/material.dart" lib/` returns nothing.
- `flutter analyze` clean; `flutter test` green.
- `--dart-define=VOUCH_GALLERY=true` renders the component gallery.
- Check both brightness modes, reduced motion, and 360–430 dp widths on a
  physical device.
