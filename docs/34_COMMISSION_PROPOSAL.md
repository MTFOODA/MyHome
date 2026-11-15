## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

# Proposed platform fee — approval pending

These are **product recommendations**, not a legal tariff or a claimed market average. They are currently displayed as a preview only: `COMMISSION_ENABLED=false`. Actual payment collection, invoicing and fee settlement are not implemented.

There is no single competitive pricing model: [Nawy Keys advertises rental listings without broker fees](https://www.nawy.com/nawy-keys/properties). The proposed modest schedule below is an internal starting point, to be assessed against operating costs and conversion data.

| Type | Up to 1 year | Up to 3 years | Longer contracts, including 5 years |
|---|---|---|---|
| Sale, cash or installments | **1% of owner total**, once per deal | Same | Same |
| Private rental | **½ month's base rent**, once per contract | **¾ month**, once per contract | **1 month maximum**, once per contract |
| Shared rental | **¼ month's base bed rent**, per signed bed contract | **⅜ month**, per signed bed contract | **½ month maximum**, per signed bed contract |

For custom contracts shorter than one year, the one-year fee is prorated by `months / 12`. Old-rent contracts require a separate agreement; no duration or fee is guessed. The proposal assumes the monthly base price is fixed across the entered contract; annual rent escalations are not modeled.

Sale official price is `owner price + fee`. For installments, the platform fee is added to the displayed down payment once; installment amounts remain unchanged, so down payment + installments still equals the official total.

Rental official monthly price is `owner monthly rent + allocated monthly fee`. The monthly allocation is rounded **down** to whole piasters; the displayed total fee equals that allocation times the contract months. This keeps the rounding adjustment within the stated maximum and avoids charging an unexplained remainder. The UI shows both total contract fee and the monthly price with fee. This is price calculation, not recurring payment collection.

Examples before any regional discount:

- Sale: owner asks EGP 1,000,000 → fee EGP 10,000 → official sale price EGP 1,010,000.
- Private rent, 1 year: EGP 12,000/month → total fee EGP 6,000 → displayed EGP 12,500/month.
- Shared rent, 1 year: EGP 3,000/bed/month → total fee EGP 750 per signed bed contract → displayed EGP 3,062.50/bed/month. Four occupied beds correspond to four contracts, not four times one person's fee.

## Governorates, areas and people

The base property/bed price already reflects the governorate and area. No automatic "wealth" classification or higher regional rate is installed. Optional **0–30% discounts on the fee** can be configured for specific governorates/areas after operational evidence or a targeted promotion. An area's override takes precedence over its governorate; discounts are not stacked. Defaults are empty, so every area's multiplier is 1.00.

Capacity does not multiply a per-bed quote. `estimated_full_occupancy_fee` is an illustrative full-occupancy estimate only; no fee is charged for empty beds or hypothetical contracts by this implementation.

## Operator configuration

Server-only settings (local `.env` / Compose API environment):

```dotenv
COMMISSION_ENABLED=false
COMMISSION_POLICY_VERSION=proposal-v1
COMMISSION_SALE_RATE=0.01
COMMISSION_PRIVATE_ONE=0.5
COMMISSION_PRIVATE_THREE=0.75
COMMISSION_PRIVATE_LONG=1
COMMISSION_SHARED_ONE=0.25
COMMISSION_SHARED_THREE=0.375
COMMISSION_SHARED_LONG=0.5
COMMISSION_REGION_DISCOUNTS={}
```

An optional discount value of `0.20` means a 20% discount on the fee. Keys use `area:ID` or `governorate:ID`. No discounts are enabled by this document. Clients cannot supply fee rates or regional multipliers; strict input validation rejects those extra fields.

Each listing stores owner price, official display price, total fee and policy version. Enabling/changing a policy does **not** silently reprice existing listings: only a newly created/materially edited listing obtains a fresh snapshot and requires approval. Filters/sorting use the stored official price. Sold/rented history remains immutable. Change the policy version whenever changing its rates; explicit price migration/owner re-acceptance would be a separate operation.

Pending product decisions: approve/adjust the proposed rates, define collection/settlement and cancellation/refund rules, and decide any actual regional promotions. No commission is collected or applied to public prices while this proposal is disabled.
