// Firebase Cloud Functions for Admin Role Management
// 
// Deploy to your Firebase project:
// 1. Initialize functions if not done: firebase init functions
// 2. Place this code in functions/src/index.ts
// 3. Run: npm install && firebase deploy --only functions
//
// TypeScript code that can be adapted for your backend.

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const auth = admin.auth();
const db = admin.firestore();

/**
 * CALLABLE: Set admin status for a user.
 * Only admin users (verified via custom claims) can call this.
 * 
 * Accessible from Flutter via:
 * ```dart
 * final callable = FirebaseFunctions.instance.httpsCallable('setAdminRole');
 * await callable.call({'uid': 'user123', 'isAdmin': true});
 * ```
 */
export const setAdminRole = functions.https.onCall(async (data, context) => {
  // 1. Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated."
    );
  }

  // 2. Verify caller is admin (check custom claims)
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can assign admin roles."
    );
  }

  // 3. Validate input
  const targetUserId = data.uid;
  const isAdmin = data.isAdmin === true;

  if (!targetUserId || typeof targetUserId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "uid is required and must be a string."
    );
  }

  try {
    // 4. Set custom claim in Firebase Auth
    await auth.setCustomUserClaims(targetUserId, {
      admin: isAdmin,
    });

    // 5. Update Firestore user doc for redundancy
    await db.collection("users").doc(targetUserId).update({
      isAdmin,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 6. Return success
    return {
      success: true,
      message: `Admin status set to ${isAdmin} for ${targetUserId}`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : String(error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to set admin role: ${errorMessage}`
    );
  }
});

/**
 * CALLABLE: Get list of all admin user IDs.
 * Only admins can call this.
 */
export const getAdminUsers = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can view admin users."
    );
  }

  try {
    // Query Firestore for users with isAdmin = true
    const snapshot = await db
      .collection("users")
      .where("isAdmin", "==", true)
      .select("email")
      .get();

    const adminUids = snapshot.docs.map((doc) => ({
      uid: doc.id,
      email: doc.data().email,
    }));

    return {
      adminUids,
      count: adminUids.length,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : String(error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to fetch admin users: ${errorMessage}`
    );
  }
});

/**
 * TRIGGER: Auto-promote users with whitelisted emails on creation.
 * Useful for onboarding the first admin.
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const adminEmails = process.env.ADMIN_EMAILS?.split(",") || [
    "admin@example.com",
  ];

  if (adminEmails.includes(user.email || "")) {
    try {
      // Set custom claim
      await auth.setCustomUserClaims(user.uid, { admin: true });

      // Set Firestore doc
      await db.collection("users").doc(user.uid).set(
        {
          email: user.email,
          role: "admin",
          isAdmin: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          displayName: user.displayName || "",
        },
        { merge: true }
      );

      console.log(
        `Promoted ${user.email} (${user.uid}) to admin via whitelist.`
      );
    } catch (error) {
      console.error(`Failed to promote admin: ${error}`);
    }
  }
});

/**
 * CALLABLE: Revoke admin role.
 * Only admins can call this.
 */
export const revokeAdminRole = functions.https.onCall(
  async (data, context) => {
    if (!context.auth || context.auth.token.admin !== true) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can revoke admin roles."
      );
    }

    const targetUserId = data.uid;

    if (!targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required."
      );
    }

    try {
      await auth.setCustomUserClaims(targetUserId, { admin: false });
      await db.collection("users").doc(targetUserId).update({
        isAdmin: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: `Admin role revoked for ${targetUserId}`,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to revoke admin role: ${errorMessage}`
      );
    }
  }
);

/**
 * TRIGGER: Log admin actions to audit collection.
 * Helpful for compliance and debugging.
 */
export const logAdminAction = functions.firestore
  .document("users/{uid}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if isAdmin changed
    if (before?.isAdmin !== after?.isAdmin) {
      const uid = context.params.uid;

      try {
        await db.collection("admin").doc("audit-logs").collection("logs").add({
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          action: "admin_role_changed",
          targetUid: uid,
          from: before?.isAdmin || false,
          to: after?.isAdmin || false,
          email: after?.email,
        });
      } catch (error) {
        console.error(`Failed to log admin action: ${error}`);
      }
    }
  });
