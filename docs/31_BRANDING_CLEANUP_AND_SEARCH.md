# بيتي / MyHome — branding, cleanup and discovery

Logo selection update: proposal 02 is now approved and installed. See [selected-logo implementation](32_SELECTED_LOGO.md); the pending-selection statements below describe the earlier proposal stage.

Updated: 2026-11-14. This increment supersedes references to a preserved NestJS backend in earlier reports. Historical task records remain intact.

## Delivered scope

- Arabic product name: **بيتي**; English: **MyHome**. Flutter title and Arabic copy updated; Android resource labels and iOS localized bundle strings added.
- Capsule search with separate filter control, search/category dropdown and horizontally scrolling listing categories, following the supplied Behance reference layout in the app's teal theme.
- Filter sheet with close control, sort dropdown, full-width listing-type pills, expandable location/price/bedroom/utilities/finishing sections and a persistent Apply footer. Closing discards edits; reset remains local until Apply. Location choices stay dependent on the chosen governorate.
- Text search reaches PostgreSQL through the existing BLoC/repository. It searches title, approximate location and Arabic/English area names; `%`, `_` and backslashes are escaped as literal input. Existing approval/visibility predicates still apply.
- Arabic/Persian numeric input normalization and invalid-range rejection are tested. Removed a shared PageStorage key on section ancestors so expanded text fields cannot restore a boolean as a scroll offset.
- Four separate logo concepts generated with the built-in imagegen tool. [Numbered proposals and exact prompts](../design/branding/README.md). None is installed as the final app icon pending the user's selection.
- README rewritten with bilingual scope, current setup and fixture screenshots. `tools/setup_local.py` creates distinct random credentials and a valid Fernet key without overwriting existing settings.

## Cleanup manifest

Removed the previous `backend/` NestJS tree after FastAPI migration and explicit user authorization, plus the empty `.gitignor/`, generated IDE files, empty Flutter tool folder, unused favorites/comparison placeholder pages, unused failure definitions, redundant DI re-export and its unused empty-home widget.

Retained the original `UI/` references, `MyHome.txt` requirements, historical docs, active tests, all platform runners and the ignored pre-migration database backup. Private `.env` files, uploaded documents, databases, caches, builds, editor settings and signing keys are excluded from publication.

## Verification

- Flutter: 28 tests passed, analyzer clean; includes deferred Apply/discard/reset behavior, submitted/cleared search and Arabic price-range validation.
- FastAPI: 19 real PostgreSQL tests passed, including Arabic/English text search and literal wildcard input; Ruff passed.
- AR/EN light/dark previews rendered and visually inspected; [screenshots](screenshots/).
- Android XML and iOS plist/Xcode localization references checked structurally; macOS/Xcode build still required for iOS.
- Local setup helper checked in a temporary clean directory: valid independent credentials, valid 32-byte Fernet key and exact preservation on repeat execution.
- Docker FastAPI and PostgreSQL healthy after rebuilding the API; database volumes preserved.

Web and Android debug builds passed after the branding/discovery changes. Evidence is recorded in [25_BUILD_TEST_RESULTS.md](25_BUILD_TEST_RESULTS.md). This increment does not complete E2EE messaging/calls, roommate matching or the other pending marketplace features listed in the handoff.

## Publication review

270 staged files (approximately 9.5 MB) were reviewed. No files exceeded 5 MB. Actual local database passwords, JWT/document keys and connection URLs were compared privately against all staged blobs; none matched. Token/private-key patterns and prohibited runtime paths were also absent. The existing GitHub initial commit is retained as the parent; no force push is used.
