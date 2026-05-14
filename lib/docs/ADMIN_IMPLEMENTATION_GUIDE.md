# Admin Role Implementation Guide

## Overview
This guide covers the complete admin role implementation using Firebase custom claims (Option A), with Firestore fallback.

**Key Benefits:**
- ✅ Custom claims embedded in ID token (no extra Firestore reads)
- ✅ Server-side verified (Firestore rules + Cloud Functions)
- ✅ Efficient role checks on client
- ✅ Seamless role updates via token refresh

---

## Architecture

```
┌─────────────────────────────────┐
│   Admin Assignment (Server)     │
│  - Cloud Functions              │
│  - Admin SDK / Manual CLI       │
└──────────────┬──────────────────┘
               │
               ▼
        ┌──────────────┐
        │ Firebase Auth│ ◄─── Sets custom claim: { admin: true }
        │  ID Token    │
        └──────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
    Client       Firestore
   (Dart)        Rules
    │            │
    ├─ Check     ├─ Allow admin-only reads/writes
    │ .claims    │ if request.auth.token.admin == true
    └─ Show UI   │
    └────────────┘
```

---

## 1. Server-Side Setup (Cloud Functions)

### Option 1A: Deploy Cloud Functions (Recommended)

**Step 1: Initialize Firebase Functions**
```bash
cd your-firebase-project
firebase init functions
# Choose TypeScript
# Choose npm
```

**Step 2: Copy the code**
- Place contents from `cloud_functions_admin_example.ts` into `functions/src/index.ts`
- Adjust `ADMIN_EMAILS` environment variable if needed

**Step 3: Install dependencies**
```bash
cd functions
npm install firebase-functions firebase-admin
```

**Step 4: Deploy**
```bash
firebase deploy --only functions
```

**Step 5: (Optional) Set environment variable for auto-promotion**
```bash
firebase functions:config:set admin.emails="admin@example.com,owner@example.com"
firebase deploy --only functions
```

---

### Option 1B: Manual Admin Promotion via CLI

If you don't have Cloud Functions, promote admins manually:

**Using Firebase Admin CLI:**
```bash
npm install -g firebase-tools
firebase login
firebase projects:select <your-project-id>

# Run Node script to set custom claim
node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
admin.auth().setCustomUserClaims('USER_UID_HERE', { admin: true })
  .then(() => console.log('✓ Admin role set'))
  .catch(err => console.error('Error:', err));
"
```

**Get `service-account-key.json`:**
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save as `service-account-key.json` in your project root

---

### Option 1C: Set Custom Claim via Custom Backend

If you have a Node.js/Express backend:

```typescript
import * as admin from 'firebase-admin';

// In your user registration endpoint
app.post('/api/register-admin', async (req, res) => {
  const { email, password } = req.body;
  
  try {
    const user = await admin.auth().createUser({
      email,
      password,
    });
    
    // Set admin claim immediately
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    
    res.json({ uid: user.uid, success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

---

## 2. Client-Side Dart Implementation

### Step 1: Update AuthService (Already done ✅)

The `auth_service.dart` now includes:
- `isAdmin()` — Fast check via custom claims
- `refreshIdToken()` — Refresh after role changes
- `getUserRole()` — Fallback to Firestore

### Step 2: Use AdminGuard in Routes

Wrap admin screens:

```dart
// In main.dart or routing logic
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Refresh token on init to get latest custom claims
    _authService.refreshIdToken();
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: _AdminDashboardContent(authService: _authService),
      fallback: UnauthorizedScreen(), // Shows access denied
    );
  }
}
```

### Step 3: Check Admin in Code

```dart
// Check if current user is admin
final isAdmin = await authService.isAdmin();
if (isAdmin) {
  // Show admin UI
}

// Or get role
final role = await authService.getUserRole();
if (role == AppConstants.roleAdmin) {
  // Admin only
}
```

### Step 4: Call Cloud Function to Change Admin Status

```dart
import 'services/admin_role_service.dart';

// Promote a user to admin (only admins can call this)
final success = await AdminRoleService.setUserAdminRole(
  targetUid: 'user123',
  isAdmin: true,
);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('User promoted to admin')),
  );
  // Refresh current user's token
  await _authService.refreshIdToken();
}
```

---

## 3. Firestore Security Rules (Already Updated ✅)

The `firestore.rules` now:
- Check custom claims first: `request.auth.token.admin == true`
- Fall back to Firestore role
- Protect admin-only collection

Example rule (already in your file):
```firestore
function isAdmin() {
  return isSignedIn() && (
    request.auth.token.admin == true
    || myRole() == 'admin'
  );
}

match /admin/{document=**} {
  allow read, write: if isAdmin();
}
```

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
```

---

## 4. Testing Workflow

### Test 1: Promote First Admin (Local/Console)

**Goal:** Set admin custom claim for a test user

**Steps:**
1. Register a test account (e.g., `admin@test.com`)
2. Note the UID from Firebase Console
3. Use Cloud Function or CLI to set `admin: true`
   ```bash
   # Via CLI
   node -e "const admin = require('firebase-admin'); admin.initializeApp(); admin.auth().setCustomUserClaims('test-uid', { admin: true }).then(() => console.log('✓'));"
   ```

### Test 2: Login and Verify Admin Access

**Goal:** Ensure admin sees admin dashboard

**Steps:**
1. Run your Flutter app
2. Login with admin account
3. Should see `AdminDashboardScreen`
4. Verify `AdminGuard` allows access (no "Access Denied" message)
5. Check logs: `await authService.isAdmin()` should return `true`

### Test 3: Non-Admin Gets Redirected

**Goal:** Ensure regular users can't access admin pages

**Steps:**
1. Login with non-admin account
2. Try to navigate to `/admin`
3. Should see "Access Denied" fallback screen
4. Verify `AdminGuard` shows error

### Test 4: Token Refresh After Role Change

**Goal:** Ensure roles update when custom claims change

**Steps:**
1. Login as admin
2. Open admin dashboard ✅
3. In Cloud Console or backend, change `admin: true` → `admin: false`
4. Tap a button that calls `await authService.refreshIdToken()`
5. Redirect should trigger, showing "Access Denied"
6. Confirm role no longer admin

### Test 5: Firestore Security Rules

**Goal:** Ensure `/admin` collection is protected

**Steps:**
1. In Firebase Console → Firestore → Write a test
   - As non-admin user: Try to write to `/admin/test` → **DENIED** ✅
   - As admin user: Try to write to `/admin/test` → **ALLOWED** ✅

```firestore
// Test query in console (impersonate as user)
db.collection('admin').doc('test').set({ data: 'test' });
// Should fail if not admin
```

---

## 5. Full Integration Checklist

- [ ] **Server:**
  - [ ] Deploy Cloud Functions (or set custom claims via CLI/backend)
  - [ ] Deploy Firestore rules
  - [ ] Test Cloud Function: `setAdminRole` callable

- [ ] **Client:**
  - [ ] Import `admin_guard.dart` in screens
  - [ ] Wrap admin routes with `AdminGuard`
  - [ ] Call `authService.refreshIdToken()` on dashboard init
  - [ ] Import `admin_role_service.dart` for role management

- [ ] **Testing:**
  - [ ] Promote a test user to admin
  - [ ] Login and verify admin screen loads
  - [ ] Login as non-admin, verify "Access Denied"
  - [ ] Test token refresh after role change
  - [ ] Test Firestore rules with console

---

## 6. Production Checklist

Before deploying to production:

- [ ] All Cloud Functions deployed and tested
- [ ] Firestore rules reviewed by security auditor (see `firebase-security-rules-auditor` skill)
- [ ] At least one human admin account set up (not email-based auto-promotion)
- [ ] Admins trained on role management (via Cloud Function or CLI)
- [ ] Audit logging enabled (see `logAdminAction` trigger in cloud functions)
- [ ] Rate limiting on `setAdminRole` function (to prevent abuse)
- [ ] Test fallback: If custom claims unavailable, Firestore role still works

---

## 7. Common Issues & Solutions

### Issue: "You do not have admin permissions"

**Causes:**
- Custom claim not set
- Token not refreshed after claim was set
- ID token expired

**Fix:**
```dart
// Force refresh
await FirebaseAuth.instance.currentUser?.getIdToken(true);
// Then check again
final isAdmin = await authService.isAdmin();
```

### Issue: Cloud Function returns "permission-denied"

**Cause:** Caller doesn't have `admin: true` in custom claims

**Fix:**
1. Verify the calling user is actually an admin
2. Check custom claims: `getIdTokenResult().claims`
3. If missing, set it via CLI first

### Issue: Firestore rule denying admin writes

**Cause:** Rule checking `myRole()` instead of custom claims

**Fix:**
Ensure rule checks custom claims first:
```firestore
function isAdmin() {
  return isSignedIn() && (
    request.auth.token.admin == true  // ← Check this first
    || myRole() == 'admin'
  );
}
```

---

## 8. Performance Notes

- **Custom claims:** Instant check (no Firestore read), embedded in ID token
- **Fallback to Firestore:** One read per check (slower, but works if claims unavailable)
- **Caching:** Consider storing role in app state (Provider/Riverpod) to avoid repeated checks
- **Token refresh:** ~500ms-1s, call only on dashboard init, not every frame

---

## 9. Next Steps

1. Deploy Cloud Functions (or set claims manually)
2. Deploy Firestore rules
3. Test with a real user
4. Set up audit logging
5. Document admin onboarding process
6. Train admins on the system

---

**Need help?** Refer to:
- `ADMIN_SETUP.md` — Detailed Cloud Function setup
- `cloud_functions_admin_example.ts` — Complete function code
- `admin_guard.dart` — Widget implementation
- `admin_role_service.dart` — Callable function wrapper
