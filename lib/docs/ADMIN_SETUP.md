/// Server-Side Admin Role Assignment (Cloud Functions)
/// 
/// This guide shows how to set custom claims for admin users.
/// Deploy this function to Firebase Cloud Functions.
///
/// Option 1: Callable Function (Recommended for app integration)
/// ─────────────────────────────────────────────────────────────
/// 
/// File: functions/src/index.ts
/// 
/// ```typescript
/// import * as functions from 'firebase-functions';
/// import * as admin from 'firebase-admin';
/// 
/// admin.initializeApp();
/// 
/// /// Callable function: Set admin status for a user.
/// /// Requires: caller must be admin (verified via custom claims).
/// /// Usage: from Flutter, call via CloudFunctions.instance.httpsCallable('setAdminRole')
/// exports.setAdminRole = functions.https.onCall(async (data, context) => {
///   // Check if caller is admin
///   if (!context.auth || !context.auth.token.admin) {
///     throw new functions.https.HttpsError(
///       'permission-denied',
///       'Only admins can assign admin roles.'
///     );
///   }
/// 
///   const targetUserId = data.uid;
///   const isAdmin = data.isAdmin === true;
/// 
///   if (!targetUserId) {
///     throw new functions.https.HttpsError(
///       'invalid-argument',
///       'uid is required.'
///     );
///   }
/// 
///   try {
///     // Set custom claim
///     await admin.auth().setCustomUserClaims(targetUserId, { admin: isAdmin });
/// 
///     // Update Firestore for redundancy
///     await admin.firestore()
///       .collection('users')
///       .doc(targetUserId)
///       .update({ isAdmin, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
/// 
///     return { success: true, message: `Admin status set to ${isAdmin} for ${targetUserId}` };
///   } catch (error) {
///     throw new functions.https.HttpsError(
///       'internal',
///       `Failed to set admin role: ${error instanceof Error ? error.message : String(error)}`
///     );
///   }
/// });
/// ```
///
/// Deploy:
/// ```bash
/// cd functions
/// npm install
/// firebase deploy --only functions:setAdminRole
/// ```
///
/// ─────────────────────────────────────────────────────────────
/// 
/// Option 2: On Registration (Admin SDK in Backend)
/// 
/// If you have a custom backend (Express, etc.), set admin claim there:
/// 
/// ```typescript
/// app.post('/api/register-admin', async (req, res) => {
///   const { email, password } = req.body;
/// 
///   try {
///     // Create user via Admin SDK
///     const user = await admin.auth().createUser({ email, password });
/// 
///     // Set admin claim
///     await admin.auth().setCustomUserClaims(user.uid, { admin: true });
/// 
///     res.json({ uid: user.uid, success: true });
///   } catch (error) {
///     res.status(400).json({ error: error instanceof Error ? error.message : String(error) });
///   }
/// });
/// ```
/// 
/// ─────────────────────────────────────────────────────────────
///
/// Option 3: Manual via Firebase Console or Admin CLI
/// 
/// Using Firebase Admin CLI:
/// ```bash
/// npm install -g firebase-tools
/// firebase login
/// firebase projects:list
/// firebase projects:select <project-id>
/// node -e "const admin = require('firebase-admin'); admin.initializeApp(); admin.auth().setCustomUserClaims('USER_UID', { admin: true }).then(() => console.log('Done')).catch(console.error);"
/// ```
///
/// ─────────────────────────────────────────────────────────────
///
/// Option 4: Programmatic Promotion (Onboarding Flow)
/// 
/// Example: Promote user to admin if they sign up with whitelisted email:
/// 
/// ```typescript
/// exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
///   const adminEmails = ['admin@example.com', 'owner@example.com'];
///   
///   if (adminEmails.includes(user.email || '')) {
///     await admin.auth().setCustomUserClaims(user.uid, { admin: true });
///     await admin.firestore()
///       .collection('users')
///       .doc(user.uid)
///       .set({
///         role: 'admin',
///         email: user.email,
///         createdAt: admin.firestore.FieldValue.serverTimestamp(),
///       });
///   }
/// });
/// ```
///
/// ═════════════════════════════════════════════════════════════
///
/// KEY POINTS:
/// 
/// 1. Custom claims are embedded in the ID token and available instantly
///    in `getIdTokenResult().claims` on the client.
/// 
/// 2. Always refresh the token after changing claims:
///    `await user.getIdToken(true)` (forceRefresh=true)
/// 
/// 3. Security: Custom claims are verified server-side (Firestore rules),
///    never trust client-side checks alone.
/// 
/// 4. Fallback: Store `role` in Firestore user document for backup role lookup.
/// 
/// 5. Efficient: Custom claims avoid extra Firestore reads per check.
///
/// ═════════════════════════════════════════════════════════════
