# Selected logo — بيتي / MyHome

The owner selected **proposal 02, the Arabic architectural wordmark**, on 2026-11-14. It supersedes the earlier "awaiting logo selection" status; the other proposals remain as history.

## Installed assets

- [Bilingual wordmark master](../design/branding/selected/wordmark-master.png): teal Arabic بيتي / English MyHome and a gold roof on an opaque white surface.
- [Square icon master](../design/branding/selected/app-icon-master.png): white Arabic lettering and gold roof on teal.
- [Exact final edit prompts](../design/branding/selected/prompts.json), generated using built-in imagegen from the selected original board. An unsatisfactory transparent extraction was discarded; no transparent wordmark is claimed.
- Flutter: `assets/branding/app-icon.png` and `wordmark.png`, declared in pubspec. Shared `BrandIcon` and `BrandWordmark` widgets provide consistent rendering. Wordmark accessibility text follows the selected app language; decorative icons avoid duplicate announcements.

## Application surfaces

Home app bar and drawer use the selected app icon. Authentication and About use the bilingual wordmark. AR/EN and dark/light screenshots are in `docs/screenshots/`.

Android launcher icons include adaptive resources with extra padding; launch backgrounds use the branded launcher. iOS icons and launch-image resolutions, Web favicon/PWA icons, macOS icon assets and the Windows multiresolution ICO use the selected master. The logo artwork itself keeps its reading direction in RTL layouts.

## Reproduction

From the repository root on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/generate_brand_icons.ps1
```

This command uses .NET image resampling to package the masters at required platform sizes; it does not generate new artwork. iOS icon PNGs are opaque RGB. The ICO includes 16/24/32/48/64/128/256-pixel frames. Master files live in the repository, not in user-profile paths.

Validation results and platform limits are recorded in [build results](25_BUILD_TEST_RESULTS.md). macOS/Xcode and physical-device testing are still required for iOS; desktop builds are not claimed by this increment.

The 28-test Flutter suite and analyzer passed. Web and Android debug builds passed. The APK was inspected for both selected Flutter assets and its adaptive launcher resource; the Web output was checked for matching brand assets and metadata. AR/EN light/dark previews were rendered and visually reviewed, including drawer and dark login. A structural check validated 45 native/web icon entries, Apple RGB opacity, ICO frame offsets and Android/iOS XML. The backend is unchanged.
