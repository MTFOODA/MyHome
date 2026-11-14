# Latest request precedence — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
Read 29_PRODUCT_REQUIREMENTS_2026_11_14.md before the original expanded requirements below.
Current stack: Flutter/Cubit/BLoC + Python/FastAPI + SQLAlchemy/Alembic + local PostgreSQL/Docker. Guests browse home/listing summaries but need authentication for details and favorites. Users choose multiple intents after registration and an active mode; the separate search tab is for shared-rental seekers only.
Finishing choices explicitly named in the latest request are red brick, plastered, Lux and Super Lux. Rental choices are one/three/five years, old rent or custom months. ID/ownership proof is private and manually reviewed; OCR assists number comparison, not authenticity or biometric verification.
Latest primary platforms are Web/Android/iOS. Original additional features and acceptance requirements remain below and must not be marked complete from the narrower implemented slice.
Encrypted messaging and calling remain required and unimplemented.

---


# MyHome - Project Requirements

## 1. Project Vision
MyHome is a trusted real estate and shared-housing marketplace that connects verified property owners with people looking for:
- Apartments for sale (cash)
- Apartments for installment purchase
- Private rentals
- Shared rentals
- Student accommodation
- Expatriate accommodation

The platform must support property discovery, inquiries, roommate matching, secure communication, maintenance services, and administration.

## 2. Target Markets
- Initial: Egypt, EGP
- Design location data to support Egyptian governorates, cities, districts, and future geographic expansion

## 3. User Roles & Permissions

### Guest
- Can browse public listings and search
- Cannot publish, message, book, or access private groups

### Regular User
- Can search, save favorites, compare properties
- Can contact owners, submit inquiries
- Cannot publish owner listings without verification

### Student
- Can search for student housing
- Can create roommate preferences
- Can request shared accommodation

### Expatriate
- Can search for housing
- Can create roommate preferences
- Can request shared accommodation

### Property Owner
- Can manage verified properties
- Can publish listings after approval
- Can manage inquiries
- Can create eligible shared-housing groups

### Maintenance Provider
- Can manage verified maintenance services
- Can manage assigned requests

## 4. Property Categories
1. Sale — Cash
2. Sale — Installments
3. Private Rental
4. Shared Rental

## 5. Mandatory Property Creation Workflow

### Step 1 — Property Information
- Title (required)
- Property category (required: Sale/Cash, Sale/Installments, Private Rental, Shared Rental)
- Property type (required)
- Governorate (required)
- City (required)
- District (required)
- Street or approximate location (required)
- Area in square meters (required)
- Floor number (required)
- Building floor count (required)
- Bedrooms (required)
- Bathrooms (required)
- Occupancy capacity (required)
- Furnishing status (required)

### Step 2 — Utilities and Facilities (all Yes/No, no preselection)
- Water available? (required)
- Electricity available? (required)
- Natural gas available? (required)
- Internet available? (required)
- Internet installation possible? (required)
- Separate electricity meter? (required)
- Separate water meter? (required)
- Separate gas meter? (required)
- Elevator available? (required)
- Parking available? (required)
- Security available? (required)
- Balcony available? (required)
- Air conditioning available? (required)
- Kitchen available? (required)
- Washing machine available? (required)
- Refrigerator available? (required)
- Water heater available? (required)

Where appropriate, distinguish:
- Installed and working
- Available but disconnected
- Not available

### Step 3 — Finishing (mandatory options)
- Red brick / unfinished
- Plastered
- Basic finishing
- Standard finishing
- Lux
- Super Lux
- Ultra Super Lux

Also collect:
- Furnished / semi-furnished / unfurnished
- New / used
- Maintenance required? (required)
- Ready for occupancy? (required)
- Availability date (required)

### Step 4 — Pricing (required)
- Price in EGP (required)
- Negotiable? Yes / No (required)
- Additional charges

For rental:
- Monthly rent (required)
- Deposit (required)
- Advance payment (required)
- Maintenance fees
- Included utilities
- Minimum rental duration

For installment sale:
- Total price (required)
- Down payment (required)
- Remaining balance (required)
- Installment count (required)
- Installment frequency (required)
- Installment amount (required)
- Additional fees (required)
- Payment schedule (required)
- Balloon payment if applicable

Validate installment calculations on both frontend and backend.

### Step 5 — Property Media (required)
- Multiple photos (required)
- Cover photo (required)
- Reordering
- Compression
- Upload progress
- Deletion
- Optional video
- Optional floor plan

Validate file types, size, ownership, and storage access.

### Step 6 — Shared Rental Details (required when applicable)
- Total beds (required when shared rental)
- Available beds (required when shared rental)
- Occupied beds (required when shared rental)
- Price per bed (required when shared rental)
- Price per room if applicable
- Room capacity (required when shared rental)
- Bathroom sharing (required when shared rental)
- Kitchen sharing (required when shared rental)
- Guest rules (required when shared rental)
- Minimum stay (required when shared rental)
- Included utilities (required when shared rental)
- Housing rules (required when shared rental)

Prevent overbooking through backend transactions.

## 6. Search & Advanced Filters
- Search by location
- Sale/rent category
- Cash/installments
- Private/shared housing
- Minimum price
- Maximum price
- Negotiable only
- Area
- Bedrooms
- Bathrooms
- Capacity
- Finishing
- Furnishing
- Water
- Electricity
- Gas
- Internet
- Elevator
- Parking
- Security
- Balcony
- Air conditioning
- Availability
- Verified owners

Features:
- Combined filters
- Reset filters
- Saved searches
- Sorting
- Pagination
- Result counts
- Empty states
- Search suggestions

Filtering must be efficient in PostgreSQL — do not download all listings to Flutter and filter locally.

## 7. Property Details Screen
Must include:
- Image gallery
- Property title
- Price
- Negotiability badge
- Verification badge
- Location
- Area
- Bedrooms
- Bathrooms
- Capacity
- Furnishing
- Finishing
- Utilities checklist
- Description
- Availability
- Installment details
- Shared-bed availability
- Owner profile
- Favorite
- Share
- Contact owner
- Request viewing
- Submit inquiry
- Report listing

Private contact information must be protected.

## 8. Roommate Finder
Features:
- Roommate profile
- University/workplace
- Preferred area
- Budget
- Room preference
- Move-in date
- Occupancy preference
- Short introduction
- Search
- Filters
- Connection requests
- Accept/reject
- Block/report
- Authorized messaging

Sensitive personal information must be protected.

## 9. Secure Private Messaging
Support:
- One-to-one chats
- Property-linked chats
- Message history
- Delivery status
- Read receipts
- Typing indicators
- Attachments
- Notifications
- Blocking
- Reporting

Security requirements:
- Use established, audited end-to-end encryption protocol or library
- Do not invent cryptographic algorithms
- Encrypt message content on sender's device
- Decrypt only on authorized recipient devices
- Backend must not require access to plaintext message content
- Document: identity keys, session establishment, key rotation, multi-device support, secure key storage, device revocation, encrypted attachments, recovery limitations
- Never log plaintext messages or secret keys

## 16. Backend Architecture

### Technology Stack
- TypeScript
- NestJS
- PostgreSQL
- Prisma
- Docker Compose
- REST APIs
- Authenticated WebSockets where required

### Architecture Principles
- Modules separated by business responsibility
- Clean Architecture boundaries
- Dependency injection
- Repository pattern
- Service layer
- Guard clauses for validation
- Exception handling with proper HTTP status codes

### Required Modules
- Authentication module
- Authorization module
- User module
- Property module
- Messaging module
- Calling module
- Group module
- Maintenance module
- Notification module
- Report module
- Admin module

### API Design
- RESTful endpoints
- Proper request/response DTOs
- Input validation using pipes/guards
- Error exceptions with status codes
- Pagination metadata in responses
- Versioning strategy for API endpoints

## 17. PostgreSQL Database

### Initial Logical Entities
- users
- user_profiles
- user_roles
- role_permissions
- verification_requests
- owner_verifications
- properties
- property_locations
- property_features
- property_utilities
- property_media
- property_prices
- installment_plans
- installment_schedules
- rental_terms
- shared_housing_units
- shared_housing_beds
- housing_applications
- property_viewing_requests
- property_favorites
- saved_searches
- roommate_profiles
- roommate_connections
- conversations
- conversation_members
- encrypted_messages
- encrypted_attachments
- housing_groups
- housing_group_members
- call_sessions
- call_events
- maintenance_providers
- maintenance_requests
- reviews
- notifications
- reports
- audit_logs

### Design Requirements
- Normalized schema (avoid unrestricted JSON fields)
- UUIDs as primary keys
- Foreign keys with proper constraints
- Unique constraints where appropriate
- Check constraints for data validation
- Indexes on frequently queried columns
- Timestamps (created_at, updated_at) on all tables
- Safe deletion policies (soft delete or cascade rules)
- Transactions for multi-entity operations

### Do Not
- Replace structured searchable data with unrestricted JSON fields

## 18. Local Docker Infrastructure

### Docker Compose Services
- PostgreSQL database with persistent volumes
- Backend API service (NestJS)
- Optional Redis (where justified for caching/queues)

### PostgreSQL Configuration
- Persistent volumes for data persistence
- Environment variables for configuration
- Health checks
- Development seed data scripts
- Automatic database backups targeting 05:00 local time
- Restore scripts for isolated database recovery

### Network Configuration
- Document local networking for:
  - Android emulator (10.0.2.2 for host localhost)
  - Android physical device (10.0.2.2 or direct IP)
  - iOS simulator (localhost)
  - iOS physical device (network IP)
  - Web (localhost or machine IP)
  - Windows development
  - macOS development
  - Linux development

### Environment Variables
- Do not hardcode secrets
- Use .env files with proper .gitignore
- Document all required environment variables

### Health Checks
- Database connection health
- API service health
- Redis connectivity (if used)

## 19. Security & Verification

### Implement:
- Owner identity verification
- Property ownership/authorization verification
- Listing approval
- Role-based authorization
- Object-level authorization
- Secure document storage
- Secure media validation
- Rate limiting
- Abuse reporting
- Audit logging
- Privacy controls
- Secure sessions
- Account deletion

### Distinguish:
- Identity verified
- Ownership/authorization verified
- Listing approved

### Never grant verification merely because a user selects the owner role.
### Do not expose verification documents publicly.

### Abuse Reporting
- Report forms for listings, messages, groups
- Moderation queue for reports
- Action tracking and audit logs

## 20. Implementation Tracking - Done System

### Task ID Format
- AUTH-001, PROP-001, SEARCH-001, CHAT-001, GROUP-001

### Statuses
- [ ] TODO
- [-] IN PROGRESS
- [x] DONE
- [!] BLOCKED

### DONE Comment Format
<!-- DONE: TASK_ID | Files: ... | Tests: ... | Verified: YYYY-MM-DD -->

### DONE Criteria
A task is DONE only when:
- Implementation exists
- Required tests pass
- Dependencies are integrated
- UI is reviewed
- Documentation is updated

### Track Separately
- UI
- State management
- Backend
- Database
- Security
- Localization
- Tests
- Platform builds

### Never
- Mark a partially implemented feature fully DONE
- Delete task history

## 21. Feature Preservation

### Maintain
docs/06_FEATURE_PRESERVATION_CHECKLIST.md

### Before Changing Existing Code
1. Identify current behavior
2. Identify dependencies
3. Identify affected files
4. Confirm existing tests
5. Implement changes
6. Run regression tests
7. Update documentation

## 22. Agent Handoff & Continuity

### Create
- AGENTS.md in project root
- docs/14_AGENT_HANDOFF.md

### Agents Must Read
1. AGENTS.md
2. docs/00_MASTER_PLAN.md
3. docs/05_IMPLEMENTATION_PROGRESS.md
4. docs/14_AGENT_HANDOFF.md
5. Relevant screen specifications
6. Relevant feature registry entries

### Before Implementing
- Inspect existing code
- Do not duplicate completed work

### After Every Verified Task, Update
- Progress
- Task status
- DONE comment
- Files changed
- Tests
- Migrations
- Known issues
- Next task

### Handoff Document Must Include
- Last completed task
- Current task
- Next task
- Changed files
- Test results
- Build results
- Migration status
- Blockers
- Resume commands

### Project Must Remain Resumable After
- Claude usage limits
- Context exhaustion
- VS Code restart
- Computer restart
- Agent replacement
- Switching between Claude and Codex

### Never
- Rely exclusively on conversation history

## 24. Implementation Phases (Order)

### Phase 0: Documentation & UI analysis
- Inspect repository
- Analyze seven screenshot groups
- Extract individual screens
- Create screen specifications
- Create project architecture
- Create folder/file/class inventories
- Create task registry
- Create agent handoff

### Phase 1: Foundation
- Initialize Flutter
- Initialize NestJS
- Configure PostgreSQL
- Configure Docker
- Configure dependency injection
- Configure routing
- Configure localization
- Configure themes
- Build Design System
- Configure testing

### Phase 2: Authentication & roles
- Login
- Registration
- Session restoration
- Role onboarding
- Owner verification
- Profile setup
- Authorization tests

### Phase 3: Property management
- Database schema
- Property CRUD
- Mandatory listing form
- Property media
- Pricing
- Installments
- Shared rental configuration
- Validation

### Phase 4: Discovery
- Home
- Search
- Advanced filters
- Property details
- Favorites
- Saved searches
- Viewing requests

### Phase 5: Shared housing
- Roommate profiles
- Roommate finder
- Housing applications
- Bed availability
- Group creation
- Group membership
- Role restrictions

### Phase 6: Communication
- Private messaging
- End-to-end encryption
- Attachments
- Group messaging
- Group encryption
- Voice calling
- Call history
- Notifications

### Phase 7: Supporting features
- Maintenance
- Account settings
- Help
- FAQ
- About Us
- User Guide
- Reviews

### Phase 8: Administration
- Admin dashboard
- Owner verification review
- Listing moderation
- Reports
- Audit logs

### Phase 9: Quality & release
- Security audit
- Integration tests
- Performance optimization
- Accessibility
- Localization QA
- Platform builds
- Backup/restore verification
- Deployment documentation

### Do Not
- Mark a phase DONE until its acceptance criteria are verified
- Independent tasks may proceed when dependencies satisfied

## 27. Final Acceptance Criteria

### Project Complete Only When
- Documentation is accurate
- Architecture is consistent
- All identified reference screens are implemented
- All approved additional screens are implemented
- Property creation works
- Mandatory validation works
- Search and filters work
- Owner verification is enforced
- Role permissions are enforced server-side
- Shared-housing group restrictions work
- Messaging encryption is verified
- Voice-call security is verified
- Arabic and English work
- Light and dark modes work
- Database migrations pass
- Backend tests pass
- Flutter tests pass
- Supported platform builds are verified
- Backup and restore are tested
- No known critical security issues remain

## 28. Token & Context Efficiency

### Development Environment Considerations
- Avoid repeatedly scanning the entire repository
- Use file inventory for references
- Read relevant files only
- Avoid unnecessary terminal output
- Keep tasks focused
- Avoid duplicate explanations
- Save progress after each verified task
- Maintain concise handoff documentation
- Never falsely mark unfinished work DONE

### Before Ending Any Session
- Update the handoff document
- Preserve the exact implementation state

### If Approaching Context or Usage Limit
- Prioritize preserving the exact implementation state
- Never falsely mark unfinished work DONE

## 23. Automated Testing

### Create
- Unit tests
- Widget tests
- BLoC/Cubit tests
- Repository tests
- API tests
- Database integration tests
- Authorization tests
- Security tests
- Localization tests
- Navigation tests
- Responsive tests

### Critical Tests
- Regular users cannot publish owner listings
- Unverified owners cannot bypass verification
- Owners cannot edit other owners' properties
- Nonmembers cannot access private groups
- Removed owners cannot create new groups
- Suspended owners cannot bypass role restrictions
- Users cannot access other users' identity documents
- Unauthorized users cannot access private messages
- Crafted API requests cannot bypass property validation
- Concurrent requests cannot overbook the last available bed
- Installment calculations remain consistent

### For Messaging and Calling
- Test actual security mechanisms, not only mocked UI behavior
- Verify encryption/decryption works correctly
- Test key rotation scenarios
- Test multi-device synchronization