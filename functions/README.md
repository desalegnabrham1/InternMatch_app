# Cloud Functions for Internship Finder

This folder contains simple Firebase Cloud Functions used to manage admin roles.

Files:
- `src/index.ts` — callable functions `setAdminRole` and `getAdminUsers`.

Deploy:

1. Install dependencies:

```bash
cd functions
npm install
```

2. Build & deploy:

```bash
npm run build
firebase deploy --only functions:setAdminRole,getAdminUsers
```

Note: Caller must be an admin (custom claim) to call `setAdminRole`.
