# Tenant Admin Console Source Layout

The admin console is organized around feature-owned modules with a thin app shell.

- `app/`: top-level React app, view state, and routing between admin console surfaces.
- `features/*/*Page.tsx`: feature-owned page/detail components rendered by the app shell.
- `features/*/service.ts`: Firestore subscriptions and callable Function wrappers owned by each feature.
- `features/*/types.ts`: feature-specific TypeScript models.
- `features/auth/`: authentication helpers.
- `shared/firebase/`: Firebase clients and low-level helpers shared across features.
- `shared/i18n/`: i18next setup.
- `shared/types/`: cross-feature types such as roles, user profile, and activity.
- `shared/utils/`: shared utility helpers and error formatting.

`src/data.ts` and `src/types.ts` remain as compatibility barrels for the current `App.tsx` surface.
New code should import from the owning feature or shared module directly. When extracting UI,
prefer moving a whole route/detail page into its feature folder before introducing shared
components.
