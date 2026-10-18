# Handoff — design pass in progress

Last updated: 2026-10-18

This file is the quick state of the current work so another machine can pick up
without the chat history. Delete it once the pass is finished and merged.

## Where things stand

The app is functionally complete and runs against Firebase. The current job is
a **visual “soul” pass** — the owner asked for a less template-like interface
with a hand-made, editorial, studio-designed character.

Direction now in place:

- **Palette / type** unchanged: indigo `#5B4BFF`, coral `#FF6A55`, lime
  `#C9F27A`, cream `#FFF8F2`, ink `#171520`; Bricolage Grotesque display,
  Manrope body.
- **New primitives in `lib/widgets/soul.dart`:** `Asterisk` (six-spoke doodle,
  optional slow spin), `Squiggle` (hand underline), `DashRule`, `Sticker`
  (rotated label with a hard offset shadow), `InkCard` (crisp border + hard
  printed shadow), `SoulButton` (cream/indigo pill CTA with circled arrow),
  `TopFade` (status-bar fade only after scrolling), `PaperDots` (dot-paper
  background).
- **`lib/widgets/vouch_dock.dart`:** custom floating tab bar replaces
  `NavigationBar` — blurred translucent slab, active tab on a tilted indigo
  tile. The squiggle under the selected label and the icon's hard shadow were
  removed on 2026-10-18 at the owner's request.
- **Scroll fix (2026-10-18):** `TopFade` used to insert its `ShaderMask` only
  after the first scroll notification. That changed the widget tree above the
  `SingleChildScrollView`, so Flutter rebuilt the scroll view and reset its
  offset to 0 — scrolling looked broken on every page. `TopFade` now always
  keeps the `ShaderMask` in the tree and just moves its gradient stop
  (`0.0001` when unscrolled), so the scroll position survives. Verify on device.
- **Editorial screens:** mastheads with asterisk + uppercase eyebrow, numbered
  dashed-rule section headers (`01`, `02`, …), sticker labels, squiggly
  underlines. Home, History, Settings, auth, onboarding, create/join/waiting,
  schedule setup, note and mark sheets were all restyled.
- **Copy diet:** removed filler subtitles/explanations across every screen.
  Test-required strings were preserved (`Today`, `You`, `WITNESSING`,
  `Mark today`, `Witnessed by Amara Okafor.`, `Witness, not judge.`,
  `Demo preview`).

## Verified

- `flutter analyze` — clean.
- `flutter test` — all tests pass, including the demo widget flow that scrolls
  to Settings and back (this flow caught the scroll-reset bug).
- Debug APK built and installed on the owner's physical Redmi Note 10 Pro over
  wireless adb; the owner-home redesign was screenshot-checked.
- `SoulButton` label no longer truncates (label now `Expanded`; arrow pinned
  right). Not yet re-checked on device after the fix.
- Dock shadow/squiggle removal and the scroll fix are in this commit but not
  yet rebuilt on device.

## Open threads (in order)

1. **Rebuild + reinstall debug** and capture the owner home again to confirm the
   CTA fix, the cleaned-up dock, and that pages scroll normally:
   ```bash
   DEV='adb-d5f1bd50-naYOVk._adb-tls-connect._tcp'
   flutter build apk --debug
   adb -s "$DEV" install -r build/app/outputs/flutter-apk/app-debug.apk
   adb -s "$DEV" shell am force-stop com.zamirszn.vouch
   adb -s "$DEV" shell monkey -p com.zamirszn.vouch -c android.intent.category.LAUNCHER 1
   adb -s "$DEV" exec-out screencap -p > /tmp/vouch_home.png
   ```
   MIUI blocks `adb shell input tap` (INJECT_EVENTS SecurityException), so tabs
   cannot be switched by automation. Relaunching resets to Today. To inspect
   History/Settings, temporarily set the initial tab in
   `lib/screens/home_shell.dart`, build, screenshot, then revert.
2. **Check the witness view** (partner home: indigo promise hero card, lime
   “The promise” sticker, “Did X keep it?” panel) and the Settings/History
   screens on device. No automated navigation is available.
3. **Release build + dist refresh** once visual checks pass:
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   cp build/app/outputs/flutter-apk/app-release.apk dist/vouch-1.0.0.apk
   cp build/app/outputs/bundle/release/app-release.aab dist/vouch-1.0.0.aab
   ```
   `dist/` currently holds an older release and is gitignored.
4. **GitHub Actions** — `.github/workflows/build.yml` added with a manual
   `workflow_dispatch` trigger (`target`: both/apk/aab, `demo`: bool). It runs
   analyze + tests, builds, and uploads artifacts. Untested on CI. Signing uses
   the optional `KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS` /
   `KEY_PASSWORD` repo secrets and otherwise falls back to debug signing.

## Constraints

- **Never use an emulator** — verify on the owner's physical phone.
- **Never commit secrets:** `android/key.properties`, `*.jks`, `*.keystore` are
  gitignored. The OAuth client secret and Firebase tokens stay out of git.
- Keep edge-to-edge working (`SystemUiMode.edgeToEdge`, transparent system
  bars, transparent navigation bar contrast).
- Push notable changes to `main` on https://github.com/zamirszn/vouch.
- Web automation (if needed) uses Chrome with the “smith jacob” profile,
  headless/background.

## Useful files

- `lib/widgets/soul.dart` — the design primitives.
- `lib/widgets/vouch_dock.dart` — custom bottom navigation.
- `lib/screens/home_shell.dart` — both role homes, masthead, sections.
- `lib/screens/settings_screen.dart`, `history_screen.dart` — restyled tabs.
- `lib/theme/vouch_theme.dart` — schemes + type scale.
- `README.md` — run, Firebase, signing and CI docs.
