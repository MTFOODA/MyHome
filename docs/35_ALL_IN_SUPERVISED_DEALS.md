# Approved all-in pricing and supervised transactions — 2026-11-15

This amendment supersedes the preview-only commission proposal and earlier E2EE message requirement. The owner explicitly approved server inspection followed by encryption at rest. Historical documents remain below their current amendments. The marketplace as a whole is still in progress.

## قواعد التسعير المعتمدة

- السعر المعروض شامل حصة المشتري / المستأجر من عمولة المنصة، بلا إضافة عمولة منصة أخرى عند الإتمام.
- يُحفظ السعر المرجعي الأصلي منفصلًا عن السعر الحالي والعرض المقبول. الخصم يغير قيمة العقار وحدها؛ نصيب كل طرف يظل ثابتًا.
- `backend_fastapi/app/financial.py` هو مصدر الحسابات الوحيد؛ Flutter يعرض مبالغ الخادم ولا يعيد حساب النسب.
- العمولة الإجمالية مناصفة بين الطرفين. عند وجود قرش فردي، يُسند فرق القرش لحصة المشتري حتى يطابق مجموع الحصتين الإجمالي تمامًا.
- البيع النقدي والتقسيط: 1% إجمالًا؛ 0.5% لكل طرف. حصة المشتري فقط تضاف إلى السعر المعروض والدفعة المقدمة في عرض التقسيط.

| Transaction | ≤12 months | ≤36 months | >36 months, including 5 years |
|---|---:|---:|---:|
| Private rental, total platform fee | ½ month | ¾ month | 1 month |
| Shared rental, total fee per contracted occupied bed | ¼ month | ⅜ month | ½ month |

Custom contracts shorter than 12 months prorate the annual factor by months/12. Both rental shares are allocated across the specified months. Each monthly share rounds down to piasters; the total equals twice that share times the months. This slightly reduces rounding residues instead of adding an undisclosed final charge. Shared fees are charged per actual bed contract, not for all available beds in advance. Configured area/governorate discounts default to none, never automatic regional surcharges. Existing references do not change when configuration changes.

The rental model assumes fixed monthly base rent; escalating rents, deposits held in escrow, refunds, taxes, registration costs and rent collection are not modeled as platform fees or payment processing. The existing listing records the security deposit separately. The financial ledger implemented here covers the property/rent component and platform fee, not a complete banking or refundable-deposit ledger.

### Mandatory sale example, covered by API tests

| Amount, EGP | Original listing | Accepted discount |
|---|---:|---:|
| Original commission reference | 2,000,000 | 2,000,000 |
| Property component | 2,000,000 | 1,900,000 |
| Buyer fee | 10,000 | 10,000 |
| Seller fee | 10,000 | 10,000 |
| Buyer all-in total | 2,010,000 | 1,910,000 |
| Seller economic net | 1,990,000 | 1,890,000 |
| Platform total | 20,000 | 20,000 |

Once the buyer's 10,000 platform transfer is independently verified, the remaining amount **within** the 1,910,000 total is 1,900,000. The fee is not requested again. The seller's 10,000 transfer is their own share; the economic net remains 1,890,000. Reporting a reference alone is not verification.

Draft category/duration changes before any open deal prepare the corresponding schedule using the same original price; price-only edits preserve the reference. Category/duration changes are blocked while a deal is open; all material edits are blocked for an accepted deal. Quotes for a saved draft include its ID so retrying a submission cannot reset the original reference.

## الإيجار القديم

- 12 شهرًا مرجع لحساب العمولة فقط، وليس مدة العقد القانونية أو تحديدًا لحقوقه.
- العمولة الإجمالية ¾ شهر من الإيجار المرجعي الأصلي، مقسمة مناصفة وثابتة عند الخصم.
- المراجع الداخلي المعيّن يفحص أهلية المعاملة ويربط القرار بمرجع خارجي وملاحظة؛ لا يكفي كون الإعلان موثقًا.
- قبل الأهلية، الأرقام مرجعية وغير ملزمة، والإعلان يوضح انتظار المراجعة. لا تبدأ صفقة مالية ولا يُفعّل الدفع.
- للإيجار الأصلي 10,000: الإجمالي الأول 13,750 يشمل حصة المستأجر 3,750 مرة واحدة. الإيجار التالي 10,000. لا يُعرض مجموع عقد مجهول المدة.
- الخصم إلى 9,000: الدفعة الأولى 12,750 وصافي المؤجر لأول دفعة 5,250، ثم الإيجار الشهري 9,000؛ العمولة لا تنخفض.
- تستطيع الإدارة اقتراح اتفاق عمولة استثنائي مع سبب ومرجع قانوني. يُعرض الإجمالي الجديد والحصتان والمبلغ الشامل قبل الموافقة. لا يطبق إلا بعد موافقة الطرفين على النسخة نفسها.
- سحب الأهلية يمنع الموافقات المالية الجديدة، عرض QR للدفع، طلب تأكيد تحويل وإتمام الصفقة. لا نفترض قابلية كل عقد قديم للوساطة أو نقل الحقوق.

## Supervised workflow and permissions

1. An eligible buyer/tenant opens a deal for an approved available listing. Original price, category, rental term and fixed shares are snapshotted. No owner email, phone or identity number is returned in deal DTOs.
2. Deal/group text conversations are separate and authenticated. Members coordinate inside the app.
3. The buyer requests a future hourly viewing slot; the owner confirms. An administrator assigns an active internal field agent. The assigned agent records attendance when due. References are unique; simultaneous staff/hour bookings are rejected.
4. After attendance, either party submits or counters an **all-in** offer. Only the other party can accept/reject. Acceptance reserves the property or one shared bed with row locking. Concurrent attempts cannot reserve the same last bed.
5. Both parties explicitly accept versioned AR/EN brokerage terms, fixed financial amounts and their digest. Terms, time and evidence hashes are recorded. Changing the financial agreement invalidates mismatched consent.
6. The assigned internal document reviewer accesses only the linked private verification assets, after both consents. The reviewer records a reviewed contract reference/note. This is a human workflow, not automatic legal document validation.
7. The admin uploads the platform's actual InstaPay QR and recipient name. A destination version is pinned to the deal. Parties see only their invoice/action and submit a bank reference after a transfer. Only an administrator can reconcile external bank evidence; self-review and duplicate references are rejected.
8. The admin records completion after legal review, both consents and both verified shares. Sale/private rental move to terminal history. Shared tenancy is created for that user; remaining beds stay available until full occupancy. Group creation continues to require a verified owner role and an actual accepted tenant as co-admin.

The app has no live InstaPay/bank integration, qualified electronic signature, escrow or automatic bank reconciliation. Explicit consent records are not represented as a certified legal signature. The operator must supply reviewed terms, qualified staff and the actual payment destination before real transactions. The [official ITIDA electronic-signature information](https://itida.gov.eg/English/Pages/E-Signature.aspx) describes the regulated service; no certified provider integration is claimed here.

## Moderated text chat

The server checks text **before storage/delivery**. It normalizes Arabic/Persian/full-width digits, zero-width marks and common spelled-number variants, rejects phone/contact links/emails, and checks recent fragments from the same sender. Rejected text is not stored; audit events contain metadata only. Messages are encrypted with a per-conversation HKDF-derived Fernet key and authenticated conversation/sender/message bindings. Losing the document master key also loses message decryption. Transport TLS is still required outside localhost.

The server can inspect plaintext in memory, as explicitly approved; this is **not E2EE**. Arbitrary steganographic contact sharing cannot be guaranteed impossible. Conservative numeric detection can reject legitimate long numeric messages; use structured offers/viewings for prices and dates. Chat currently supports text, 30-message history pages and polling; attachments, calls, notifications, retention/export and moderation appeals remain pending. Crypto primitives follow the official [Fernet](https://cryptography.io/en/stable/fernet/) and [HKDF](https://cryptography.io/en/latest/hazmat/primitives/key-derivation-functions/) documentation.

## Flutter navigation and UI

- Drawer: My properties, My groups, Deals and financial history. Admins additionally see Team/brokerage settings; admins and active document reviewers see the old-rent eligibility queue.
- Eligible property details: server financial breakdown and Start deal. The same breakdown is used in listing creation, negotiation, agreement, completion and financial history.
- Staff accounts are created internally by an admin, with an independently checked staff profile. Public registration cannot grant staff/admin privileges.
- Light/dark, AR/EN and RTL are preserved. Preview evidence: `docs/screenshots/deal-*.png`, `old-rent-*.png`, `chat-*.png`, `staff-*.png`.
- Owner dashboard remains grouped by sale/private/shared, with remote suggestions and exactly three DB rows per page. Eye pause, saved-property tombstones, current/history and terminal lifecycle remain intact. A supervised active deal blocks bypassing settlement through the manual sold/rented button.

## Demo and validation

`tools/start_demo.ps1` upgrades only `myhome_demo`; `tools/smoke_demo.py` exercises its Docker HTTP API. The demo has 10 random-credential accounts: two owners, student/expatriate/roommate, viewer, outsider, admin, field agent and document reviewer; 13 synthetic listings; one 3-member group; one open sale deal and two separate conversations with at least five seeded messages. Runtime smoke adds two explicitly synthetic messages. Actual payment QR and legally reviewed terms are intentionally not invented for the demo.

- UI: http://127.0.0.1:8081; demo API: http://127.0.0.1:3001/api/v1.
- Private credentials: ignored `artifacts/demo-accounts.json`. Never publish credentials, DB dumps, media or env files.
- Main owner: 5 sale, 3 private rental, 1 shared rental current listings; separate sold/rented history. Sale pages: 3 then 2.
- Host fixture assertions and real restricted-role Docker HTTP smoke both passed, including message insert/read, phone rejection, member isolation, staff login, favorites and fee shares.
- 56 real PostgreSQL tests; 43 Flutter tests; 6 preview-render tests. Analyzer and Ruff clean. Web and Android debug builds passed. iOS is not built on Windows.
- Local evidence: `artifacts/all-in-backend-tests.log`, `all-in-flutter-tests.log`, `all-in-web-build.log`, `all-in-apk-build.log`, `all-in-demo-runtime.json`.
- Main DB backed up to ignored `artifacts/myhome-before-all-in-20261115.dump` before additive migrations. Main/demo migration head: `20261115_communications`. Existing volumes retained.

Remaining work includes the broader roommate matching, calling, full listing edit/resume UI, account recovery, notifications and production payment/signature/operational integrations. No complete marketplace phase is marked done.
