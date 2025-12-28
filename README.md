# onecummins

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Super Admin Dashboard (Notices & Club Requests)

This project includes a Super Admin dashboard to manage Notices and Club Join Requests.

Features:
- Super Admins can create, edit, and delete notices from the dashboard.
- Notices support an optional link field which is displayed inside the notice card on the Feed (no external navigation).
- Club join requests are stored in `club_join_requests`. Super Admins can accept or decline requests. Accepting adds the club to the user's `clubs` array in the `users` document.

How to use:
1. Sign in using a Super Admin account (the user's `role` should be `super_admin` in the `users` collection).
2. Go to the Dashboard (via the Dashboard button) and open either the Notices Manager or Club Requests.
3. Use the form in Notices Manager to create notices (title and body required; link optional).

Firestore schema (summary):
- `notices` collection: `title`, `body`, `link` (optional), `createdBy`, `createdAt`, `visible`.
- `club_join_requests` collection: `userId`, `userName`, `clubName`, `status` (`pending`/`accepted`/`declined`), `createdAt`, `handledBy`, `handledAt`.

Security rules guidance is available in `docs/firestore_security.md` — **use the emulator to test rules** before deploying.

Notes:
- Feed cards show the notice content inline; long notices are collapsed with an expansion option.
- If you'd like, I can add notifications and email alerts on requests acceptance as a next step.

# One-Cummins
