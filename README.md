# app-admin (Admin Web)

Flutter Web admin dashboard for Glmoi.

What you get in this repo:
- Login (Firebase Auth)
- Integrated dashboard (app list)
- App admin area (currently implemented for `maumsori` / Glmoi-admin style)
- Firestore + Storage integration (content, config, image pool)

This repo is intended to be usable from a fresh checkout with minimal context.

## System Info / Tooling

Known working versions in this workspace:
- Flutter: 3.38.9 (stable)
- Dart: 3.10.8

Core deps (see `pubspec.yaml`):
- State: Riverpod (`flutter_riverpod`)
- Routing: `go_router`
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- Upload UX (web): `image_picker` (single), `flutter_dropzone` (drag-and-drop bulk)

## Quick Start (Local)

Install deps:

```bash
flutter pub get
```

Run (Dev / Stg / Prod):

```bash
# DEV
flutter run -d chrome -t lib/main_dev.dart

# STG
flutter run -d chrome -t lib/main_stg.dart

# PROD
flutter run -d chrome -t lib/main_prod.dart
```

Build and serve a release build locally:

```bash
flutter build web -t lib/main_dev.dart --release
python3 -m http.server 5001 --directory build/web
```

Notes:
- Prefer `lib/main_dev.dart` / `lib/main_stg.dart` / `lib/main_prod.dart` as entrypoints.
- `lib/main.dart` uses `lib/firebase_options.dart` and may point to a different Firebase project.

## Firebase Setup (Required)

This admin web expects 3 Firebase projects (one per environment):
- `glmoi-dev`
- `glmoi-stg`
- `glmoi-prod`

Per project:
1) Authentication enabled (Email/Password)
2) Create at least one admin account (same email can be used across projects)
3) Firestore + Storage enabled
4) Add a Web App in the Firebase console (for web config)

### Rules (Minimum Safety)

This codebase assumes Firestore and Storage are restricted.

If using an email allowlist, set it consistently across Firestore + Storage.

Firestore Rules must be under Firestore (not Storage):

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return request.auth != null
        && request.auth.token.email == "vinus@vinus.co.kr";
    }

    match /quotes/{docId} {
      allow read, write: if isAdmin();
    }

    match /image_assets/{docId} {
      allow read, write: if isAdmin();
    }

    match /config/{docId} {
      allow read, write: if isAdmin();
    }

    // Used for admin-only duplicate prevention.
    // The app creates a doc per normalized content hash.
    match /dedup_quotes/{docId} {
      allow read, write: if isAdmin();
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Storage Rules must be under Storage:

```rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null
        && (request.auth.token.email == "vinus@vinus.co.kr");
    }
  }
}
```

If you see `permission-denied`:
- The app shows `email` + `projectId` in the UI to help debug.
- Verify the Firebase project you are running against matches the rules you edited.

### Admin Operations (Email Allowlist)

This project currently uses a simple admin gate via Firebase Rules email allowlist.

What it means:
- Anyone can have a Firebase Auth account, but only allowlisted emails can read/write Firestore/Storage.
- Adding/removing an admin requires a Rules change in each environment.

Add an admin (repeat for DEV/STG/PROD):
1) Firebase console -> Authentication -> Users
2) Create the user (Email/Password) or confirm it already exists
3) Update Firestore Rules + Storage Rules to allow the email
4) Publish rules
5) Ask the admin to sign out/in (or hard refresh) to ensure token state is clean

Remove an admin:
1) Remove the email from Firestore Rules + Storage Rules
2) Publish rules
3) Optionally disable/delete the Auth user in Authentication -> Users

Recommended hardening (optional):
- Add `request.auth.token.email_verified == true` to Rules
- Keep one company-owned "break-glass" admin email to avoid lockouts

Operational downside:
- Admin changes require applying the same Rules edits to 3 separate Firebase projects.

Future alternative (recommended when the admin list grows):
- Use Firebase custom claims (`admin=true`) and gate Rules with `request.auth.token.admin == true`.
  This avoids frequent Rules deploys, but requires an Admin SDK script/process.

### Indexes (Composite Index)

Firestore queries in this project require composite indexes.
When you see an error like:

`failed-precondition: The query requires an index`

Use the link in the error message OR open:
- DEV: `https://console.firebase.google.com/project/glmoi-dev/firestore/indexes`
- STG: `https://console.firebase.google.com/project/glmoi-stg/firestore/indexes`
- PROD: `https://console.firebase.google.com/project/glmoi-prod/firestore/indexes`

Create the required indexes per environment (indexes do not propagate across projects).

#### Recommended Index Checklist (This Repo)

These are the composite indexes commonly required by the current query patterns in:
- `lib/features/maumsori/data/repositories/quote_repository.dart`
- `lib/features/maumsori/data/repositories/image_repository.dart`

Create them in each environment project (DEV/STG/PROD):

Quotes (`quotes` collection)
- List (official content): `app_id` Asc, `is_user_post` Asc, `createdAt` Desc
- List (official content, with type filter): `app_id` Asc, `is_user_post` Asc, `type` Asc, `createdAt` Desc
- User posts (glmoi): `app_id` Asc, `is_user_post` Asc, `createdAt` Desc
- User posts (with approval filter): `app_id` Asc, `is_user_post` Asc, `is_approved` Asc, `createdAt` Desc
- Reported posts (sorted by report_count then recency): `app_id` Asc, `report_count` Desc, `createdAt` Desc
- Top posts (like_count): `app_id` Asc, `is_active` Asc, `like_count` Desc

Image assets (`image_assets` collection)
- Image pool (uploaded_at): `app_id` Asc, `is_active` Asc, `uploaded_at` Desc
- Image pool (usage_count): `app_id` Asc, `is_active` Asc, `usage_count` Desc

Note:
- Firestore may not require every index depending on which screens you use.
- If you see an index error, the console link in the error message always points to the exact missing index.

## Environment Parity Checklist

When bootstrapping or diagnosing a broken environment, verify this in DEV/STG/PROD:
- Auth: Email/Password enabled
- Auth: Admin user exists (and credentials are known to the operators of that env)
- Firestore Rules: `service cloud.firestore` rules published
- Storage Rules: `service firebase.storage` rules published
- Firestore Indexes: required composite indexes are "Enabled" (not "Building")
- Storage bucket exists and matches the project (`*.firebasestorage.app`)

Quick smoke test per env:
1) Login
2) Open `/maumsori/dashboard`
3) Add one quote (composer)
4) Upload one image (image pool)

## Deploy Vs Sync (Operational)

This repo has two separate "push" concepts:

1) Code deploy (Flutter Web)
- Changes like UI tweaks (tab order, layouts), bug fixes, and new admin features.
- To apply to PROD, you must build and deploy to Firebase Hosting.

2) Settings/data sync (Firestore)
- Changes stored in Firestore (categories, composer defaults, ad config, terms, bad-words rules).
- DEV and PROD are separate Firebase projects, so Firestore changes do NOT automatically propagate.

If you "synced" but a UI change did not apply, that is expected: UI is code.

### DEV -> PROD Settings Sync (Exclude Content/Images)

The admin UI includes a DEV-only helper to copy settings docs from DEV to PROD.

Where:
- Settings -> "콘텐츠 설정" tab -> "운영 반영 (DEV -> PROD)"

Scope (copied and overwritten in PROD):
- `config/app_config`
- `config/ad_config`
- `config/terms_config`
- `admin_settings/bad_words`

Excluded:
- Content and images (ex: `quotes`, `image_assets`, Storage objects)

Security:
- This helper is only shown when the current `projectId` is `glmoi-dev`.
- For safety, it prompts for PROD admin email/password on every sync.

Implementation:
- `lib/features/maumsori/presentation/screens/settings_screen.dart` (sync logic)

Note:
- This is client-side and performs writes to PROD from the browser, so keep PROD Rules strict.
- If you need a more defensible approach, move the sync into a prod-side backend (Callable/HTTPS)
  and require prod auth + admin claim there.

## App Flow / Routes

Auth gating is handled via `go_router` redirect:
- Unauthed users -> `/login`
- Authed users -> `/`

Key routes are in `lib/core/router/app_router.dart`:
- `/login` -> Login
- `/` -> Integrated dashboard
- `/maumsori/*` -> App admin (currently implemented)
  - `/maumsori` redirects to `/maumsori/dashboard`

## Directory Structure (Important Paths)

Top-level:
- `lib/` Flutter source
- `web/` Flutter web host files (HTML, manifest)
- `test/` tests (minimal)
- `PRD.md` product requirements (detailed)

Core:
- `lib/main_dev.dart` DEV Firebase entrypoint
- `lib/main_stg.dart` STG Firebase entrypoint
- `lib/main_prod.dart` PROD Firebase entrypoint
- `lib/main.dart` default entrypoint (may point elsewhere)
- `lib/core/auth/auth_service.dart` Firebase Auth wrapper
- `lib/core/router/app_router.dart` routes + auth redirects
- `lib/core/theme/app_theme.dart` UI theme

Integrated dashboard:
- `lib/features/dashboard/presentation/screens/root_dashboard.dart`
  - App list cards
  - `maumsori` card routes into `/maumsori` (dashboard landing)

App admin (currently `maumsori` namespace):
- `lib/features/maumsori/presentation/screens/maumsori_dashboard_screen.dart`
- `lib/features/maumsori/presentation/screens/content_list_screen.dart`
- `lib/features/maumsori/presentation/screens/content_composer_screen.dart`
- `lib/features/maumsori/presentation/screens/image_pool_screen.dart`
- `lib/features/maumsori/presentation/screens/glemoi_screen.dart`
- `lib/features/maumsori/presentation/screens/ad_management_screen.dart`
- `lib/features/maumsori/presentation/screens/settings_screen.dart`

Data layer:
- `lib/features/maumsori/data/models/quote_model.dart`
- `lib/features/maumsori/data/models/image_asset_model.dart`
- `lib/features/maumsori/data/models/config_model.dart`
- `lib/features/maumsori/data/repositories/quote_repository.dart`
- `lib/features/maumsori/data/repositories/image_repository.dart`
- `lib/features/maumsori/data/repositories/config_repository.dart`

## Firestore Schema (Operational Contract)

This section documents fields that are relied on by the admin web.

`quotes` (collection)
- `app_id` string (default: `maumsori`)
- `type` string: `quote` | `thought` | `malmoi`
- `content` string
- `author` string
- `category` string
  - For `type=quote` this is currently stored as an empty string
- `image_url` string|null
- `font_style` string: `gothic` | `serif`
- `createdAt` timestamp
- `is_active` bool
- `is_user_post` bool
- `is_approved` bool
- `report_count` number
- `like_count` number
- `share_count` number

`image_assets` (collection)
- `app_id` string
- `original_url` string
- `thumbnail_url` string
- `webp_url` string|null
- `uploaded_at` timestamp
- `width` number
- `height` number
- `file_size` number
- `usage_count` number
- `is_active` bool

`config/app_config` (document)
- `min_version` string
- `latest_version` string
- `is_maintenance_mode` bool
- `maintenance_message` string
- `categories` array<string>
- `composer_font_size` number (default: 24)
- `composer_line_height` number (default: 1.6)
- `composer_dim_strength` number (default: 0.4)
- `composer_font_style` string: `gothic` | `serif` (default: gothic)

`dedup_quotes` (collection)
- Used internally to prevent duplicate official/admin content.
- Contains one doc per dedup key.

## Storage Naming / Image Pool

When uploading images, this project renames Storage objects to a stable, collision-resistant format:
- Path: `assets/{appId}/images/{timestamp}_{random}.{ext}`
- Implementation: `lib/features/maumsori/data/repositories/image_repository.dart`

Image pool supports:
- Single upload (file picker)
- Bulk upload via drag-and-drop (web)

If preview does not show:
- The UI now renders loading/error state; check Storage Rules and the stored `thumbnailUrl`.

### Storage CORS (Web Preview)

If an image URL opens in a new tab but does not render inside the admin UI (grid preview), this is often a Storage CORS issue.

Symptom:
- `Image.network(...)` fails inside the Flutter Web app
- The same `https://firebasestorage.googleapis.com/...` URL works when opened directly

Fix (DEV example):
1) Ensure you have `gsutil` available (Google Cloud SDK).

On macOS (Homebrew):

```bash
brew install --cask gcloud-cli
```

2) Authenticate with an account that has permission to update Storage buckets.

```bash
gcloud auth login --update-adc
gcloud auth list
```

3) Create/update `cors.json` (this repo includes a starter at `cors.json`).

Important:
- CORS is stored on the bucket, not on a PC. Once applied, it affects all users accessing the bucket from allowed origins.
- When you deploy the admin web and connect a custom domain, you must add the production domain(s) to the `origin` list and re-apply.

```json
[
  {
    "origin": [
      "http://localhost:5001",
      "http://localhost:5002",
      "http://127.0.0.1:5001",
      "http://127.0.0.1:5002"
    ],
    "method": ["GET", "HEAD", "OPTIONS", "POST", "PUT"],
    "responseHeader": [
      "Content-Type",
      "Authorization",
      "x-goog-resumable"
    ],
    "maxAgeSeconds": 3600
  }
]
```

4) Apply to the Storage bucket(s):

```bash
gsutil cors set cors.json gs://glmoi-dev.firebasestorage.app
```

Alternatively, use the helper script in this repo:

```bash
scripts/apply_storage_cors.sh cors.json \
  gs://glmoi-dev.firebasestorage.app \
  gs://glmoi-stg.firebasestorage.app \
  gs://glmoi-prod.firebasestorage.app
```

Repeat per environment bucket (stg/prod).

When you register a production domain:
- Add it to `cors.json` under `origin` (example: `https://admin.example.com`).
- Re-apply CORS to each environment bucket.

If login keeps selecting the wrong Google account:
- Use a dedicated Chrome profile or Incognito.
- This repo also includes `scripts/open_chrome_fresh.sh` to open a URL in a fresh Chrome profile.

## Hosting (Firebase Hosting)

"Deploying the admin web" means:
- Build Flutter web output
- Host it (recommended: Firebase Hosting)
- Optionally connect a custom domain

You do not need separate third-party hosting if you use Firebase Hosting.

Typical flow:
1) Build:

```bash
flutter build web -t lib/main_prod.dart --release
```

2) Deploy to Firebase Hosting (per env project):
- Use `firebase init hosting` and `firebase deploy` in the corresponding Firebase project.
- Connect a custom domain in Firebase Hosting settings.

If a deploy "seems not applied":
- Hard refresh the browser (Cmd/Ctrl+Shift+R).
- Try Incognito.
- Confirm the UI shows the intended `projectId`.

After domain connection:
- Update Storage CORS origins to include the deployed domain(s) and re-apply.

## Functions (Image Optimization)

Goal:
- When an image is uploaded to Storage, automatically generate:
  - a small thumbnail (for image pool previews)
  - a WebP optimized variant (for background usage)
- Write generated URLs back to Firestore `image_assets` fields:
  - `thumbnail_url`
  - `webp_url`

Planned structure:
- Keep Cloud Functions source code under `functions/` in this repo.
- Deploy the same functions to each Firebase project so behavior matches per environment:
  - `glmoi-dev`
  - `glmoi-stg`
  - `glmoi-prod`

Deployment policy:
- Treat dev/stg/prod as separate deployments.
- Do not assume changes in one project propagate to the others.

Note:
- This section documents the intended setup. The `functions/` directory may be added later.

## Text Rendering (Word Wrap)

Requirement:
- Preview and actual app UI must wrap text by word boundaries (space-delimited) instead of breaking inside words.

Admin implementation:
- This repo provides `lib/core/widgets/word_wrap_text.dart` (`WordWrapText`) and uses it in admin preview surfaces.

Long content (Thought / Glmoi) must be scrollable:
- "좋은생각" and "글모이" can be long-form content. In both the admin preview and the end-user Android app,
  the content area should allow vertical scrolling when text exceeds the viewport.
- In admin, previews are wrapped with `SingleChildScrollView` + `Scrollbar` so newlines are preserved and long
  content remains readable.

IMPORTANT (mobile app):
- When integrating/maintaining the end-user app, apply the same approach in the app rendering code (content cards/detail/preview) so wrapping behavior matches the admin preview.

## Troubleshooting

`cloud_firestore/permission-denied`
- Firestore Rules are not allowing the current user.
- Ensure you edited Firestore Rules under Firestore (not Storage).
- Confirm the email shown in the UI matches your allowlist.
- If you just changed rules, refresh the page or sign out/in.

`failed-precondition: The query requires an index`
- Create the index in the environment project (dev/stg/prod) using the console link.

"I edited rules but nothing changed"
- Firestore Rules and Storage Rules are edited in different console sections.
- Make sure you clicked Publish.
- Ensure you edited the correct Firebase project (dev/stg/prod).

## PRD

See `PRD.md` for feature scope and operational specs.

## Bad Words Filtering (Glmoi)

Glmoi allows both admins and end-users to write content. To keep the service clean,
this repo includes a bad-words dictionary (Firestore) + regex rules (optional), and
client-side real-time filtering for the admin composer.

### Dictionary Location (Firestore)

Bad words config doc:
- `admin_settings/bad_words` (document)

Schema (high-level):
- `enabled` bool (default: true)
- `schema_version` number (default: 1)
- `updatedAt` timestamp
- `rules` map (dictionary), keyed by rule id:
  - `mode`: `plain` | `regex`
  - `value`: string
  - `enabled`: bool
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

Admin UI:
- Settings -> "콘텐츠 설정" tab includes a "금지어 규칙 (글모이)" section.

Implementation:
- Model: `lib/features/maumsori/data/models/bad_words_model.dart`
- Repo: `lib/features/maumsori/data/repositories/bad_words_repository.dart`
- UI: `lib/features/maumsori/presentation/screens/settings/widgets/bad_words_settings_section.dart`

### Search/Match Rules (Normalization)

The goal is to catch obfuscations like `씨.발`, `씨~발`, `씨1발` while keeping the
logic fast enough for real-time input validation.

Plain rule matching:
- Normalize the input by removing whitespace + punctuation + symbols.
- Keep Hangul syllables and Latin letters.
- Digits are removed by default, but are kept when the rule contains digits
  (ex: `010`).
- A plain rule matches if `normalizedInput.contains(normalizedRule)`.

Regex rule matching:
- Regex patterns are evaluated against both:
  - the raw text
  - the normalized text (digits kept)
- Invalid regex patterns are rejected in the admin UI.

Implementation:
- `lib/features/maumsori/domain/bad_words/bad_words_matcher.dart`

### Default Seed Words

When `admin_settings/bad_words` does not exist yet, the admin app seeds a default
list on first load of Settings/Composer:

- 씨발, 개새끼, 병신, 좆, 씌발
- 좌빨, 수꼴, 대깨, 토착왜구
- 사이비, 개독
- 대출, 카지노, 토토
- 주식 리딩방, 밴드 가입
- 010
- 노인네, 틀딱, 꼰대

### Server-Side Validation (Functions)

Firestore background triggers cannot synchronously reject a write. If you need the
server to *block* saves and return an error, route writes through a Callable
function and deny direct client writes in Firestore Rules.

This repo includes a starter callable:
- `badWordsValidate` (Callable)

Functions source:
- `functions/src/index.ts`
- `functions/src/badWords.ts`
