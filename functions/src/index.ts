import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Callable function to set/unset admin claim for a user.
 * Caller must already be admin (checked via custom claims).
 * Payload: { uid: string, isAdmin: boolean }
 */
export const setAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can assign admin roles.');
  }

  const targetUid = data?.uid;
  const isAdminFlag = data?.isAdmin === true;
  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'uid is required.');
  }

  try {
    // 1) Set custom claim via Admin SDK
    await admin.auth().setCustomUserClaims(targetUid, { admin: isAdminFlag });

    // 2) Update Firestore users doc for redundancy (merge)
    await db.collection('users').doc(targetUid).set(
      {
        isAdmin: isAdminFlag,
        role: isAdminFlag ? 'admin' : 'user',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { success: true, message: `Admin status set to ${isAdminFlag} for ${targetUid}` };
  } catch (err: any) {
    const msg = err?.message || String(err);
    throw new functions.https.HttpsError('internal', `Failed to set admin role: ${msg}`);
  }
});

/** Optional: callable to list admin UIDs (for admin UIs) */
export const getAdminUsers = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can view admin users.');
  }

  try {
    const snapshot = await db.collection('users').where('isAdmin', '==', true).get();
    const adminUids = snapshot.docs.map((d) => d.id);
    return { adminUids, count: adminUids.length };
  } catch (err: any) {
    throw new functions.https.HttpsError('internal', err?.message || String(err));
  }
});
