# Bundled Google Fonts

Offline copies of the typefaces used by `AppTheme` / `GoogleFonts.*`
(`Inter`, `Merriweather`). Filenames must match google_fonts API prefixes
(e.g. `Inter-Regular.ttf`, `Merriweather-Italic.ttf`) so
`package:google_fonts` prefers these assets over HTTP.

Runtime fetching is disabled in `lib/main.dart` via
`configureBundledGoogleFonts()` to prevent FLUTTER-8-style crashes when
DNS/network to `fonts.gstatic.com` fails.

Licenses: `OFL-Inter.txt`, `OFL-Merriweather.txt` (SIL OFL 1.1).
