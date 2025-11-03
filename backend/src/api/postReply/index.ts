// backend/src/api/postReply/index.ts
import {
  APIGatewayProxyHandlerV2,
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";
import { verifyJwt } from "../_lib/auth";

/**
 * Post Reply — Lambda handler
 *
 * Accepts authenticated POST requests and (for now) echoes the payload.
 * Future phases will route this into a real “send reply” pipeline.
 *
 * Responsibilities:
 *  - CORS preflight (OPTIONS)
 *  - Method guard (POST only)
 *  - Auth (Authorization: Bearer <JWT>)
 *  - Safe body parsing (JSON, supports base64)
 *  - Structured, consistent JSON responses
 */

/* -------------------------------------------------------------------------- */
/* Utilities                                                                  */
/* -------------------------------------------------------------------------- */

const CORS_HEADERS = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization,content-type",
  "access-control-allow-methods": "POST,OPTIONS",
} as const;

const json = (
  statusCode: number,
  body?: unknown
): APIGatewayProxyResultV2 => ({
  statusCode,
  headers: CORS_HEADERS,
  body: body === undefined ? "" : JSON.stringify(body),
});

class HttpError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public detail?: unknown
  ) {
    super(message);
  }
}
class UnauthorizedError extends HttpError {
  constructor(detail?: unknown) {
    super(401, "Unauthorized", detail);
  }
}
class BadRequestError extends HttpError {
  constructor(detail?: unknown) {
    super(400, "BadRequest", detail);
  }
}
class MethodNotAllowedError extends HttpError {
  constructor(allowed: string[]) {
    super(405, "MethodNotAllowed", { allowed });
  }
}

/**
 * Case-insensitive header lookup.
 */
function getHeader(
  headers: APIGatewayProxyEventV2["headers"] | undefined,
  name: string
): string | undefined {
  if (!headers) return undefined;
  const lower = name.toLowerCase();
  for (const [k, v] of Object.entries(headers)) {
    if (k.toLowerCase() === lower) return v;
  }
  return undefined;
}

/**
 * Parse the request body to an object. Supports base64-encoded payloads.
 * Throws BadRequestError on invalid JSON.
 */
function parseJsonBody(event: APIGatewayProxyEventV2): unknown {
  if (!event.body) return {};
  const raw =
    event.isBase64Encoded === true
      ? Buffer.from(event.body, "base64").toString("utf8")
      : event.body;

  try {
    return raw ? JSON.parse(raw) : {};
  } catch {
    throw new BadRequestError("Invalid JSON body");
  }
}

/**
 * Normalise HTTP method across REST v1 and HTTP API v2 shapes.
 */
function getMethod(event: any): string {
  return event?.requestContext?.http?.method || event?.httpMethod || "GET";
}

/* -------------------------------------------------------------------------- */
/* Handler                                                                    */
/* -------------------------------------------------------------------------- */

export const handler: APIGatewayProxyHandlerV2 = async (
  event
): Promise<APIGatewayProxyResultV2> => {
  try {
    const method = getMethod(event);

    // CORS preflight
    if (method === "OPTIONS") return json(204);

    // Method guard
    if (method !== "POST") throw new MethodNotAllowedError(["POST", "OPTIONS"]);

    // Auth (Authorization: Bearer <token>)
    const authHeader = getHeader(event.headers, "authorization");
    const user = await verifyJwt(authHeader).catch((e: unknown) => {
      // Keep error info terse to avoid token leakage in logs
      throw new UnauthorizedError(
        e instanceof Error ? e.message : "Invalid token"
      );
    });

    // Body
    const payload = parseJsonBody(event);

    // Stubbed business logic — replace with actual reply logic later.
    // Example: const replyId = await sendReply({ user, payload });

    return json(200, {
      ok: true,
      note: "Reply stubbed — integrate sending in a later phase",
      echo: payload,
      user: { sub: (user as any)?.sub },
    });
  } catch (err) {
    // Map known HttpErrors → JSON shape; everything else → 500.
    if (err instanceof HttpError) {
      return json(err.statusCode, { error: err.message, detail: err.detail });
    }

    console.error("postReply unexpected error:", err);
    const message = err instanceof Error ? err.message : String(err);
    const looksAuthy = /token|jwt|kid|issuer|audience|unauthor/i.test(message);
    return json(looksAuthy ? 401 : 500, {
      error: looksAuthy ? "Unauthorized" : "InternalError",
      detail: message,
    });
  }
};
