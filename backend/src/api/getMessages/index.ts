// backend/src/api/getMessages/index.ts
import {
  APIGatewayProxyHandlerV2,
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";
import { verifyJwt } from "../_lib/auth";
import { DynamoDBClient, ScanCommand, AttributeValue } from "@aws-sdk/client-dynamodb";

/**
 * Get Messages — Lambda handler
 *
 * Responsibilities:
 *  - CORS preflight (OPTIONS)
 *  - Method guard (GET only)
 *  - Auth (Authorization: Bearer <JWT>)
 *  - Read latest messages from DynamoDB (projection + limit)
 *  - Coerce AttributeValues → plain JS and return a tidy list
 */

/* -------------------------------------------------------------------------- */
/* Config & Clients                                                            */
/* -------------------------------------------------------------------------- */

const ddb = new DynamoDBClient({});
const TABLE = process.env.DDB_TABLE;

/* -------------------------------------------------------------------------- */
/* HTTP helpers                                                                */
/* -------------------------------------------------------------------------- */

const CORS_HEADERS = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization,content-type",
  "access-control-allow-methods": "GET,OPTIONS",
} as const;

const json = (statusCode: number, body?: unknown): APIGatewayProxyResultV2 => ({
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
class ConfigError extends HttpError {
  constructor(detail?: unknown) {
    super(500, "InternalError", detail ?? "Missing configuration");
  }
}

/* -------------------------------------------------------------------------- */
/* Utility helpers                                                             */
/* -------------------------------------------------------------------------- */

function getMethod(event: any): string {
  return event?.requestContext?.http?.method || event?.httpMethod || "GET";
}

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

/** Safe extractor for DynamoDB AttributeValue → string (or fallback). */
const s = (a?: AttributeValue, fallback = ""): string =>
  (a && "S" in a ? a.S ?? fallback : fallback);

/* Domain shape returned by this endpoint */
type MessageItem = {
  id: string;
  platform: string;
  sender: string;
  text: string;
  sentiment: string;
  intent: string;
  ts: string; // ISO8601 or raw timestamp string
};

function mapDdbItem(i: Record<string, AttributeValue>): MessageItem | null {
  const id = s(i.id) || s(i.message_id) || "";
  const text = s(i["text"]);
  if (!id || !text) return null;

  return {
    id,
    platform: s(i.platform, "unknown"),
    sender: s(i.sender),
    text,
    sentiment: s(i.sentiment, "NEUTRAL"),
    intent: s(i.intent, "other"),
    ts: s(i.message_ts) || s(i.dt),
  };
}

/* -------------------------------------------------------------------------- */
/* Handler                                                                     */
/* -------------------------------------------------------------------------- */

export const handler: APIGatewayProxyHandlerV2 = async (
  event
): Promise<APIGatewayProxyResultV2> => {
  try {
    const method = getMethod(event);

    // CORS preflight
    if (method === "OPTIONS") return json(204);

    // Method guard
    if (method !== "GET") throw new MethodNotAllowedError(["GET", "OPTIONS"]);

    // Config guard
    if (!TABLE) throw new ConfigError("DDB_TABLE is not set");

    // Auth (Authorization: Bearer <token>)
    const authHeader = getHeader(event.headers, "authorization");
    await verifyJwt(authHeader).catch((e: unknown) => {
      throw new UnauthorizedError(
        e instanceof Error ? e.message : "Invalid token"
      );
    });

    // Read a small page; projection keeps network cost low
    const scan = await ddb.send(
      new ScanCommand({
        TableName: TABLE,
        ProjectionExpression:
          "#id, platform, sender, #t, sentiment, intent, message_ts, dt, message_id",
        ExpressionAttributeNames: { "#id": "id", "#t": "text" },
        Limit: 50,
      })
    );

    const raw = scan.Items ?? [];
    const items = raw
      .map(mapDdbItem)
      .filter((x): x is MessageItem => x !== null)
      .sort((a, b) => (a.ts > b.ts ? -1 : a.ts < b.ts ? 1 : 0)); // newest first

    if (items.length === 0) {
      return json(200, {
        items: [
          {
            id: "mock-1",
            platform: "instagram",
            sender: "dev",
            text: "Hello from mock",
            sentiment: "NEUTRAL",
            intent: "other",
            ts: new Date().toISOString(),
          },
        ],
        note: "No usable items in DynamoDB; returned mock.",
      });
    }

    return json(200, { items, count: items.length });
  } catch (err) {
    if (err instanceof HttpError) {
      return json(err.statusCode, { error: err.message, detail: err.detail });
    }

    // Fallback mapping (keeps old behavior of auth-ish messages → 401)
    const message = err instanceof Error ? err.message : String(err);
    const looksAuthy = /token|jwt|kid|issuer|audience|unauthor/i.test(message);
    console.error("getMessages unexpected error:", err);
    return json(looksAuthy ? 401 : 500, {
      error: looksAuthy ? "Unauthorized" : "InternalError",
      detail: message,
    });
  }
};
