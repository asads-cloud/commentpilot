# _lib — Shared Utilities

This folder contains shared helper modules used by all API routes under `src/api/`.  
Each file in here is **pure, isolated, and dependency-light**, focusing on reusability and clarity.

---

## 📦 Current Modules

| File | Purpose |
|------|----------|
| `auth.ts` | JWT verification and authentication helpers (Cognito + `jose`). |
| `http.ts` *(planned)* | Standardized JSON and CORS response helpers. |
| `errors.ts` *(planned)* | Centralized application error types and HTTP status mapping. |
| `validation.ts` *(planned)* | Reusable Zod schemas for request/response validation. |
| `log.ts` *(optional)* | Simple structured logging utility. |

---

## 🔐 `auth.ts`

### Overview

Provides functions for verifying and extracting authenticated users from **Cognito JWTs**.  
Uses [`jose`](https://github.com/panva/jose) under the hood with caching, rotation, and strict validation.

### Environment Variables

| Variable | Description | Example |
|-----------|--------------|----------|
| `COGNITO_ISSUER` | Cognito issuer URL | `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_123ABC` |
| `COGNITO_AUDIENCE` | Cognito App Client ID | `abcd1234exampleclientid` |

### Exports

| Function | Description |
|-----------|--------------|
| `verifyJwt(authHeader?: string)` | Verifies a Bearer token and returns the decoded payload. Throws `AuthError` (401) on failure. |
| `requireAuth(headers?: Record<string, string | undefined>)` | Convenience wrapper — extracts `Authorization` header and calls `verifyJwt`. |
| `getAuthHeader(headers)` | Case-insensitive helper to retrieve the `Authorization` header. |
| `AuthError` | Custom error type used for all auth-related failures. |

### Example

```ts
import { requireAuth } from "../_lib/auth";

export const handler = async (event) => {
  const user = await requireAuth(event.headers);
  console.log("User:", user.sub);
};
```

---

## 🧱 Design Principles

- **Single Responsibility:** Each module has a single, narrow concern.  
- **Pure Functions:** No side effects or shared mutable state.  
- **Runtime Safety:** Fail early with clear messages (for both logs and clients).  
- **AWS-Friendly:** All modules are Lambda-compatible and lightweight.

---

## 🧭 Adding a New Utility

1. Create a new file in `_lib/` (e.g., `logger.ts` or `storage.ts`).  
2. Keep dependencies minimal and avoid hard-coded environment variables.  
3. Export only what’s needed; avoid circular imports.  
4. Add a short doc block at the top describing purpose and usage.  
5. If public (imported by routes), add a short section for it in this README.

---

## ✅ Example Structure

```
src/api/_lib/
├─ auth.ts         # JWT auth (Cognito)
├─ http.ts         # JSON + CORS responses (shared)
├─ errors.ts       # Typed errors → HTTP mapper
├─ validation.ts   # Zod schemas for requests
└─ log.ts          # Optional logger wrapper
```
