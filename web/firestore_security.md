# Firestore Security Rules for OneCampus

This document contains recommended Firestore security rules for the new `notices` and `club_join_requests` collections.

Important: adjust collection names and fields to match your final schema and test thoroughly in the Firestore Rules simulator.

---

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: basic read/write for own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update, delete: if request.auth != null && request.auth.uid == userId;
    }

    // Notices: only super_admin can create, update, or delete
    match /notices/{noticeId} {
      allow read: if true; // public

      allow create: if isSuperAdmin();
      allow update, delete: if isSuperAdmin();
    }

    // Club join requests: authenticated users can create a request for themselves; only super admins can change status
    match /club_join_requests/{reqId} {
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;

      // Everyone can read requests (adjust as needed)
      allow read: if request.auth != null;

      // Only super admin can update status to "accepted" or "declined" and set handledAt/handledBy
      allow update: if isSuperAdmin() &&
        (request.resource.data.status in ['accepted', 'declined', 'pending']) &&
        (request.resource.data.handledBy == request.auth.uid || request.resource.data.handledBy == resource.data.handledBy);

      allow delete: if isSuperAdmin();
    }

    // Helper function
    function isSuperAdmin() {
      return request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
  }
}

---

Testing guidance
- Use the Firebase emulator to test rules locally.
- Create tests that simulate: a normal user creating a club_join_request, then attempted status changes by a non-admin (should fail), and status change by a super_admin (should succeed).
- Test notice creation/update/delete only authenticated super_admin can perform these actions.

Deployment
- Use `firebase deploy --only firestore:rules` (after `firebase init` and configuring project) to deploy rules.
