# Current feature registry — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->

| Feature family | Current status |
|---|---|
| BACK-201 FastAPI migration | [x] Scoped verified adoption/runtime; broader operations pending |
| AUTH-001/002/003 | [-] Functional auth and sessions retained in FastAPI; native/runtime/release validation remains |
| AUTH-004/005 | [ ] Email verification and recovery still absent |
| AUTH-006 / AUTH-201 | [-] Multiple intents/active mode/persona implemented and tested; full lifecycle remains |
| AUTH-007 | [-] Private docs, number/date/OCR comparison and manual reviewer workflow exist; authenticity, retention and operational policy pending |
| PROP-001/002/008/009/010 | [-] Current-request create/validate/upload/submit/review API/UI slice exists; expanded fields and complete management UI remain |
| PROP-003/004/005 | [-] Real PostgreSQL discovery/filtering, protected details/gallery and favorites exist; broader discovery acceptance still pending |
| PROP-006/007 | [ ] Saved searches/viewing requests absent |
| SEARCH-001/002/003 | [-] Property filters moved to public home; separate search tab now means shared-only roommate search |
| ROOM-001/002 | [ ] Authorized empty roommate endpoint only, no real profiles or matching |
| ROOM-003/004 | [-] Application and last-bed acceptance implemented; full lifecycle pending |
| ROOM-005 / GROUP | [-] Group metadata enforces verified active owner + accepted tenant co-admin; actual chat unimplemented |
| CHAT/VOICE | [ ] E2EE transport/calls, key/device lifecycle and notifications absent |
| PROF-001/002 | [-] Read account, active role/locale/theme settings; profile editing/lifecycle absent |
| ADMIN-002 | [-] Reviewer queue/decision UI and API; broad admin/moderation functionality remains |
| HELP/ABOUT/GUIDE | [-] Introductory localized content only |
| MAIN/REVIEWS/REPORTS/NOTIFICATIONS | [ ] Not implemented |

Scoped DONE comments and exact evidence remain in docs/05. Historical feature definitions/statuses below are preserved.

---


# MyHome — Current feature status
<!-- CURRENT_AUDIT_2026_11_09 -->
Audited 2026-11-09. The table below supersedes the original INTEGRATED/PARTIALLY IMPLEMENTED labels preserved in the historical registry.

| Feature | Current status | Scope remaining |
|---|---|---|
| AUTH-001 Registration | [-] Implemented functional slice | Native runtime QA; full identity/profile flows separate |
| AUTH-002 Login | [-] Implemented functional slice | Native runtime QA and release/security QA |
| AUTH-003 Session restoration | [-] Implemented and host/live-API tested | Native secure-storage validation on each platform |
| AUTH-004 Email verification | [ ] TODO | No OTP/challenge/mail delivery implementation |
| AUTH-005 Password reset | [ ] TODO | No recovery/token/delivery implementation |
| AUTH-006 Role onboarding | [-] Registration role selection implemented | Broader profile setup and verification workflow |
| AUTH-007 Owner verification | [ ] TODO | Status/default/guards exist; submission/review does not |
| PROF-001 Profile | [-] Read/refresh implemented | Editing/avatar/location/contact profile |
| PROF-002 Settings | [-] Locale/appearance implemented | Remaining account/privacy/notifications settings |
| SEARCH-001 Home | [-] Presentation shell | Live featured/listing/search data |
| SEARCH-002/003 Search/filters | [ ] TODO | Search is an empty view, not an implemented query |
| PROP-001..010 | [ ] TODO | No property database/API/form/media/favorites backend |
| SEARCH-004 Comparison | [ ] TODO | Empty presentation shell only |
| HELP-001 | [-] Brief guide exists | Full FAQ/contextual help |
| ABOUT-001/GUIDE-001 | [-] Introductory content exists | Complete reference content and approved organization information |
| ROOM/CHAT/VOICE/GROUP/MAIN/ADMIN/NOTIF/REVIEW/REPORT features | [ ] TODO | No implementation present |

Completed scoped increments FOUND-001, AUTH-101, AUTH-102 and INFRA-001 are tracked with evidence in 05_IMPLEMENTATION_PROGRESS.md. No complete product phase is claimed.

---

## Historical registry entries — superseded status labels, feature definitions retained

# MyHome - Feature Registry

This document registers all features of the MyHome application, their current implementation status, and their relationship to other features.

## Feature Registration Format
Each feature entry includes:
- Feature ID (e.g., AUTH-001, PROP-001)
- Feature name
- Architecture layer (presentation, domain, data)
- Responsibility
- Related screens
- Dependencies on other features
- Implementation phase
- Current status ([ ], [-], [x], [!])

## Authentication Features

### AUTH-001: User Registration
- Layer: presentation/domain
- Responsibility: User sign-up with validation
- Screens: Registration page
- Dependencies: None
- Phase: 2
- Status: INTEGRATED

### AUTH-002: User Login
- Layer: presentation/domain
- Responsibility: User authentication with session
- Screens: Login page
- Dependencies: AUTH-001
- Phase: 2
- Status: INTEGRATED

### AUTH-003: Session Restoration
- Layer: domain/data
- Responsibility: Restore user session on app launch
- Screens: None (background)
- Dependencies: AUTH-001, AUTH-002
- Phase: 2
- Status: INTEGRATED

### AUTH-004: Email Verification
- Layer: domain/data
- Responsibility: Send and verify email OTP
- Screens: Verification page
- Dependencies: AUTH-001, AUTH-002
- Phase: 2
- Status: PARTIALLY IMPLEMENTED

### AUTH-005: Password Reset
- Layer: domain/data
- Responsibility: Password reset via email link
- Screens: Password reset page
- Dependencies: AUTH-001
- Phase: 2
- Status: PARTIALLY IMPLEMENTED

### AUTH-006: Role Onboarding
- Layer: presentation/domain
- Responsibility: Select/confirm user role on first login
- Screens: Role selection page
- Dependencies: AUTH-001, AUTH-002
- Phase: 2
- Status: INTEGRATED

### AUTH-007: Owner Verification
- Layer: domain/data
- Responsibility: Verify property owner identity
- Screens: Verification request page
- Dependencies: AUTH-001, AUTH-002
- Phase: 2
- Status: TODO

## Property Features

### PROP-001: Property Creation Form (7 steps)
- Layer: presentation/domain/data
- Responsibility: Multi-step form for creating listings
- Screens: Property creation wizard
- Dependencies: None (foundational)
- Phase: 3
- Status: TODO

### PROP-002: Property CRUD Operations
- Layer: domain/data
- Responsibility: Create, read, update, delete properties
- Screens: Property management pages
- Dependencies: PROP-001
- Phase: 3
- Status: TODO

### PROP-003: Property Search & Filters
- Layer: presentation/data
- Responsibility: Search and advanced filtering
- Screens: Home, search page
- Dependencies: None
- Phase: 4
- Status: TODO

### PROP-004: Property Details
- Layer: presentation/domain/data
- Responsibility: Display full property information
- Screens: Property detail page
- Dependencies: PROP-002, PROP-003
- Phase: 4
- Status: TODO

### PROP-005: Favorites
- Layer: domain/data
- Responsibility: Save and manage property favorites
- Screens: Property detail, favorites page
- Dependencies: PROP-002
- Phase: 4
- Status: TODO

### PROP-006: Saved Searches
- Layer: domain/data
- Responsibility: Save and recall search criteria
- Screens: Search page
- Dependencies: PROP-003
- Phase: 4
- Status: TODO

### PROP-007: Viewing Requests
- Layer: domain/data
- Responsibility: Submit viewing request for property
- Screens: Property detail page
- Dependencies: PROP-002, AUTH-001
- Phase: 4
- Status: TODO

### PROP-008: Installment Calculations
- Layer: domain/data
- Responsibility: Validate installment plan calculations
- Screens: Property creation step 4, property details
- Dependencies: PROP-001
- Phase: 3
- Status: TODO

### PROP-009: Shared Rental Configuration
- Layer: domain/data
- Responsibility: Configure shared rental details
- Screens: Property creation step 6
- Dependencies: PROP-001
- Phase: 3
- Status: TODO

### PROP-010: Property Media Upload
- Layer: presentation/data
- Responsibility: Upload and manage property photos/videos
- Screens: Property creation steps 5, property detail gallery
- Dependencies: PROP-001
- Phase: 3
- Status: TODO

## Roommate Features

### ROOM-001: Roommate Profile
- Layer: presentation/domain
- Responsibility: User profile for roommate searching
- Screens: Roommate profile page
- Dependencies: AUTH-001, AUTH-006
- Phase: 5
- Status: TODO

### ROOM-002: Roommate Finder
- Layer: presentation/domain/data
- Responsibility: Search and find compatible roommates
- Screens: Roommate finder page
- Dependencies: ROOM-001, AUTH-006
- Phase: 5
- Status: TODO

### ROOM-003: Housing Applications
- Layer: domain/data
- Responsibility: Apply for shared housing
- Screens: Application submission page
- Dependencies: ROOM-002, PROP-009
- Phase: 5
- Status: TODO

### ROOM-004: Bed Availability
- Layer: domain/data
- Responsibility: Track bed availability in shared units
- Screens: None (backend feature)
- Dependencies: PROP-009
- Phase: 5
- Status: TODO

### ROOM-005: Group Creation
- Layer: domain/data
- Responsibility: Create housing group for property
- Screens: Group creation page
- Dependencies: PROP-009, AUTH-007
- Phase: 5
- Status: TODO

### ROOM-006: Group Membership
- Layer: domain/data
- Responsibility: Manage group membership requests
- Screens: Group management page
- Dependencies: ROOM-005
- Phase: 5
- Status: TODO

### ROOM-007: Role Change Restrictions
- Layer: domain/data
- Responsibility: Enforce group creation restrictions on role change
- Screens: None (backend enforcement)
- Dependencies: ROOM-005, AUTH-007
- Phase: 5
- Status: TODO

## Communication Features

### CHAT-001: Private Messaging
- Layer: presentation/domain/data
- Responsibility: One-to-one private chat
- Screens: Chat screen, conversation list
- Dependencies: AUTH-001, AUTH-002
- Phase: 6
- Status: TODO

### CHAT-002: End-to-End Encryption
- Layer: domain/data
- Responsibility: Encrypt/decrypt message content
- Screens: None (crypto library)
- Dependencies: CHAT-001
- Phase: 6
- Status: TODO

### CHAT-003: Message History
- Layer: domain/data
- Responsibility: Load and display message history
- Screens: Chat screen
- Dependencies: CHAT-001
- Phase: 6
- Status: TODO

### CHAT-004: Typing Indicators
- Layer: presentation/domain
- Responsibility: Show when user is typing
- Screens: Chat screen
- Dependencies: CHAT-001
- Phase: 6
- Status: TODO

### CHAT-005: Property-Linked Chats
- Layer: domain/data
- Responsibility: Chat linked to specific property
- Screens: Property detail, chat initiation
- Dependencies: CHAT-001, PROP-004
- Phase: 6
- Status: TODO

### VOICE-001: Voice Calling
- Layer: presentation/domain/data
- Responsibility: WebRTC-based voice calls
- Screens: Call screen, call history
- Dependencies: None (technical setup)
- Phase: 6
- Status: TODO

### VOICE-002: Call Session Management
- Layer: domain/data
- Responsibility: Manage call sessions and events
- Screens: None (background)
- Dependencies: VOICE-001
- Phase: 6
- Status: TODO

### VOICE-003: Call History
- Layer: domain/data
- Responsibility: Store and display call history
- Screens: Profile, call history page
- Dependencies: VOICE-001
- Phase: 6
- Status: TODO

## Shared-Housing Group Features

### GROUP-001: Group Creation
- Layer: domain/data
- Responsibility: Create encrypted group for property
- Screens: Group creation page
- Dependencies: PROP-009, AUTH-007
- Phase: 5
- Status: TODO

### GROUP-002: Membership Requests
- Layer: domain/data
- Responsibility: Handle membership join requests
- Screens: Group members page
- Dependencies: GROUP-001
- Phase: 5
- Status: TODO

### GROUP-003: Membership Approval
- Layer: domain/data
- Responsibility: Approve/reject membership requests
- Screens: Group management page
- Dependencies: GROUP-002
- Phase: 5
- Status: TODO

### GROUP-004: Member Removal
- Layer: domain/data
- Responsibility: Remove member from group
- Screens: Group management page
- Dependencies: GROUP-002
- Phase: 5
- Status: TODO

### GROUP-005: Group Announcements
- Layer: presentation/domain
- Responsibility: Post announcements to group
- Screens: Group chat page
- Dependencies: GROUP-001, CHAT-001
- Phase: 5/6
- Status: TODO

### GROUP-006: Role Change Enforcement
- Layer: domain/data
- Responsibility: Revoke group creation on role change
- Screens: None (backend enforcement)
- Dependencies: GROUP-001, AUTH-007
- Phase: 5
- Status: TODO

## Maintenance Features

### MAIN-001: Service Provider Profiles
- Layer: presentation/domain
- Responsibility: Provider profiles with verification status
- Screens: Maintenance services page
- Dependencies: None
- Phase: 7
- Status: TODO

### MAIN-002: Service Requests
- Layer: domain/data
- Responsibility: Create and manage maintenance requests
- Screens: Create request, request status page
- Dependencies: MAIN-001, PROP-002
- Phase: 7
- Status: TODO

### MAIN-003: Provider Assignment
- Layer: domain/data
- Responsibility: Assign provider to request
- Screens: Request management page
- Dependencies: MAIN-002
- Phase: 7
- Status: TODO

### MAIN-004: Customer-Provider Communication
- Layer: presentation/domain
- Responsibility: Communicate with assigned provider
- Screens: Request details page
- Dependencies: MAIN-002, CHAT-001
- Phase: 7
- Status: TODO

### MAIN-005: Completion Confirmation
- Layer: domain/data
- Responsibility: Confirm maintenance completion
- Screens: Request completion page
- Dependencies: MAIN-002
- Phase: 7
- Status: TODO

### MAIN-006: Provider Reviews
- Layer: presentation/domain/data
- Responsibility: Review completed service providers
- Screens: Provider profile, reviews page
- Dependencies: MAIN-002
- Phase: 7
- Status: TODO

## Discovery Features

### SEARCH-001: Home Screen
- Layer: presentation
- Responsibility: Main home dashboard
- Screens: Home page
- Dependencies: None
- Phase: 4
- Status: TODO

### SEARCH-002: Advanced Search
- Layer: presentation/data
- Responsibility: Advanced filterable search
- Screens: Search page
- Dependencies: PROP-003
- Phase: 4
- Status: TODO

### SEARCH-003: Search Filters
- Layer: domain/data
- Responsibility: Individual filter components
- Screens: Search page sidebar/panel
- Dependencies: SEARCH-002
- Phase: 4
- Status: TODO

### SEARCH-004: Property Comparison
- Layer: presentation/domain
- Responsibility: Compare multiple properties
- Screens: Comparison view
- Dependencies: PROP-004, PROP-005
- Phase: 4
- Status: TODO

## Profile Features

### PROF-001: User Profile
- Layer: presentation/domain
- Responsibility: User profile display and editing
- Screens: Profile page, edit profile
- Dependencies: AUTH-001, AUTH-002
- Phase: 2
- Status: TODO

### PROF-002: Account Settings
- Layer: presentation/domain
- Responsibility: Account configuration
- Screens: Account settings page
- Dependencies: PROF-001
- Phase: 7
- Status: TODO

### PROF-003: Password Change
- Layer: presentation/domain/data
- Responsibility: Change user password
- Screens: Account settings page
- Dependencies: PROF-001, AUTH-004
- Phase: 7
- Status: TODO

### PROF-004: Account Deletion
- Layer: domain/data
- Responsibility: Delete user account
- Screens: Account settings page
- Dependencies: PROF-001, AUTH-001
- Phase: 7
- Status: TODO

## Admin Features

### ADMIN-001: Admin Dashboard
- Layer: presentation/domain/data
- Responsibility: Platform administration panel
- Screens: Dashboard page
- Dependencies: AUTH-001 (admin role only)
- Phase: 8
- Status: TODO

### ADMIN-002: Owner Verification Review
- Layer: domain/data
- Responsibility: Review and approve owner verifications
- Screens: Verification review page
- Dependencies: AUTH-007
- Phase: 8
- Status: TODO

### ADMIN-003: Listing Moderation
- Layer: domain/data
- Responsibility: Moderate and approve/reject listings
- Screens: Moderation queue page
- Dependencies: PROP-002, AUTH-007
- Phase: 8
- Status: TODO

### ADMIN-004: Reports
- Layer: domain/data
- Responsibility: View and manage reports
- Screens: Reports page
- Dependencies: AUTH-001 (admin role)
- Phase: 8
- Status: TODO

### ADMIN-005: Audit Logs
- Layer: domain/data
- Responsibility: View audit log of system actions
- Screens: Audit log page
- Dependencies: AUTH-001 (admin role)
- Phase: 8
- Status: TODO

## Supporting Features

### NOTIF-001: Notifications
- Layer: presentation/domain
- Responsibility: Push/local notifications
- Screens: Notification center
- Dependencies: CHAT-001, VOICE-001, MAIN-002
- Phase: 7
- Status: TODO

### HELP-001: Help & FAQ
- Layer: presentation
- Responsibility: Help articles and FAQ answers
- Screens: Help page, FAQ page
- Dependencies: None
- Phase: 7
- Status: TODO

### ABOUT-001: About Us
- Layer: presentation
- Responsibility: Company information
- Screens: About Us page
- Dependencies: None
- Phase: 7
- Status: TODO

### GUIDE-001: User Guide
- Layer: presentation
- Responsibility: How-to guides and tutorials
- Screens: User Guide page
- Dependencies: None
- Phase: 7
- Status: TODO

### REVIEW-001: Property Reviews
- Layer: presentation/domain/data
- Responsibility: User reviews for properties
- Screens: Property detail page
- Dependencies: PROP-004
- Phase: 7
- Status: TODO

### REPORT-001: Listing Reports
- Layer: presentation/domain
- Responsibility: Report inappropriate listings
- Screens: Property detail page, report form
- Dependencies: PROP-004
- Phase: 7
- Status: TODO