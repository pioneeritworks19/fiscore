# FiScore Multilingual App Strategy

## Purpose

FiScore should support multilingual restaurant teams without changing the meaning
of operational food-safety content created by inspectors, tenants, or FiScore
library authors.

## Version 1 Scope

Version 1 localization should focus on app-owned visible text:

- navigation labels
- buttons
- status labels
- severity labels
- role labels
- app messages
- validation text
- empty states
- onboarding and authentication copy
- billing and subscription copy when added

Version 1 should not automatically translate authored operational content:

- public inspection text
- violation findings from source agencies
- tenant notes and comments
- checklist questions
- training lessons
- uploaded file names

Those content types should remain in the language in which they were authored.

## Initial Languages

Initial app-shell languages:

- English
- Spanish

Spanish is the first non-English language because many United States restaurant
teams include Spanish-speaking staff.

## Data Model Principle

Firestore should store canonical codes, not translated labels.

Examples:

- `status = open`
- `status = pending_review`
- `severity = critical`
- `role = staff`

The app should map those values to localized display labels at render time.

## Content Localization Later

FiScore library content may later support authored localized variants:

```text
fiscoreLibrary/training/items/{itemId}/localizedContent/{locale}
fiscoreLibrary/checklists/items/{itemId}/localizedContent/{locale}
```

Tenant-owned checklist and training content should remain tenant-authored. If
translation support is added later, translated versions should be explicit
content records rather than silent automatic translations.

## Implementation Notes

The Flutter app uses the standard Flutter localization workflow:

- source strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`
- `l10n.yaml` configures generated output under `lib/l10n/generated`
- app code reads generated `AppLocalizations`
- `MaterialApp.locale` remains nullable by default so the app follows the
  device or browser language
- users can override the language from Profile & preferences

Cloud Function errors should continue to return stable error codes or known
messages. The Flutter app maps those to localized user-facing copy before
showing them.
