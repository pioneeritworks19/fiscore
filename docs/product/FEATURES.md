# FiScore Features

## Platform Direction

FiScore should be designed as a restaurant operations and compliance platform rather than a single-purpose inspection viewer.

Version 1 is centered on:

- public health department inspections
- internal audits
- actions and violations
- corrective action workflows

However, the product should leave room for future operational modules such as:

- asset tracking
- complaint tracking
- additional location operations workflows

This direction should influence navigation, data boundaries, and overall app structure from the beginning so the platform can grow without needing a full redesign later.

## Actions Module

### Feature Summary

The Actions module gives FiScore a unified workflow for tracking, assigning, responding to, reviewing, and closing follow-up work across restaurant operations and compliance. Actions may originate from health department inspections harvested from government websites, from internal audits conducted by restaurant staff, from manual entry during day-to-day operations, or from recurring operational needs that are not tied to a specific inspection or audit.

Violation is one action type within this broader module. Every action should follow a clear lifecycle so teams can move from identification to remediation with full traceability. Users should be able to respond with either a simple response or a more detailed Corrective and Preventive Action (CAPA) workflow, attach lightweight evidence such as photos, short videos, or supporting documents, collaborate with teammates, and route the action for review when needed.

### Business Value

- Centralizes follow-up work across external inspections, internal audits, and operational tasks
- Helps restaurants respond consistently to food safety issues
- Supports accountability through assignment, review, and closure workflows
- Creates traceable remediation records for compliance and operational follow-up
- Gives owners and managers visibility into unresolved, recurring, and high-risk issues

### Action Types

FiScore should support multiple action types under one common workflow framework.

Initial action types should include:

- violation
- operational task
- recurring task

This allows FiScore to evolve beyond inspection-specific follow-up into a broader restaurant operations system.

### Action Sources

FiScore should support actions originating from multiple sources while preserving source context.

Supported sources include:

- Health department inspections harvested from government websites
- Internal audits conducted by restaurant staff
- Auto-created violations triggered from audit checklist responses
- Manually created actions entered by users
- Recurring operational tasks created by the system or administrators

Each action should retain source metadata so users can understand where it came from and report on it accurately.

Suggested source fields:

- action type
- source type
- source system or agency
- source inspection or audit id
- originating checklist question when applicable
- date identified

### Action Lifecycle

Every action should have a clear lifecycle regardless of source.

Recommended lifecycle states:

- `Open`
- `In Progress`
- `Pending Review`
- `Closed`
- `Reopened`

Best-practice expectations:

- New actions begin in `Open` unless created as draft records
- Work performed by staff can move an action to `In Progress`
- Users can submit a completed response for manager review, moving it to `Pending Review`
- Restaurant managers or owners can approve and close actions
- Closed actions can be reopened if the issue recurs, the response is insufficient, or the condition fails verification
- Lifecycle transitions should be traceable by user, timestamp, and device

### Recurring Actions and Tasks

The system should support recurring actions and tasks for operational work that needs to happen on a repeated cadence.

Capabilities include:

- create recurring actions for repeatable operational work
- assign recurring actions to one or more restaurants
- define recurrence patterns such as daily, weekly, or monthly
- create individual action instances from the recurring definition
- track completion history of recurring tasks over time

Examples:

- weekly line check
- monthly equipment check
- recurring sanitation verification task

### Response Types

Users should be able to choose a response style that matches the severity and complexity of the issue.

#### 1. Simple Response

Simple responses are designed for straightforward issues that can be resolved quickly.

Typical contents:

- response notes
- corrective action taken
- completion date
- lightweight photo or short video evidence
- supporting document when needed

#### 2. Detailed CAPA Response

For more serious or recurring issues, FiScore should support a structured Corrective and Preventive Action workflow.

Typical CAPA contents:

- issue summary
- root cause
- corrective action
- preventive action
- responsible person
- target completion date
- verification notes
- evidence attachments
- review outcome

This allows teams to document not only how they fixed the issue, but also how they will prevent it from happening again.

### Evidence Attachments

Action responses should support lightweight supporting evidence without creating excessive storage or sync problems.

Supported evidence types:

- images
- short videos
- documents

Best-practice expectations:

- Compress images before sync or upload
- Limit video length and optimize files for mobile capture
- Support background upload and sync for media when the device reconnects
- Show attachment status such as saved locally, uploading, synced, or failed
- Keep evidence tied to the specific action and response event

### Collaboration and Chat

The system should support built-in collaboration on follow-up work.

Capabilities include:

- conversation or comment thread within an action
- timestamped discussion history
- collaboration between assignees, managers, and reviewers
- activity visibility for updates, evidence uploads, and status changes

This allows users to coordinate work inside the action itself rather than relying on external messaging tools.

### Review and Closure Workflow

FiScore should support a flexible but controlled closeout process.

Capabilities include:

- Users can resolve an action and close it directly if allowed by role and policy
- Users can submit an action response for review instead of closing it directly
- Restaurant managers or owners can review submitted responses and close the action
- Reviewers should be able to reject the response, request more work, or reopen the violation
- Closure should preserve who closed the violation, when it was closed, and what evidence supported closure

### Configurable Action Workflows

FiScore should support configurable action types and action workflows.

Capabilities include:

- define action types such as violation, operational task, and recurring task
- configure which fields are required for each action type
- configure status transitions by action type
- configure review requirements by action type
- configure evidence or collaboration requirements by action type

Violation should be one action type within this broader action framework.

### Source-Specific Context

Although all actions share a common lifecycle, source type still matters for reporting and user context.

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

#### Standalone Operational Actions

These are not tied directly to a public inspection or internal audit and should preserve:

- manually created action source
- restaurant context
- action type
- assignment and recurrence context if applicable

### Action Display and Representation

Actions should support different display formats depending on their type, source, and level of detail. Not every action will have the same structure, and the UI should be able to present both simple and richly contextualized records without forcing them into one rigid format.

Common display patterns include:

- plain-text action title with an action type
- official health department clause or code with descriptive text
- checklist-based context such as section, question, and response
- a combined representation that includes both a user-friendly summary and the underlying structured source details

Examples:

- `Improper cold holding`
- `Handwashing sink not properly stocked`
- `Clause 3-501.16: Cold holding temperatures above safe limit`
- `Food Storage > Are raw and ready-to-eat foods separated? > No`
- `Weekly sanitizer test verification`

Best-practice expectations:

- The system should always store a readable action summary for list views and notifications
- The system should also preserve structured source context when available
- Users should be able to see both the normalized action record and the source details behind it
- Health department violations should preserve official language where available
- Internal audit violations should preserve checklist context such as section, question, and triggering response where available

### Functional Expectations

The Actions module should support the following user outcomes:

- View actions from health department inspections, internal audits, and standalone operational work in one system
- Filter actions by type, source, restaurant, status, assignee, severity, and due date
- Create actions manually outside audits when supported
- Create recurring actions/tasks
- Auto-create violation-type actions from audit responses
- Add a simple response or a detailed CAPA response
- Attach lightweight photos, short videos, and documents
- Collaborate through built-in action comments or chat
- Save and update action responses offline where applicable
- Submit actions for review
- Allow managers or owners to review and close actions
- Reopen actions when needed
- Maintain a full response and status history

### Recommended Best-Practice Positioning

From an industry best-practice perspective, this feature should be positioned as a closed-loop action and remediation system rather than a simple issue list. The value comes from combining:

- unified action intake across multiple sources
- structured remediation workflows
- configurable action types
- recurring operational tasks
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

## Audit Checklist Module

### Feature Summary

The Audit Checklist module enables restaurants to perform structured, repeatable internal inspections and food safety audits using configurable digital checklists. Each checklist can include sections, questions, answer types, trigger logic, predefined notes, and guided follow-up actions. Based on user responses, the system can automatically create violations for non-compliant findings, while also allowing auditors to manually add violations when needed.

This feature is designed to help restaurant teams standardize audit execution, improve consistency across locations, capture evidence clearly, and turn findings into trackable corrective actions.

### Business Value

- Standardizes internal inspections across restaurants and teams
- Improves food safety readiness before health department visits
- Helps teams identify risks earlier and take corrective action faster
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
- Force action creation when certain responses are selected
- Required follow-up actions when certain responses are selected
- Configurable business rules that map specific answers to risk conditions

#### 4. Automatic and Manual Violation Creation

The checklist should support both system-generated and user-generated findings.

Capabilities include:

- Auto-create violations when a response matches a configured non-compliance rule
- Link each auto-created violation back to the audit, section, and question that triggered it
- Allow auditors to manually create violations during the audit
- Allow manual violations even when no predefined trigger rule exists
- Prevent duplicate violations where practical through matching or user confirmation

#### 5. Closed-Loop Corrective Action Workflow

Audit findings should not stop at identification. The system should support remediation tracking through closure.

Capabilities include:

- Assign violations to team members
- Add due dates and corrective action notes
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
- Maintain an audit trail for edits, closures, and follow-up actions
- Preserve template version history for compliance-sensitive audits
- Support stable cross-version linkage using question identifiers where the logical question remains the same

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
- Visibility into completion rates and outstanding corrective actions
- Comparisons across locations and audit periods
- Prior-response lookup by site and stable question id

#### 8A. Prior Response Intelligence

The checklist engine should help auditors work faster and with better context by using previous audit information intelligently.

Capabilities include:

- Smart pre-fill of prior answers for the same restaurant or site where configured
- Clear display of the previous audit response at the question level during data entry
- Cross-version linkage within an audit type based on stable question id

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
- Corrective action tracking
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
- AI-assisted photo classification for common food safety issues
- Smart suggestions for corrective actions based on prior violations
- Checklist scoring models and weighted risk calculations
- Shared checklist libraries by restaurant type or regulatory framework
- Supervisor review and sign-off workflows

### Related Design Reference

See [AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md) for the more detailed checklist-engine design covering template metadata, versioning, question types, conditional logic, required evidence rules, and prior-response behavior.
