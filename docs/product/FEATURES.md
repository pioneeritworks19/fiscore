# FiScore Features

## Platform Direction

FiScore should be designed as a restaurant operations and compliance platform rather than a single-purpose inspection viewer.

Version 1 is centered on:

- public health department inspections
- internal audits
- site portfolio management
- training and operational improvement
- violations and remediation workflows

However, the product should leave room for future operational modules such as:

- asset tracking
- complaint tracking
- additional location operations workflows

This direction should influence navigation, data boundaries, and overall app structure from the beginning so the platform can grow without needing a full redesign later.

## Closed-Loop Improvement Model

FiScore should be positioned as a closed-loop restaurant safety and behavior improvement platform.

The core product loop is:

`Audit -> Violation -> Discussion -> Structured Response -> Training -> Improved Behavior -> Better Audit`

This loop should influence product requirements, workflow design, data modeling, and reporting.

Best-practice expectations:

- remediation should not stop at identifying a finding
- discussion, structured remediation, and training should be connected to real operational issues
- later audit outcomes should be reviewable alongside prior remediation and training activity

## Site Management Module

### Feature Summary

FiScore should allow tenants to manage the restaurant sites they operate inside the app, even when a location is not yet available in FiScore master data.

Users with permission should be able to:

- find and add a site from FiScore master data
- manually add a site when it cannot be found in master data
- manage a portfolio of sites after registration, not only during onboarding
- switch between sites during day-to-day use
- later link a manually created site to a master restaurant record when a verified match becomes available

This capability should be treated as part of the tenant operating model rather than a one-time onboarding task.

### Business Value

- prevents onboarding and expansion from blocking on master data gaps
- allows restaurants to start using internal audits and violations immediately
- supports real-world multi-site operators whose locations may not all be present in the public-data layer yet
- creates a cleaner separation between tenant-owned operating sites and externally sourced master restaurant records

### Core Concepts

FiScore should distinguish between:

- `master restaurant`
  the canonical public or reference entity in the master-data platform
- `tenant site`
  the operating location inside the customer's FiScore tenant

This distinction matters because a tenant site may exist before a master restaurant match exists.

### Site Creation Paths

#### 1. Linked Site

The user finds the location in FiScore master data and adds it into the tenant.

Capabilities include:

- search by zip code and restaurant name
- select the correct master record
- create the tenant site with a master link
- import public inspection history when available

#### 2. Manual Site

The user cannot find the location in FiScore master data and creates it manually.

Capabilities include:

- enter site name and address manually
- create the tenant site without a master link
- begin using internal audits, violations, and team workflows immediately
- later reconcile or link the site to master data when available

### Site Link States

Recommended tenant site link states:

- `linked_to_master`
- `manual_unlinked`
- `pending_match_review`
- `archived`

### Functional Expectations

The Site Management module should support the following outcomes:

- add sites during registration
- add sites after registration from a dedicated site management area
- search and link to master restaurant records
- manually create sites when no match is found
- switch between active sites
- show which sites are linked versus manual
- allow later master-link reconciliation for manual sites
- allow internal audits and violations for both linked and manual sites
- only enable public inspection import for linked sites

### Best-Practice Expectations

- manual site creation should not be treated as an error condition
- the user should understand clearly when public inspection data is unavailable because the site is not linked
- a later matching workflow should avoid overwriting tenant activity already created on the manual site
- site management should remain available after onboarding because tenants will add locations over time

### Relationship To Future Asset Management

This feature is about managing the restaurant locations or sites inside the tenant.

It should not be confused with future fixed-asset tracking such as:

- refrigerators
- equipment
- thermometers
- maintenance assets

If FiScore later adds classic asset tracking, that should live under a separate module attached to a tenant site.

## Violations Module

### Feature Summary

The Violations module gives FiScore a unified workflow for tracking, assigning, responding to, reviewing, and closing restaurant compliance findings. Violations may originate from health department inspections harvested from government websites, from internal audits conducted by restaurant staff, or from manual entry directly against a site.

Every violation should follow a clear lifecycle so teams can move from identification to remediation with full traceability. Users should be able to capture a structured response, attach lightweight evidence such as photos, short videos, or supporting documents, collaborate with teammates through a thread discussion, and route the violation for review when needed.

### Business Value

- Centralizes follow-up work across public inspections, internal audits, and manual site findings
- Helps restaurants respond consistently to food safety issues
- Supports accountability through assignment, review, and closure workflows
- Creates traceable remediation records for compliance and operational follow-up
- Gives owners and managers visibility into unresolved, recurring, and high-risk issues

### Violation Sources

FiScore should support violations originating from multiple sources while preserving source context.

Supported sources include:

- health department inspection findings copied into the tenant site
- internal audits conducted by restaurant staff
- auto-created violations triggered from audit checklist responses
- manually created violations entered directly against a site

Each violation should retain source metadata so users can understand where it came from and report on it accurately.

Suggested source fields:

- source type
- source system or agency
- source inspection id when applicable
- source finding id when applicable
- source audit id when applicable
- originating checklist question or response when applicable
- date identified

### Violation Lifecycle

Every violation should have a clear lifecycle regardless of source.

Recommended lifecycle states:

- `Open`
- `In Progress`
- `Pending Review`
- `Closed`
- `Reopened`

Best-practice expectations:

- New violations begin in `Open`
- Work performed by staff can move a violation to `In Progress`
- Users can submit a completed response for manager review, moving the violation to `Pending Review`
- Restaurant managers can approve and close violations
- Closed violations can be reopened if the issue recurs, the response is insufficient, or the condition fails verification
- Lifecycle transitions should be traceable by user, timestamp, and device

### Structured Violation Response

Version 1 should use a structured violation response rather than a separate CAPA-plan or generic actions module.

Recommended response fields:

- `responseGeneral`
- `responseContainment`
- `responseRootCause`
- `responseCorrectiveAction`
- `responsePreventiveAction`

Important positioning:

- the thread remains the collaboration space
- the response is the official record of how the issue was addressed
- staff may complete the response over time in phases
- managers review the response together with thread history before closure

### Evidence Attachments

Violation responses should support lightweight supporting evidence without creating excessive storage or sync problems.

Supported evidence types:

- images
- short videos
- documents

Best-practice expectations:

- Compress images before sync or upload
- Limit video length and optimize files for mobile capture
- Support background upload and sync for media when the device reconnects
- Show attachment status such as saved locally, uploading, synced, or failed
- Keep evidence tied to the specific violation and response event

### Collaboration and Chat

The system should support built-in collaboration on follow-up work.

Capabilities include:

- thread-first discussion within an action
- thread-first discussion within a violation
- timestamped discussion history
- comments
- mentions
- photos
- updates
- assignments
- status-change notes
- collaboration between assignees, managers, and reviewers
- activity visibility for updates, evidence uploads, and status changes

This allows users to coordinate work inside the violation itself rather than relying on external messaging tools.

### Violation Threads

Violations should behave as collaborative operational threads rather than only static records.

Best-practice expectations:

- the thread should remain part of the compliance record
- remediation context should stay attached to the originating issue
- the discussion should help produce clearer remediation and better structured responses

### Review and Closure Workflow

FiScore should support a flexible but controlled closeout process.

Capabilities include:

- Users can work on a violation response and submit it for review
- Restaurant managers can review submitted responses and close the violation
- Reviewers should be able to reject the response, request more work, or reopen the violation
- Closure should preserve who closed the violation, when it was closed, and what evidence supported closure

### Notifications and Follow-Up Signals

FiScore should support operational notifications for follow-up work.

Important notification use cases include:

- assigned violations
- assigned training
- overdue audits
- overdue training
- review requests submitted to managers

### Source-Specific Context

Although all violations share a common lifecycle, source type still matters for reporting and user context.

#### Health Department Violations

These are typically harvested from government websites and should preserve:

- agency name
- inspection date
- original inspection reference
- official violation text when available
- status relative to the official inspection

#### Internal Audit Violations

These are created from restaurant-led audits or manual operational findings and should preserve:

- related audit session
- checklist section and question when applicable
- whether the violation was auto-created or manually added
- the response that triggered the finding when applicable

#### Manual Site Violations

These are created directly against a site and should preserve:

- manually created source
- site context
- creation user and timestamp

### Violation Display and Representation

Violations should support different display formats depending on their source and level of detail. Not every violation will have the same structure, and the UI should be able to present both simple and richly contextualized records without forcing them into one rigid format.

Common display patterns include:

- plain-text violation title
- official health department clause or code with descriptive text
- checklist-based context such as section, question, and response
- a combined representation that includes both a user-friendly summary and the underlying structured source details

Examples:

- `Improper cold holding`
- `Handwashing sink not properly stocked`
- `Clause 3-501.16: Cold holding temperatures above safe limit`
- `Food Storage > Are raw and ready-to-eat foods separated? > No`
Best-practice expectations:

- The system should always store a readable violation summary for list views and notifications
- The system should also preserve structured source context when available
- Users should be able to see both the normalized violation record and the source details behind it
- Health department violations should preserve official language where available
- Internal audit violations should preserve checklist context such as section, question, and triggering response where available

### Functional Expectations

The Violations module should support the following user outcomes:

- View violations from health department inspections, internal audits, and manual site entry in one system
- Filter violations by source, site, status, assignee, severity, and due date
- Create violations manually against a site
- Auto-create violations from audit responses
- Add and update a structured violation response
- Attach lightweight photos, short videos, and documents
- Collaborate through built-in violation discussion
- Save and update violation responses offline where applicable
- Submit violations for review
- Allow managers to review and close violations
- Reopen violations when needed
- Maintain a full response and status history

### Recommended Best-Practice Positioning

From an industry best-practice perspective, this feature should be positioned as a closed-loop violation and remediation system rather than a simple issue list. The value comes from combining:

- unified violation intake across multiple sources
- structured remediation workflows
- collaboration on follow-up work
- flexible response depth
- evidence-based verification
- manager review and controlled closure
- traceable compliance history

## Public Inspection Records Module

### Feature Summary

FiScore should allow tenants to view public health department inspection history for linked restaurants and supplement incomplete public records with tenant-provided supporting documents when needed.

In some jurisdictions, the public source may expose inspection summaries and findings but not the actual inspection report PDF or official document artifact. In those cases, FiScore should allow permitted tenant users to upload a copy of the onsite inspection report that was left with the restaurant by the health department auditor.

### Business Value

- fills gaps in incomplete public-source inspection records
- gives restaurants a more complete compliance history in one system
- supports manager review and future inspection readiness
- improves documentation quality for follow-up and remediation

### Core Capabilities

#### 1. Public Inspection Visibility

The system should allow users to:

- view imported public inspection records for linked restaurants
- review inspection findings and history
- view official report links when the source provides them

#### 2. Tenant-Provided Onsite Report Upload

When the public source does not provide the actual report document, the system should allow a permitted user to attach a restaurant-provided copy of the onsite inspection report.

Capabilities include:

- upload a PDF, image, or scanned copy of the onsite inspection report
- attach the uploaded file to a specific public inspection record
- label the file clearly as tenant-provided rather than official-source-provided
- track who uploaded the file and when
- support replacing the uploaded copy later if a clearer version is provided

#### 3. Clear Source Labeling

The system should clearly distinguish between:

- official public-source report artifacts
- tenant-uploaded onsite copies

This helps preserve trust and traceability.

### Best-Practice Expectations

- the tenant-uploaded onsite report should not overwrite or masquerade as the official source document
- the UI should clearly show whether a report came from the public source or from the restaurant
- if both exist, both should be viewable
- uploaded onsite reports should be treated as supporting compliance documentation tied to a specific public inspection

## Training Module

### Feature Summary

FiScore should support a Training module focused on operational behavior improvement rather than generic learning management.

Training should be used to help restaurants respond to:

- audit findings
- repeated violations
- risk areas
- remediation gaps

### Business Value

- helps convert findings into measurable behavior change
- gives managers a way to reinforce corrective and preventive responses
- creates a stronger link between remediation effort and later audit performance
- supports a true closed-loop improvement model

### Training Types

FiScore should support two main training types:

- full courses
- micro-learning topics

Full courses are suited for onboarding, certifications, and broader compliance refreshers.

Micro-learning topics are suited for:

- violation remediation
- targeted coaching
- just-in-time learning
- short operational refreshers

### Core Capabilities

The Training module should support:

- manager-assigned training
- training linked to violations
- training linked to structured violation responses when relevant
- training linked to audit risk areas
- assignment due dates
- overdue states
- completion tracking
- optional quick knowledge checks
- progress visibility by user and by site

### Best-Practice Expectations

- training should remain short, relevant, and operational
- FiScore should avoid heavy LMS-style complexity in version 1
- the system may recommend training from audit and violation context
- hard auto-assignment should wait unless explicitly enabled later

## Audit Checklist Module

### Feature Summary

The Audit Checklist module enables restaurants to perform structured, repeatable internal inspections and food safety audits using configurable digital checklists. Each checklist can include sections, questions, answer types, trigger logic, predefined notes, and guided follow-up requirements. Based on user responses, the system can automatically create violations for non-compliant findings, while also allowing auditors to manually add violations when needed.

This feature is designed to help restaurant teams standardize audit execution, improve consistency across locations, capture evidence clearly, and turn findings into trackable violations and remediation.

### Business Value

- Standardizes internal inspections across restaurants and teams
- Improves food safety readiness before health department visits
- Helps teams identify risks earlier and take corrective response faster
- Creates more consistent and traceable audit records
- Supports analytics and trend reporting across repeated audits

#### 1A. Audit Scheduling and Recurrence

The system should support scheduling audits for specific dates and recurring inspections by restaurant or site.

Capabilities include:

- schedule an audit for a specific date
- assign a scheduled audit to a specific restaurant or site
- create recurring inspections by restaurant or site
- support recurrence patterns such as daily, weekly, monthly, or custom operational cadence
- generate scheduled audit instances from the recurring definition
- track schedule status clearly

Recommended schedule states include:

- `Scheduled`
- `In Progress`
- `Completed`
- `Overdue`
- `Missed`

Best-practice expectations:

- scheduled audits should be visible before the due date
- overdue audits should remain actionable
- missed audits should remain historically visible and reportable
- recurring schedules should create predictable operational accountability across locations

### Core Capabilities

#### 1. Configurable Checklist Structure

The system should support flexible checklist design so audits can be tailored to different restaurant workflows and regulatory needs.

Capabilities include:

- Checklists with multiple sections
- Multiple questions within each section
- Support for custom checklists and forms
- Support for reusable checklist templates
- Support for FiScore-provided pre-built templates
- Support for location-specific or restaurant-specific checklist variations
- Ordered presentation of sections and questions
- Template metadata such as name, version, owner, tags, and assigned locations

Recommended pre-built template examples:

- food safety
- cleaning and sanitation
- compliance
- daily operational checks

#### 2. Flexible Response Capture

The system should support rich response capture so auditors can document findings clearly and efficiently during an inspection.

Capabilities include:

- Multiple answer types such as pass/fail, yes/no, score, text, numeric, date, and selection-based answers
- Support for short text and long text
- Support for multiple choice and dropdown selection
- Support for numeric measurements with units and threshold validation
- Free-form notes entered by the auditor
- Predefined notes or recommended observations for faster entry
- Optional comments tied to a specific question response
- Evidence capture through images and short videos
- Signature capture where compliance sign-off requires it
- Barcode or QR scan support where the audit program requires it
- Configurable location capture such as GPS where verification needs it
- Lightweight media handling so uploaded evidence does not consume excessive device storage or bandwidth

Media capture best-practice expectations:

- Compress images before upload or sync
- Limit video duration for audit evidence
- Prefer short-form video capture over large continuous recordings
- Store thumbnails and optimized media variants where appropriate
- Queue media uploads for background sync when offline
- Clearly indicate whether media is stored locally, uploading, or synced

#### 3. Conditional and Trigger Logic

The checklist should support dynamic behavior so the audit flow adapts to the user’s responses.

Capabilities include:

- Trigger questions that appear based on previous answers
- Conditional follow-up questions for failed or non-compliant responses
- Force photo upload when certain responses are selected
- Force comment entry when certain responses are selected
- Force violation creation when certain responses are selected
- Suggest training when certain responses are selected
- Flag repeat issues based on prior history
- Required follow-up remediation when certain responses are selected
- Configurable business rules that map specific answers to risk conditions

#### 4. Automatic and Manual Violation Creation

The checklist should support both system-generated and user-generated findings.

Capabilities include:

- Auto-create violations when a response matches a configured non-compliance rule
- Link each auto-created violation back to the audit, section, question, and response that triggered it
- Allow auditors to manually create violations during the audit even when no question directly triggered them
- Allow manual violations even when no predefined trigger rule exists
- Prevent duplicate violations where practical through matching or user confirmation

#### 5. Closed-Loop Corrective Action Workflow

Audit findings should not stop at identification. The system should support remediation tracking through closure.

Capabilities include:

- Assign violations to team members
- Add due dates and remediation notes
- Track violation status from open to closed
- Support either a simple response or a detailed CAPA response
- Allow responses to be submitted for review before closure
- Reopen violations when issues recur or were closed incorrectly
- Maintain history of updates, closures, and reopen events

#### 6. Traceability and Audit History

The system should provide a clear record of what happened during each audit.

Capabilities include:

- Tie every response to the audit session, section, question, user, device, and timestamp
- Record who created a violation and whether it was auto-created or manual
- Preserve response history for key compliance-related updates
- Maintain an audit trail for edits, closures, and follow-up activity
- Preserve template version history for compliance-sensitive audits
- Support stable cross-version linkage using question identifiers where the logical question remains the same
- Preserve recommended or assigned training context when triggered by audit findings

#### 7. Offline Audit Execution

Because audits may be conducted in low-connectivity environments, the feature must support offline-first execution.

Capabilities include:

- Load assigned or relevant checklists on the device before the audit begins
- Allow auditors to complete checklists while offline
- Save responses locally immediately
- Queue responses, violations, and media for background synchronization
- Show sync state clearly so users know whether the audit is saved locally or fully synced

#### 8. Analytics Readiness

Audit checklist data should support reporting and continuous improvement across locations.

Capabilities include:

- Trend analysis by checklist, section, question, restaurant, and date range
- Reporting on repeat failures and recurring violations
- Visibility into completion rates and outstanding violations pending remediation
- Comparisons across locations and audit periods
- Prior-response lookup by site and stable question id
- Comparison of later audit outcomes against prior remediation and training activity

#### 8A. Prior Response Intelligence

The checklist engine should help auditors work faster and with better context by using previous audit information intelligently.

Capabilities include:

- Smart pre-fill of prior answers for the same restaurant or site where configured
- Clear display of the previous audit response at the question level during data entry
- Cross-version linkage within an audit type based on stable question id
- Repeat violation alerts during audits
- Suggested fixes based on prior site history
- Recommended training based on prior failures
- Risk explanations for triggered conditions

Best-practice expectations:

- pre-fill should be assistive rather than silently accepted
- the auditor should always confirm or change the current response
- prior-response lookups should use stable question identity rather than only matching question text

#### 9. Score and Grade Calculation

The Audit Checklist feature should support both a numeric score and a grade outcome for each completed audit.

Capabilities include:

- Support checklist-specific scoring configurations rather than one universal scoring model
- Calculate an audit score as a percentage based on question responses
- Display a grade as a text representation such as `A`, `B`, `C`, `D`, `F` or another configurable grading scale
- Derive the grade primarily from the calculated score using configurable grade thresholds
- Support exception rules where certain serious or critical question responses can lower the grade even if the total score remains relatively high
- Preserve transparency by showing how the score and grade were determined
- Allow business rules to distinguish between general point loss and critical food safety failures

Best-practice expectations:

- Each audit checklist may define its own sections, questions, answer types, weights, thresholds, and critical-response rules
- Scoring rules should be versioned with the checklist so historical audits remain accurate even if the checklist changes later
- Score and grade should be related but not treated as identical
- Score reflects overall audit performance numerically
- Grade reflects the broader compliance outcome and should account for critical findings
- Critical violations or priority failures should be able to cap or reduce the final grade
- The user should be able to understand whether a lower grade came from overall performance, a critical response, or both

Example model:

- Score: `92%`
- Default grade from score threshold: `A`
- Final grade after critical finding rule: `B`

This approach mirrors real-world inspection and quality programs where a location may perform well overall but still receive a reduced grade because of a serious food safety issue.

Scoring should be defined at the audit checklist level. This means each checklist can have its own:

- section structure
- question set
- response options
- scoring weights
- score thresholds
- grade scale
- critical question rules
- grade caps or overrides

This allows FiScore to support different audit programs without forcing all restaurants or audit types into the same scoring model.

### Functional Expectations

The Audit Checklist feature should support the following user outcomes:

- Start an audit from a predefined checklist template
- Schedule an audit for a specific date
- Create recurring inspections by restaurant or site
- Move through sections in a structured sequence
- Answer questions with the appropriate response type
- Add notes, images, and short videos as evidence
- See conditional follow-up questions when triggered
- Automatically generate violations from configured response rules
- Manually add violations during the audit
- View an automatically calculated audit score and grade
- Save progress during the audit, including offline
- Resume an in-progress audit later
- Submit a completed audit and sync it automatically
- Track audits in schedule states such as scheduled, overdue, missed, or completed

### Recommended Best-Practice Positioning

From an industry best-practice perspective, this feature should be positioned as more than a digital checklist. It is a structured compliance workflow that combines:

- Standardized audit execution
- Configurable response logic
- Evidence capture
- Exception-based violation management
- Violation remediation tracking
- Traceable compliance history

That framing reflects how modern inspection and quality systems are typically described in restaurant operations, food safety, and compliance products.

### Scoring and Grading Design Note

From a product and compliance standpoint, FiScore should treat scoring and grading as related but distinct outputs:

- `Score` is the numeric percentage based on response performance across the checklist
- `Grade` is the policy-driven outcome shown to users and may be adjusted by serious findings

This is important because some responses should carry more operational significance than their raw point value alone. A restaurant may achieve a strong percentage score while still having a critical failure that should reduce the final grade and trigger management attention.

Scoring and grading should also be checklist-specific. FiScore should allow each audit checklist template to define the scoring logic that applies to that checklist, so different audit types can reflect different operational priorities, risk levels, and compliance standards.

### Future Enhancements

Potential future improvements may include:

- Voice notes converted to structured observations
- Smart suggestions for remediation based on prior violations
- Checklist scoring models and weighted risk calculations
- Shared checklist libraries by restaurant type or regulatory framework
- Supervisor review and sign-off workflows

### Related Design Reference

See [AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md) for the more detailed checklist-engine design covering template metadata, versioning, question types, conditional logic, required evidence rules, and prior-response behavior.

See [TRAINING_MODULE.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\TRAINING_MODULE.md) for the more detailed training design.
