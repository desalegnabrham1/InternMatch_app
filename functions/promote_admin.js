#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');
const admin = require('firebase-admin');

const ROOT_DIR = path.resolve(__dirname, '..');
const FIREBASE_RC_PATH = path.join(ROOT_DIR, '.firebaserc');
const GOOGLE_SERVICES_PATH = path.join(ROOT_DIR, 'android', 'app', 'google-services.json');
const FIREBASE_TOOLS_PATH = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function loadProjectId() {
  const firebaserc = readJsonIfExists(FIREBASE_RC_PATH);
  if (firebaserc && firebaserc.projects && firebaserc.projects.default) {
    return firebaserc.projects.default;
  }

  const firebaseTools = readJsonIfExists(FIREBASE_TOOLS_PATH);
  if (firebaseTools && firebaseTools.activeProjects) {
    const activeProject = firebaseTools.activeProjects[ROOT_DIR] || Object.values(firebaseTools.activeProjects)[0];
    if (activeProject) return activeProject;
  }

  const googleServices = readJsonIfExists(GOOGLE_SERVICES_PATH);
  if (googleServices && googleServices.project_info && googleServices.project_info.project_id) {
    return googleServices.project_info.project_id;
  }

  throw new Error('Unable to determine Firebase project ID.');
}

function loadApiKey() {
  const googleServices = readJsonIfExists(GOOGLE_SERVICES_PATH);
  const apiKey = googleServices?.client?.[0]?.api_key?.[0]?.current_key;
  if (apiKey) return apiKey;
  throw new Error('Unable to read Firebase Web API key from android/app/google-services.json.');
}

function loadCliAuth() {
  const firebaseTools = readJsonIfExists(FIREBASE_TOOLS_PATH);
  const token = firebaseTools?.tokens?.access_token;
  const expiresAt = firebaseTools?.tokens?.expires_at;
  if (!token) return null;
  if (typeof expiresAt === 'number' && expiresAt < Date.now()) {
    throw new Error('Firebase CLI access token is expired. Run `firebase login` and try again.');
  }
  return {
    accessToken: token,
    projectId: loadProjectId(),
  };
}

function buildServiceAccountCredential(serviceAccountPath) {
  const resolvedPath = path.resolve(serviceAccountPath);
  if (!fs.existsSync(resolvedPath)) {
    throw new Error(`Service-account file not found: ${resolvedPath}`);
  }

  const stats = fs.statSync(resolvedPath);
  const candidatePath = stats.isDirectory()
    ? fs.readdirSync(resolvedPath)
        .filter((name) => name.toLowerCase().endsWith('.json'))
        .map((name) => path.join(resolvedPath, name))
        .find((filePath) => {
          try {
            const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            return content && content.project_id && content.client_email && content.private_key;
          } catch (_) {
            return false;
          }
        })
    : resolvedPath;

  if (!candidatePath || !fs.existsSync(candidatePath)) {
    throw new Error(`No usable service-account JSON found at: ${resolvedPath}`);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(candidatePath, 'utf8'));
  return admin.credential.cert(serviceAccount);
}

async function httpJson(url, { method = 'GET', headers = {}, body } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await response.text();
  const parsed = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const message = parsed?.error?.message || text || `HTTP ${response.status}`;
    throw new Error(message);
  }

  return parsed;
}

async function lookupUserByEmail(projectId, accessToken, email) {
  const response = await httpJson(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:lookup`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      body: { email: [email] },
    },
  );
  return response?.users?.[0] || null;
}

async function createUserWithPassword(apiKey, email, password) {
  const response = await httpJson(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`,
    {
      method: 'POST',
      body: {
        email,
        password,
        returnSecureToken: false,
      },
    },
  );
  return response;
}

async function updateAuthUser(projectId, accessToken, localId, updates) {
  return httpJson(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:update`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      body: {
        localId,
        ...updates,
      },
    },
  );
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (value && typeof value === 'object' && value.__timestamp === true) {
    return { timestampValue: new Date().toISOString() };
  }
  return { stringValue: String(value) };
}

async function patchFirestoreUser(projectId, accessToken, uid, data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    fields[key] = toFirestoreValue(value);
  }

  await httpJson(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${encodeURIComponent(uid)}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      body: {
        fields,
      },
    },
  );
}

function getCredentialMode() {
  const serviceAccountPath = process.argv[4] || process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (serviceAccountPath) {
    return { mode: 'service-account', credential: buildServiceAccountCredential(serviceAccountPath) };
  }

  const cliAuth = loadCliAuth();
  if (cliAuth) {
    return { mode: 'cli-access-token', credential: cliAuth };
  }

  throw new Error('No usable Firebase credentials found. Set FIREBASE_SERVICE_ACCOUNT_PATH or sign in with `firebase login`.');
}

async function main() {
  const target = process.argv[2];
  const password = process.argv[3];

  if (!target) {
    console.error('Usage: node promote_admin.js <uid|email> [password] [serviceAccountJsonPath]');
    console.error('If no service-account is provided, the script uses the Firebase CLI login cache from your machine.');
    process.exit(2);
  }

  try {
    const { mode, credential } = getCredentialMode();

    if (mode === 'service-account') {
      admin.initializeApp({ credential });
      const userRecord = target.includes('@')
        ? await admin.auth().getUserByEmail(target)
        : await admin.auth().getUser(target);

      if (password) {
        await admin.auth().updateUser(userRecord.uid, {
          password,
          emailVerified: true,
        });
      }

      await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
      await admin.firestore().collection('users').doc(userRecord.uid).set({
        role: 'admin',
        isAdmin: true,
        email: userRecord.email || target,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(`Success: set admin claim for uid=${userRecord.uid} (${userRecord.email})`);
      return;
    }

    const projectId = credential.projectId;
    const accessToken = credential.accessToken;
    const apiKey = loadApiKey();

    let user = null;
    if (target.includes('@')) {
      user = await lookupUserByEmail(projectId, accessToken, target);
      if (!user && !password) {
        throw new Error(`No Firebase Authentication account exists for ${target}.`);
      }
      if (!user && password) {
        const created = await createUserWithPassword(apiKey, target, password);
        user = {
          localId: created.localId,
          email: target,
        };
      }
    } else {
      const lookup = await httpJson(
        `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:lookup`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
          body: { localId: [target] },
        },
      );
      user = lookup?.users?.[0] || null;
      if (!user) {
        throw new Error(`No Firebase Authentication account exists for UID ${target}.`);
      }
    }

    const uid = user.localId || user.uid;
    const email = user.email || target;

    if (password) {
      await updateAuthUser(projectId, accessToken, uid, {
        password,
        emailVerified: true,
      });
    }

    await updateAuthUser(projectId, accessToken, uid, {
      customAttributes: JSON.stringify({ admin: true }),
      emailVerified: true,
    });

    await patchFirestoreUser(projectId, accessToken, uid, {
      role: 'admin',
      isAdmin: true,
      email,
      updatedAt: { __timestamp: true },
    });

    console.log(`Success: set admin claim for uid=${uid} (${email})`);
  } catch (err) {
    console.error('Error:', err && err.message ? err.message : err);
    process.exit(1);
  }
}

main();
