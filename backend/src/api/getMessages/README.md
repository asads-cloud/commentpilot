# getMessages — API Route

Handles authenticated `GET` requests to retrieve recent **messages** from DynamoDB.  
This endpoint fetches the most recent items, limits results for development safety, and returns a simplified, clean structure.

---

## 🧭 Overview

| Method | Path | Auth Required | Description |
|:-------|:-----|:---------------|:-------------|
| GET | /getMessages | ✅ Yes | Fetches up to 50 recent messages from DynamoDB (mocked if empty). |

---

## 🧱 Responsibilities

- ✅ Handle **CORS preflight** (`OPTIONS`)
- ✅ Enforce **GET-only** requests
- ✅ Verify **JWT Authorization header**
- ✅ Scan DynamoDB table for recent items (projection + limit)
- ✅ Convert raw `AttributeValues` into simple JSON
- ✅ Return consistent **JSON responses** with standard headers

---

## 🧰 Key Files

| File | Purpose |
|------|----------|
| `index.ts` | Main Lambda handler for `GET /getMessages` |
| `_lib/auth.ts` | `verifyJwt()` — verifies Cognito-issued JWT tokens |
| `_lib/http.ts` *(planned)* | Common JSON + CORS response helpers (shared across endpoints) |

---

## ⚙️ Example Request

```bash
curl -X GET https://<your-api>/getMessages   -H "Authorization: Bearer <JWT>"
```

### Example Response

```json
{
  "items": [
    {
      "id": "msg-001",
      "platform": "instagram",
      "sender": "user123",
      "text": "Hello from production",
      "sentiment": "POSITIVE",
      "intent": "support",
      "ts": "2025-10-31T12:30:00Z"
    }
  ],
  "count": 1
}
```

---

## 🚦 Error Responses

| HTTP | Error | When |
|------|--------|------|
| 400 | `BadRequest` | Invalid request |
| 401 | `Unauthorized` | Missing or invalid JWT |
| 405 | `MethodNotAllowed` | Any method other than `GET` |
| 500 | `InternalError` | Unexpected exception or missing config |

---

## 🧩 Notes

- DynamoDB table name must be set via the environment variable **`DDB_TABLE`**.  
- CORS headers are permissive (`*`) for dev convenience.  
  Restrict them before production deployment.
- Mock response is returned when no usable items exist in the table.
- Limit is **50 items** to prevent large dev scans.

---

## 🧪 Local Testing

You can test this locally via AWS SAM, the Serverless Framework, or Node directly:

```bash
npm run build && node dist/api/getMessages/index.js
```

_(Ensure `DDB_TABLE` and JWT verification config are available in your environment.)_

---

## 🧭 Next Steps

- Move shared response logic to `_lib/http.ts`
- Add query parameters for filtering and pagination
- Implement caching or pagination for production scaling
