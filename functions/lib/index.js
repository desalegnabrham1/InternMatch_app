"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAdminUsers = exports.setAdminRole = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
/**
 * Callable function to set/unset admin claim for a user.
 * Caller must already be admin (checked via custom claims).
 * Payload: { uid: string, isAdmin: boolean }
 */
exports.setAdminRole = functions.https.onCall(async (data, context) => {
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
        await db.collection('users').doc(targetUid).set({
            isAdmin: isAdminFlag,
            role: isAdminFlag ? 'admin' : 'user',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return { success: true, message: `Admin status set to ${isAdminFlag} for ${targetUid}` };
    }
    catch (err) {
        const msg = err?.message || String(err);
        throw new functions.https.HttpsError('internal', `Failed to set admin role: ${msg}`);
    }
});
/** Optional: callable to list admin UIDs (for admin UIs) */
exports.getAdminUsers = functions.https.onCall(async (data, context) => {
    if (!context.auth || context.auth.token.admin !== true) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can view admin users.');
    }
    try {
        const snapshot = await db.collection('users').where('isAdmin', '==', true).get();
        const adminUids = snapshot.docs.map((d) => d.id);
        return { adminUids, count: adminUids.length };
    }
    catch (err) {
        throw new functions.https.HttpsError('internal', err?.message || String(err));
    }
});
//# sourceMappingURL=index.js.map