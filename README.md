# EMR Homemade

An Electronic Medical Record system built for small psychiatric clinics — designed around a single practicing doctor's real workflow rather than a generic hospital EMR feature list.

Cross-platform (Android, Windows, macOS, Linux) via Flutter, backed by Supabase (Postgres) with Row Level Security as the actual security boundary.

## Why this exists

Most EMR software is built for hospitals: multi-department, multi-role, heavyweight. A solo or small-clinic psychiatrist doesn't need that — they need patient records, visit notes, prescriptions, and psychological assessment scoring that are fast to fill in during a consultation and safe to run on a single clinic PC or phone.

This project also documents its own evolution: it started on a MySQL/PHP-style schema and was migrated to Supabase/Postgres with Auth and RLS, with the migration reasoning kept in the SQL comments rather than thrown away.

## Features

- **Patients** — records, search, contact info (supports multiple phone numbers per patient — patient, parent, guardian).
- **Visits (Kunjungan)** — chief complaint, history, physical exam, vitals (BP, temperature, pulse, respiration rate, pain scale), mental status exam, diagnosis, therapy plan. A "previous visit" reference card surfaces relevant history while filling in a new visit, with one-tap copy of prior data.
- **Prescriptions (Resep)** — per-visit prescriptions with an allergy check against the patient's known allergies and a drug-interaction checker.
- **Psychological assessments** — scored against configurable instruments (questions, scoring categories, interpretation rules), with full history per patient.
- **Medications & drug interactions** — a maintained drug database with pairwise interaction data.
- **Dashboard** — patient/visit statistics at a glance.
- Responsive layout: the same screens adapt between a desktop sidebar and a phone-width single-column layout, down to dialog width and touch targets.

## Tech stack

- **Flutter** / Dart, `provider` for state management
- **Supabase**: Postgres, Auth, and PostgREST as the API layer — no custom backend server
- **Row Level Security** is the actual security boundary, not client-side checks. The anon key is meant to be extractable from the distributed binary; every table has RLS enabled with policies scoped to `authenticated` only, and `anon` has no policies at all (see `supabase/migrations/0001_init.sql`).

## Getting started

```bash
flutter pub get
cp lib/config/supabase_config.dart.example lib/config/supabase_config.dart
# fill in your Supabase project URL + anon key
```

Apply the SQL migrations in `supabase/migrations/` (in order) to a Supabase project via the SQL editor or `supabase db push`, create a user under Authentication (accounts are provisioned manually, not from the app), then:

```bash
flutter run
```

## Testing

```bash
flutter test
```

`test/` covers the parts of the app where a silent regression would be dangerous rather than just annoying — e.g. that a cached page actually refetches data when revisited instead of showing stale patient lists, and that error dialogs surface the real failure reason instead of a generic message.
