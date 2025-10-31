import { APIGatewayProxyHandlerV2 } from "aws-lambda";
import type { APIGatewayProxyResult } from "aws-lambda";
import { verifyJwt } from "../_lib/auth";
/**
 * === Post Reply API ===
 * This Lambda handles authenticated POST requests to send (or eventually queue) replies.
 * For now, it’s a stub — later phases will integrate actual platform connectors.
 *
 *  - verifyJwt() ensures the user’s token is valid (Cognito).
 *  - json() wraps responses with headers + CORS handling.
 *  - POST is the only method this route allows.
 */

/* -------------------------------------------------------------------------- */
/*                             Response Builder                               */
/* -------------------------------------------------------------------------- */

/**
 * Small utility to standardize JSON responses.
 * Includes permissive CORS headers — tweak before production if needed.
 */
const json = (code: number, body?: unknown): APIGatewayProxyResult => ({
  statusCode: code,
  headers: {
    "content-type": "application/json",
    "access-control-allow-origin": "*", // dev-friendly CORS
    "access-control-allow-headers": "authorization,content-type",
    "access-control-allow-methods": "POST,OPTIONS",
  },
  body: body === undefined ? "" : JSON.stringify(body),
});

/* -------------------------------------------------------------------------- */
/*                              Main Handler                                  */
/* -------------------------------------------------------------------------- */

/**
 * Handler entrypoint for POST /postReply
 * Handles:
 *  - CORS preflight (OPTIONS)
 *  - Auth verification
 *  - Body validation
 *  - (Stub) Reply creation — will later integrate platform-specific logic.
 */
export const handler = async (event: any): Promise<APIGatewayProxyResult> => {
  try {
    // Normalize method/path across REST v1 and HTTP v2
    const method =
      event?.requestContext?.http?.method || event?.httpMethod || "GET";

    // Quick CORS preflight
    if (method === "OPTIONS") return json(204);

    // Case-insensitive Authorization header
    const headers = event?.headers ?? {};
    const authHeader =
      headers.authorization ??
      headers.Authorization ??
      headers.AUTHORIZATION ??
      null;

    // Verify Cognito JWT
    const user = await verifyJwt(authHeader);

    if (method !== "POST") return json(405, { error: "MethodNotAllowed" });

    // Parse body safely (supports base64 + string/object)
    let bodyObj: any = {};
    if (event?.body) {
      let bodyStr =
        typeof event.body === "string" ? event.body : JSON.stringify(event.body);
      if (event?.isBase64Encoded) {
        bodyStr = Buffer.from(bodyStr, "base64").toString("utf8");
      }
      try {
        bodyObj = bodyStr ? JSON.parse(bodyStr) : {};
      } catch {
        return json(400, { error: "BadRequest", detail: "Invalid JSON body" });
      }
    }

    // Stub response (hook up real sending later)
    return json(200, {
      ok: true,
      note: "Reply stubbed in Phase 2",
      echo: bodyObj,
      user: { sub: (user as any).sub },
    });
  } catch (err: any) {
    console.error("postReply error:", err);
    const isAuth = /token|jwt|kid|issuer|audience|Unauthorized|No token/i.test(
      err?.message ?? ""
    );
    return json(isAuth ? 401 : 500, {
      error: isAuth ? "Unauthorized" : "InternalError",
      detail: err?.message ?? String(err),
    });
  }
};
