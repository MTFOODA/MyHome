# Feature preservation — 2026-11-09

## Baseline before implementation
- No Git repository was present at the workspace root.
- Flutter contained 15 skeletal source files, invalid imports/localization access, a two-byte pubspec and no tests or platform runners.
- Backend contained incomplete authentication files, an invalid YAML-formatted package.json, no installed test suite and no connected AuthModule.
- No property, messaging, groups, maintenance, media or admin implementation existed.
- Several older documents described these missing features as complete. Those logs are preserved under historical sections, with an authoritative audit at the top.

## Preserved and repaired
- Kept the MyHome product name, original seven UI PNGs, Arabic/English requirement and phase order.
- Kept existing Flutter feature paths and introduced auth domain/data/presentation boundaries.
- Retained the existing TypeORM direction as the single implemented ORM; recorded the difference from the initially planned Prisma stack.
- Preserved home/search/favorites/comparison entry classes while correcting their imports and replacing broken text placeholders with honest localized shells.
- Replaced nonfunctional Passport strategies with injectable Nest Passport strategies.
- No existing database or user data was deleted. Tests use a separately created myhome_test database and delete only email records bearing their own random run prefix.

## Regression evidence
- Nest build and API tests against both pg-mem and isolated PostgreSQL.
- Flutter repository/Cubit/widget tests and analyzer.
- Web compilation and rendered Arabic/English UI previews.
- See 25_BUILD_TEST_RESULTS.md for current native/build/operational results.
