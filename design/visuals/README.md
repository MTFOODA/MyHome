# Architectural headers and guide poses — v1

Created with the built-in **imagegen** tool for MyHome / بيتي on 2026-11-17. [Exact prompts](visual47-prompts.json) include the architectural photo reference and the existing presenter reference. Images represent decorative fictional architecture, not property listings.

App backgrounds are saved as `myhome_flutter/assets/backgrounds/architecture-{corner,balconies,courtyard}-v1.webp`. The corner follows the supplied photograph's low-angle stone/window geometry and teal sky. Balconies and courtyard are companion compositions. Each is 1536×1024; the three files total about 372 KB.

Four transparent standalone poses are saved under `myhome_flutter/assets/illustrations/guide-{olive-present,olive-phone,blazer-explain,blazer-document}-v1.webp`. Faces/outfits follow `guide-duo-v1.png`; new gestures cover presenting, using the phone, explaining and document review. RGBA transparency is preserved; the four files total about 288 KB. Original generated PNG masters are archived locally in ignored `artifacts/visual47-masters/`, with byte/hash/alpha evidence in `artifacts/visual47-assets-report.json`.

Only the first introduction combines the two characters. Later introduction pages use a single presenter, while guide/About sections alternate the two characters and their poses beside their own explanations. Existing property artwork and the selected logo are preserved.
