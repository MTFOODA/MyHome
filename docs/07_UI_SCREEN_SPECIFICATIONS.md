# Current UI mapping — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
Reviewed the original UI PNG groups plus new regester user type.jpeg, ui .jpeg and splash JPEG references. MyHome retains the petroleum/white/neutral theme; new screens use matching typography, spacing, choice chips and cards.

- Home now opens publicly and shows property cards; all property filters are in an expandable panel so results are visible immediately.
- Top sign-in CTA opens the auth route. Detail/save attempts gate on auth; server policies repeat these checks.
- Role onboarding follows successful first authentication and supports multiple needs with one active mode. Independent student/expatriate identity is retained when also an owner.
- Roommate search tab appears only for active shared-rental seeking. Switching settings removes it immediately.
- Listing flow is a sequence of conditional pages. Every utility/negotiation/elevator answer starts unset; choice chips visibly indicate the selected answer.
- Proof images are private; reviewer screens use authorized binary fetches, required decision reasons and no self-approval.
- AR/EN/RTL, dark/light/system and reduced-motion-aware transitions remain supported. Arabic/Persian digits normalize before numeric validation.
- Current rendered PNGs: artifacts/20261114-{home,login,register,roles,listing,home-dark}-{ar,en}.png. Any visible sample apartment is a preview test fixture only.
- Property cards consume real uploaded photo URLs in the app. No composite reference image is used as a fake listing.
- Group setup and applications exist, but no message/call interface claims functional encryption.
- Real roommate profile search, full chat/call screens and broader original feature screens remain pending.

Original detailed reference notes below are retained; read their former TODO statuses against the latest progress table.

---


# MyHome — UI reference specification
Reference source: original PNGs in UI/. Reviewed: 2026-11-09.

## Shared design and behavior
- Petroleum teal header (#28545D), white cards, pale neutral page background, thin field borders, modest corner radii and readable spacing.
- Labels and actions are generated from paired Arabic/English ARB files. Arabic uses RTL layout; email/password retain LTR content direction.
- Login form has a maximum width of 460px. Other content is centered with bounded widths; home categories use one, two or four columns.
- Forms scroll when the keyboard or a small viewport reduces height. Loading disables duplicate submissions; errors remain readable inline.
- System/light/dark appearance and selected language persist independently of authentication.
- Preserve the MyHome name from the product documents. Do not copy the reference's Room Finder/Student Housing names or fictitious company statistics.
- Native keyboard, assistive technology and all desktop platforms still need device QA.

## 1. login register.png
Reference: teal masthead and centered brand, overlapping white sign-in/registration card, labeled fields, password visibility, primary action, account-mode link and success feedback.
Implemented: login, name/email/password/confirmation registration, safe account-role choice, validation, password visibility, inline localized API errors, busy state, guest entry, authenticated home transition and saved-session recovery.
Not implemented: password recovery, email verification, Google/Facebook identity providers. Social provider buttons are not presented as working integrations.
Evidence: artifacts/login-en.png, login-ar.png, register-en.png and register-ar.png. Registration is intentionally scrollable because role selection adds required content.

## 2. navigation home search.png
Reference: menu/search/sign-in masthead, hero, search/filter panel, featured listings and bottom navigation.
Implemented: app header, drawer, localized hero, housing categories, home/search/favorites/account navigation, guide/about navigation and guest/account states.
Remaining: actual search form, location suggestions, combined filters, listing cards with photography and live featured/results data. Current search/favorites views are empty presentation shells; they make no property API requests.
Do not mark SEARCH-001/002/003 or PROP-005 complete from these shells.

## 3. account profile.png
Reference: account header/avatar, personal details, account preferences, settings and FAQ.
Implemented: authenticated name/email/account role, owner verification status, refresh-from-server action, logout, guest sign-in prompt, persistent language and appearance preferences.
Remaining: avatar upload, name/profile editing, location/phone fields, privacy settings, notification settings and full help/FAQ.

## 4. room mate rooms widget.png
Reference: roommate search/filter panel and roommate cards; property cards; details with photo, price, attributes and contact action; maintenance categories.
Remaining: all functional roommate, property-details and maintenance screens. Use protected profile/contact fields. Show separate identity, property ownership and listing-approval badges only when verified by backend records.
Listing cards must include category, cover photo, price/period, approximate location, dimensions, bedroom/bathroom counts and favorite action. Empty, error/loading and pagination states are required.

## 5. Chat Call.png
Reference: conversation tabs/search/list, private message bubbles and composer, recent calls and call actions.
Remaining: all communication screens and their backend. Never seed invented private conversations or expose unencrypted message content to the server to imitate these references.
Implementation must use an established audited protocol and document key lifecycle and device revocation before CHAT-002 can be complete.

## 6. about us.png
Reference: about header, building imagery, company information, team information and location presentation.
Implemented: a concise localized MyHome introduction.
Remaining: approved organization/team/location content and corresponding imagery. The repository provides no verified business contact details, team identities or statistics; these must not be fabricated.

## 7. user guide.png
Reference: how-it-works steps, housing-type explanations, key feature cards and FAQ sections.
Implemented: a three-step localized guide to discovery, reviewing property information and arranging viewings.
Remaining: category-specific explanations with real supported product behavior, approved FAQs and contextual help linked to implemented features. Do not present illustrative prices from screenshots as current market facts.

## Visual verification
Mobile login, registration, home and guest-account previews are rendered by:
    cd myhome_flutter
    flutter test test/render_previews.dart --no-pub --update-goldens
The renderer currently loads Windows Segoe UI and the local Flutter MaterialIcons font for legible test captures. It is a local preview utility, not a cross-machine golden regression baseline.
Widget tests check RTL/navigation/dark mode at 320, 768 and 1440 logical pixel widths.
