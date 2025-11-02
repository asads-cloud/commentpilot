import type { APIGatewayProxyResult } from "aws-lambda";
import { verifyJwt } from "../_lib/auth";
import { DynamoDBClient, ScanCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});
const TABLE = process.env.DDB_TABLE!;

const json = (code: number, body: unknown): APIGatewayProxyResult => ({
  statusCode: code,
  headers: {
    "content-type": "application/json",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "authorization,content-type",
    "access-control-allow-methods": "GET,OPTIONS",
  },
  body: JSON.stringify(body),
});

export const handler = async (event: any): Promise<APIGatewayProxyResult> => {
  try {
    // REST v1 + HTTP v2 headers
    const h = event?.headers ?? {};
    const authHeader = h.authorization ?? h.Authorization ?? h.AUTHORIZATION ?? null;
    if (event.requestContext?.http?.method === "OPTIONS") return json(204, {});
    await verifyJwt(authHeader);

    // 1) Only fetch the fields we need
    const scan = await ddb.send(
      new ScanCommand({
        TableName: TABLE,
        ProjectionExpression:
          "#id, platform, sender, #t, sentiment, intent, message_ts, dt, message_id",
        ExpressionAttributeNames: { "#id": "id", "#t": "text" },
        Limit: 50, // keep small in dev
      })
    );

    // 2) Coerce AttributeValues and fill sensible defaults
    const raw = scan.Items ?? [];
    const items = raw
      .map((i: any) => ({
        id: i.id?.S ?? i.message_id?.S ?? null,
        platform: i.platform?.S ?? "unknown",
        sender: i.sender?.S ?? "",
        text: i["text"]?.S ?? "",
        sentiment: i.sentiment?.S ?? "NEUTRAL",
        intent: i.intent?.S ?? "other",
        ts: i.message_ts?.S ?? i.dt?.S ?? "",
      }))
      // 3) Drop rows that are clearly unusable (no id or text)
      .filter((x) => !!x.id && x.text !== "");

    // 4) If nothing usable, return a friendly mock
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

    // Optional: newest first
    items.sort((a, b) => (a.ts > b.ts ? -1 : a.ts < b.ts ? 1 : 0));

    return json(200, { items, count: items.length });
  } catch (err: any) {
    const msg = err?.message ?? String(err);
    const isAuth = /token|jwt|kid|issuer|audience|Unauthorized|No token/i.test(msg);
    return json(isAuth ? 401 : 500, {
      error: isAuth ? "Unauthorized" : "InternalError",
      detail: msg,
    });
  }
};
