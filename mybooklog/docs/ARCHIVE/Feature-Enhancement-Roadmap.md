# MyBookLog — Feature Enhancement Roadmap (Production Readiness for 60+ Users)

**Date:** 2026-07-17
**Purpose of the app:** Help readers aged 60+ keep a trustworthy log of books they've already read, so they never buy a book twice.
**Where we are:** The MVP is solid. The security/performance remediation documented in [[PROJECT_ANALYSIS]] and [[Remediation-Index]] is complete: RLS is enforced everywhere, the add-book flow is atomic, secrets are out of source, session restore works, and there is a small unit-test suite (10 passing). The full flow — sign up → log in → search Google Books → add to shelf → mark read → remove — works end to end. As of today, every source file also carries plain-English comments so a non-programmer can follow the logic.

This note is the gap between "working MVP" and "the best production app for this specific purpose and audience." Recommendations are ordered by how directly they serve the core mission, with a justification for each.

---

## Guiding principle

The moment of truth for this app is **standing in a bookstore (or browsing online), holding a book, asking: "Have I read this?"** Every Tier 1 item exists to make that moment instant, reliable, and possible with imperfect eyesight, imperfect recall of titles, unsteady hands, and poor in-store cell reception. Everything else supports that moment.

---

## Tier 1 — Core-mission features (do these first)

### 1.1 ISBN barcode scanning 📷 — the single highest-value feature
**What:** A big "Scan a Book" button that opens the camera; pointing it at the barcode on the back of any book answers immediately: **"✔ You read this in March 2024"** or **"You have not read this."** (Package: `mobile_scanner`; the ISBN is already the app's identity key, so the lookup is a one-line shelf query.)
**Why it's the winner:** Typing a title on a phone keyboard, in a store, with progressive lenses, is exactly the interaction this audience struggles with most — and titles are misremembered ("was it *The* Thursday Murder Club?"). A barcode is unambiguous, requires zero typing, and directly performs the app's entire reason for existing in ~2 seconds. This also makes **adding** books effortless: scan → confirm → done. It converts the app from "a list I maintain" into "a tool I use in the store."

### 1.2 A dedicated "Have I read this?" check flow
**What:** Alongside "Add Book," an equally prominent entry point ("Check a Book") that searches **the user's own shelf first** and gives a huge, unmissable YES / NO answer screen (green check / neutral "not on your shelf"), with "Add it now?" offered on NO.
**Why:** Today, checking requires: open shelf → tap magnifying glass → type ≥3 characters → visually scan a grid. That's a lookup task disguised as a browsing task. The core question deserves a first-class answer, phrased as an answer — not a filtered grid the user must interpret. Pairs naturally with 1.1 (scan feeds the same check).

### 1.3 Offline-first shelf (local cache)
**What:** Cache the shelf locally (e.g. `sqflite` or even a JSON snapshot) and serve reads from the cache, syncing with Supabase when online. Show a gentle "last updated…" note when offline.
**Why:** Bookstores, library basements, and airport shops have terrible reception. If the answer to "have I read this?" is "Failed to load bookshelf: SocketException," the app has failed at its one job precisely when it was needed. Cover images are already cached (`cached_network_image`); the data should be too. This also makes launch instant.

### 1.4 Typo-tolerant shelf search
**What:** Upgrade `ShelfBook.matchesQuery` from exact substring matching to fuzzy matching (normalize accents/case, ignore leading "The/A," tolerate 1–2 character mistakes — a small Levenshtein/trigram helper, no dependency needed).
**Why:** The current search misses "Gabriel Garcia Marquez" vs "García Márquez" and "Thursday Murder Club" vs "The Thursday Murder Club." For users with imperfect recall — the entire premise of the app — a false "you haven't read this" is the most damaging bug possible: it causes the exact duplicate purchase the app exists to prevent.

### 1.5 A "Want to Read" (wishlist) shelf
**What:** A second list, kept visually separate from "Books I've Read," with a one-tap "I bought it / move to shelf" action.
**Why:** The failure mode isn't only re-buying *read* books — it's also buying a book, forgetting, and buying it again, or buying something a spouse already bought as a gift. A wishlist closes the loop on the whole purchasing decision and answers the bookseller's "anything you're looking for?" moment. Schema impact is small (a `status` column on `bookshelf_items`).

---

## Tier 2 — Account safety & trust (production blockers)

### 2.1 Real "Forgot password" flow ⚠️ currently a stub
**What:** The login screen's "Forgot password?" button currently shows *"Forgot password functionality is not implemented yet."* Wire it to `supabase.auth.resetPasswordForEmail()` with a deep link back into the app.
**Why:** Forgotten passwords are not an edge case in this demographic; they are the *primary* account-recovery path. Right now a user who forgets their password permanently loses their entire reading history — the app's whole value. This is the most important pre-launch fix in the entire document.

### 2.2 Passwordless sign-in option (email magic link / OTP code)
**What:** Offer "Email me a sign-in link/code" as the default, with password as the alternative. Supabase supports both natively.
**Why:** The current policy (8+ chars, letter + number + special character) is a genuine barrier for elders and produces the passwords-on-sticky-notes anti-pattern. A 6-digit code emailed to them matches how their bank already works — familiar, and nothing to remember. Fewer support calls from family members, fewer abandoned accounts.

### 2.3 Account deletion & data export
**What:** A Settings screen with "Download my book list" (CSV/PDF) and "Delete my account" (Supabase RPC that removes auth user + rows).
**Why:** Account deletion in-app is a **hard App Store / Play Store review requirement** — the app can be rejected without it. Export builds trust ("my 40 years of reading isn't hostage") and doubles as a paper backup, which this audience genuinely appreciates.

### 2.4 Confirmation before removing a book
**What:** "Remove Book" currently deletes immediately on menu tap. Add a simple confirm dialog ("Remove *The Overstory* from your shelf? — Remove / Keep"), or an undo action on the snackbar.
**Why:** For a memory-support app, silently losing a record *is* data loss — the user won't notice until they re-buy the book, which is the exact harm the app prevents. Accidental taps from tremor or double-tapping are common in this demographic; destructive actions need a guard.

### 2.5 Graceful email-confirmation handling on signup
**What:** If Supabase email confirmation is enabled, the post-signup snackbar ("Sign up successful! Redirecting...") should instead clearly say "We sent a confirmation link to your email — open it, then log in."
**Why:** The current flow bounces users back to login where their credentials mysteriously fail ("Please confirm your email address" only appears after a confusing failed attempt). First-run confusion is where this audience gives up permanently.

---

## Tier 3 — Usability & accessibility for 60+ (the "best app for this audience" tier)

### 3.1 Make book actions discoverable: tap → detail sheet
**What:** Today, remove/mark-read is reachable **only via press-and-hold** — an invisible gesture. Make a plain **tap** on a book open a bottom sheet: large cover, full title/author, read date, and big labeled buttons ("Mark as Read," "Remove," later "Notes"). Keep long-press as a shortcut.
**Why:** Hidden gestures are the #1 usability failure with older users; there is no on-screen hint that long-press exists. A tap is the one gesture everyone tries first — right now it does nothing. The detail sheet also solves "title truncated to 2 lines" and gives future features (notes, dates) a natural home.

### 3.2 Text labels on the app-bar actions
**What:** Replace icon-only buttons (logout door, magnifying glass, +) with icon+text ("Log out," "Find," "Add") or a labeled bottom navigation bar.
**Why:** Icon literacy is generation-dependent; a plus sign is guessable, the logout icon is not (and it's placed top-left where "back" usually lives — easy to tap accidentally, and it signs you out with no confirmation). Labels cost nothing and remove all guesswork. Consider moving Log out into a Settings screen entirely.

### 3.3 Respect the system font-size setting, and test at 200%
**What:** Audit every screen with the OS font scaling at maximum. Fix layouts that break (the 3-column grid's fixed `childAspectRatio: 0.48` will clip titles; several hardcoded `fontSize:` values ignore theme text styles).
**Why:** Large system fonts are *the* accessibility setting this audience actually uses. The app's base sizes are already generous (16–18pt — good!), but honoring the user's own setting is what makes it feel made for them. Related: offer a "Larger covers" toggle switching the grid to 2 columns.

### 3.4 Screen-reader labels (VoiceOver / TalkBack)
**What:** Add `Semantics` labels: each shelf book announces "The Overstory, Richard Powers, read" instead of nothing; the read badge, selection checkmarks, and app-bar buttons all get labels.
**Why:** Low vision is on a spectrum; many users mix large text with occasional screen-reader use. The book grid is currently images with visual-only badges — invisible to assistive tech. This is cheap to add now and required for any accessibility claim in store listings.

### 3.5 Clearer "read" indication
**What:** The read badge is a 22 px checkmark dot. Supplement it with a text ribbon ("READ") across the cover corner, or a distinct band under the cover with the read date ("Read · Mar 2024").
**Why:** A small green dot at arm's length with reading glasses off is easy to miss — and misreading "unread" as "read" defeats the purpose. Redundant encoding (color + text + position) is basic accessible design. The `marked_read_on` date is already stored but never shown; surfacing it adds real recall value ("oh yes, last spring").

### 3.6 First-run gentle onboarding
**What:** A 3-screen intro on first launch (big text, one idea per screen): "Add the books you've read" → "In the store? Scan or search to check" → "Tap any book for options." Skippable, revisitable from Settings.
**Why:** This audience reads instructions when they're short and friendly, and abandons apps they can't figure out in the first minute. Thirty seconds of orientation replaces the family-member phone call.

### 3.7 Pull-to-refresh + larger-touch affordances
**What:** Add `RefreshIndicator` on the shelf; keep honoring the ≥48 px touch targets already in the theme (good!), and increase snackbar display duration (default 4 s is short for slower readers — use 6–8 s or add a dismiss button).
**Why:** Pull-to-refresh is the one gesture this audience *has* learned (from Facebook/email). Longer-lived messages ensure confirmations ("Book added!") are actually read, not just flashed.

---

## Tier 4 — Depth features (retention & delight)

### 4.1 Personal notes & a simple "Did I like it?" rating
**What:** On the detail sheet (3.1): a thumbs up / neutral / thumbs down and a free-text note ("Loved the sister character; too slow in the middle").
**Why:** The purchasing question is really two questions: "Have I read this?" and "Did I *like* this author enough to buy another?" A one-tap sentiment answers the second — arguably as much money saved as the first. Notes also make the log a keepsake, which drives long-term attachment. (Schema: `rating smallint`, `notes text` on `bookshelf_items`.)

### 4.2 Browse by author + sort options
**What:** A toggle to group/sort the shelf by author, date read, or date added (data already exists). Search already matches authors; browsing should too.
**Why:** Readers in this demographic are heavily author-loyal ("I read everything by Ann Cleeves"). "What have I read by this author?" is the second most common bookstore question, and today it requires typing the author into search.

### 4.3 Manual book entry
**What:** A small "Can't find it? Add it yourself" form (title, author, optional year/photo) creating a catalog row with a generated internal identifier in place of the ISBN.
**Why:** Google Books misses older, regional, self-published, and large-print editions — disproportionately what this audience reads. A book the user *knows they read* but cannot log breaks trust in the whole log. (The `add_book_to_shelf` RPC needs a variant that doesn't require an ISBN.)

### 4.4 Open Library as a search fallback
**What:** When Google Books returns nothing (or errors/hits quota), retry against the Open Library API (free, no key) before showing "no results."
**Why:** Redundancy for the app's only third-party dependency; also reduces the blast radius of the Google API key/quota. The service layer is already cleanly injectable, so this is a contained change.

### 4.5 Shared/family shelf visibility (later, but uniquely valuable)
**What:** Optional read-only share: a spouse or adult child can view (not edit) the shelf from their own device — e.g. via a share code.
**Why:** Book purchases in this demographic are frequently made *by family members as gifts*. "Check Mom's shelf before buying" prevents the duplicate-gift problem the user can't solve alone. This is the standout differentiator no generic book tracker offers; design carefully (privacy, revocation) and ship after the core is polished.

---

## Tier 5 — Production engineering (invisible, but required)

| Item | Why |
|------|-----|
| **Crash reporting** (Sentry/Crashlytics) | This audience won't file bug reports — they'll silently stop using the app. Crash telemetry is the only feedback channel you'll actually get. |
| **CI pipeline** (GitHub Actions: `flutter analyze` + `flutter test` on PR) | The test suite exists and passes; making it un-skippable keeps the remediated security posture ([[Remediation-Index]]) from regressing. |
| **Widget/integration tests for the money paths** | Unit tests cover pure logic only. Add widget tests for login, add-book, and mark-read flows with a mocked Supabase client — the flows whose breakage directly destroys user trust. |
| **Google Books API key restrictions + quota alarm** | Restrict the key to the app's bundle IDs and set a quota alert; a leaked or exhausted key currently kills search silently. |
| **Store readiness**: privacy policy, app icons for all platforms, screenshots with large-text captions | Both stores require the policy; marketing to this audience should show the large-type UI proudly. |
| **Shelf pagination safety valve** | `fetchShelf` loads everything; fine to 500+ books, but add a sane `limit`/paging before someone imports a lifetime library. |
| **Session-expiry handling** | If the Supabase token can't refresh mid-session, surface a calm "Please log in again" instead of raw `NotAuthenticatedException` text. |

---

## Aesthetic recommendations

The "oatmeal & sage" identity is genuinely good — calm, bookish, high-contrast where it counts. These items finish the job:

### A.1 Bundle the fonts the theme asks for ⚠️
The theme specifies **Merriweather** (headings) and **Inter** (body), but no font files are declared in `pubspec.yaml` — so on real devices everything silently falls back to Georgia/Roboto. Either bundle the two font families as assets or use `google_fonts`. **Value:** the intended typographic personality (a warm serif for headings is *very* right for a book app and this audience) currently doesn't render for anyone. Two fonts, one pubspec stanza.

### A.2 Finish (or defer) dark mode, and persist + expose the choice
`darkTheme` lacks card, dialog, popup-menu, chip, and snackbar styling (light-styled surfaces will pop up inside dark screens), `ThemeProvider` resets to light on every restart, and **no UI control calls `toggleTheme()` at all** — dark mode is currently unreachable dead code. Either add a Settings toggle + `shared_preferences` persistence and complete the theme, or remove it until ready. **Value:** dark mode matters for glare sensitivity and nighttime reading in bed — both elevated in this audience; a half-dark UI is worse than none.

### A.3 Give the shelf a shelf
The covers "float" on flat oatmeal. Add a subtle horizontal shelf line/wooden ledge under each grid row (the unused `assets/images/woodwork-oak-background.jpg` in the repo suggests this was the original intent — it's currently dead weight; use it or delete it). **Value:** the skeuomorphic bookshelf metaphor is instantly legible to this audience ("these are *my books*"), adds warmth, and visually separates rows, aiding scanning. Keep it subtle to preserve contrast.

### A.4 A real splash and brand mark
The splash is plain default-font text ("crafted with love") with a spinner. Use the Merriweather wordmark, a simple book glyph/logo, and the oatmeal background so first impression matches the brand. Also replace the default Flutter web/Android icons (only iOS has a custom icon). **Value:** first-launch polish signals trustworthiness — this audience is (rightly) wary of unpolished apps asking for accounts.

### A.5 Warmer empty and error states
Empty shelf is a bare sentence in accent-green 16pt. Replace with a friendly illustration (empty wooden shelf), a headline, and one big primary button ("Add your first book"). Error snackbars currently leak raw exceptions (`Failed to load bookshelf: SocketException...`) — route them through a `friendlyMessage`-style mapper like auth already has. **Value:** empty state is the first-run screen every new user sees; raw exception text reads as "the app is broken" and erodes the trust the log depends on.

### A.6 Consistent typography on auth screens
Login's title and several labels use hardcoded `TextStyle`s instead of the theme (so they miss the serif identity and won't respond to future theme changes). Sweep screens to use `Theme.of(context).textTheme`. **Value:** consistency, and it makes the font-size work in 3.3 land everywhere at once.

---

## Suggested sequencing

1. **Pre-launch blockers:** 2.1 forgot-password · 2.3 account deletion · 2.4 remove-confirmation · 2.5 signup messaging · A.1 fonts · A.2 resolve dark mode · Tier 5 crash reporting + CI
2. **The mission release:** 1.1 barcode scan · 1.2 check flow · 1.3 offline cache · 1.4 fuzzy search · 3.1 detail sheet · 3.2 labeled actions
3. **The audience-fit release:** 3.3–3.7 accessibility sweep · 3.6 onboarding · A.3–A.6 polish · 1.5 wishlist
4. **The delight release:** 4.1 notes/ratings · 4.2 author browsing · 4.3 manual entry · 4.4 Open Library fallback
5. **The differentiator:** 4.5 family shelf sharing

---

## Google Books API key setup

**For the new key you're generating:**
1. **Project:** Dedicate a project to MyBookLog only. Blast radius of any future leak stays contained.
2. **Enable the API:** *APIs & Services → Library → Books API → Enable*. The key won't work without this.
3. **Create and restrict the key:**
   - **Name:** `mybooklog-dev` (or similar — you'll rotate it later).
   - **API restrictions:** Select *Books API only*. If the key leaks, an attacker can only search books, not abuse Maps/Translate or incur charges.
   - **Application restrictions:** Choose *None* (for now). Your app doesn't yet send the Android/iOS identity headers that would enforce per-platform restrictions, and `com.example.mybooklog` is a placeholder you'll rename before store release.
4. **Billing:** Leave unlinked. Books API is free (1,000 requests/day default). No billing account = a stolen key can't cost money.
5. **Delete the old leaked key** from the Credentials screen once the new one is in your gitignored `env.json` and search works.

**Before store release:** Create two additional keys—`mybooklog-android` (restricted to your final Android app ID + release-signing SHA-1) and `mybooklog-ios` (restricted to your final iOS bundle ID)—and add identity headers to `GoogleBooksService` so each platform uses its own key. That's the "API key restrictions + quota alarm" item from Tier 5.

---

*Related notes: [[PROJECT_ANALYSIS]] (initial audit), [[Remediation-Index]] (completed security/perf fixes), [[ARCH-2-appconfig]] (config architecture).*



----
