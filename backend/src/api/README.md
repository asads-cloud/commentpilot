# API Layer — `backend/src/api`

This directory contains all AWS Lambda **HTTP handlers** that power the backend API.  
Each folder under `src/api/` represents a single route or shared library module.

The API is designed for **clarity, safety, and maintainability** — optimised for a solo developer or small team.

---

## 🧭 Overview

| Folder | Purpose |
|:--------|:---------|
| `_lib/` | Shared utilities (auth, error handling, JSON helpers, validation). |
| `getMessages/` | `GET /getMessages` — fetches recent messages from DynamoDB. |
| `postReply/` | `POST /postReply` — stub endpoint to send or queue replies. |
| `node_modules/` | Local dependencies (ignored in repo docs). |

---

## ⚙️ Core Concepts

### 🔐 Authentication
- Implemented via **Amazon Cognito** JWTs verified using [`jose`](https://github.com/panva/jose).  
- See [`_lib/auth.ts`](./_lib/auth.ts) for details.  
- All routes require an `Authorization: Bearer <token>` header.

### 🌐 CORS
- Each route uses permissive CORS headers (`*`) for development convenience.  
  Adjust before production deployment.

### ⚠️ Error Handling
- Common patterns:
  - `401 Unauthorized` → Invalid or missing JWT  
  - `400 BadRequest` → Malformed input  
  - `405 MethodNotAllowed` → Disallowed HTTP method  
  - `500 InternalError` → Unexpected server issue  
- Each route defines its own small helper for JSON responses.  
  A shared `_lib/http.ts` is planned.

### 🧱 Environment Variables

| Variable | Purpose | Example |
|-----------|----------|----------|
| `DDB_TABLE` | DynamoDB table name for messages | `myapp-messages` |
| `COGNITO_ISSUER` | Cognito issuer URL | `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXX` |
| `COGNITO_AUDIENCE` | Cognito App Client ID | `abcd1234exampleclientid` |

---

## 📂 Directory Tree

```
src/api/
├─ _lib/                # Shared logic (auth, http, errors, etc.)
│  ├─ auth.ts
│  └─ README.md
│
├─ getMessages/         # GET /getMessages
│  ├─ index.ts
│  └─ README.md
│
├─ postReply/           # POST /postReply
│  ├─ index.ts
│  └─ README.md
│
└─ node_modules/        # Dependencies (excluded from docs)
```

---

## 🚀 Running Locally

To test locally (Node 18+ required):

```bash
# install dependencies
npm install

# build (if using TypeScript)
npm run build

# run a specific handler
node dist/api/postReply/index.js
```

Or with AWS SAM / Serverless Framework:

```bash
sam local invoke PostReplyFunction   --event events/postReply.json   --env-vars env.json
```

---

## 🧪 Testing & Validation

- Each handler validates input and authentication internally.  
- You can add integration tests using [Vitest](https://vitest.dev) or Jest.  
- Planned shared modules for validation (Zod) and error mapping.

---

## 🧭 Adding a New Endpoint

1. Create a new folder under `src/api/<yourRoute>/`.  
2. Add an `index.ts` exporting `handler` (Lambda entrypoint).  
3. Add a `README.md` describing method, path, and usage.  
4. Update your API Gateway / CDK configuration to route to it.  

Example structure:

```
src/api/sendNotification/
├─ index.ts
└─ README.md
```

---

## 🧩 Notes

- Each handler is fully **self-contained** (no hidden state).  
- `_lib/` modules are designed for **safe reuse** across endpoints.  
- Logging is minimal but can be extended with a future `_lib/log.ts`.

---

### ✅ Quick Summary

- **Framework:** AWS Lambda + API Gateway (HTTP API v2)  
- **Auth:** Cognito JWT via `jose`  
- **Data:** DynamoDB (scanned / queried by handlers)  
- **Output:** JSON with consistent CORS headers  
- **Code style:** Functional, typed, minimal side effects

---

_This README provides a single-glance view of the API structure, behavior, and setup for future developers or production maintainers._
