# postReply — API Route

Handles authenticated `POST` requests for posting a **reply**.  
Currently acts as a stub endpoint that verifies JWTs and echoes back the request payload.

---

## 🧭 Overview

| Method | Path | Auth Required | Description                  |
|:-------|:-----|:---------------|:------------------------------|
| POST   | /postReply | ✅ Yes | Accepts a JSON body and (for now) returns a stubbed response. |

---

## 🧱 Responsibilities

- ✅ Handle **CORS preflight** (`OPTIONS`)
- ✅ Enforce **POST-only** requests
- ✅ Verify **JWT Authorization header**
- ✅ Safely **parse JSON body** (supports base64 payloads)
- ✅ Return consistent **JSON responses** with standard headers

---

## 🧰 Key Files

| File | Purpose |
|------|----------|
| `index.ts` | Main Lambda handler for `POST /postReply` |
| `_lib/auth.ts` | `verifyJwt()` — verifies Cognito-issued JWT tokens |
| `_lib/http.ts` *(planned)* | Common JSON + CORS response helpers (shared across endpoints) |

---

## ⚙️ Example Request

```bash
curl -X POST https://<your-api>/postReply   -H "Authorization: Bearer <JWT>"   -H "Content-Type: application/json"   -d '{
    "threadId": "abc123",
    "body": "Hello from the test client!"
  }'
```

### Example Response

```json
{
  "ok": true,
  "note": "Reply stubbed — integrate sending in a later phase",
  "echo": {
    "threadId": "abc123",
    "body": "Hello from the test client!"
  },
  "user": { "sub": "user-1234abcd" }
}
```

---

## 🚦 Error Responses

| HTTP | Error | When |
|------|--------|------|
| 400 | `BadRequest` | Invalid JSON body |
| 401 | `Unauthorized` | Missing or invalid JWT |
| 405 | `MethodNotAllowed` | Any method other than `POST` |
| 500 | `InternalError` | Unexpected exception |

---

## 🧩 Notes

- CORS headers are permissive for development (`*`).  
  You may wish to restrict this before production.
- The handler currently only **echoes** payloads — future work will integrate
  the actual reply-sending logic.
- This function assumes the `verifyJwt()` helper throws on invalid tokens.

---

## 🧪 Local Testing

You can run this locally via AWS SAM, the Serverless Framework, or directly using Node:

```bash
npm run build && node dist/api/postReply/index.js
```

_(Ensure `JWT_PUBLIC_KEY` or equivalent environment variable is configured.)_

---

## 🧭 Next Steps

- Move shared response logic to `_lib/http.ts`
- Implement real reply creation logic
- Add lightweight unit test for happy/error paths
