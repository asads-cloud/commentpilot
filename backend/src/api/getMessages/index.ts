import { APIGatewayProxyHandlerV2 } from "aws-lambda";
import type { APIGatewayProxyResult } from "aws-lambda";
import { verifyJwt } from "../_lib/auth";

/**
 * === Messages API Handler ===
 * This endpoint returns the latest messages for the authenticated user.
 * Currently uses mock data, but it’s structured to make switching to DynamoDB easy.
 *
 *  - verifyJwt() handles auth (Cognito token verification).
 *  - json() is a tiny helper for consistent responses.
 *  - The DynamoDB section is commented out but ready for future use.
 */

/* -------------------------------------------------------------------------- */
/*                         DynamoDB (Future Integration)                      */
/* -------------------------------------------------------------------------- */

// If/when you switch to DynamoDB, uncomment this block and wire it up:
//
// import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
// import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";
// const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
// const TABLE = process.env.MESSAGES_TABLE!;
//
// Example query (fetch recent messages for the logged-in user):
// const res = await ddb.send(new QueryCommand({
//   TableName: TABLE,
//   KeyConditionExpression: "accountId = :a and begins_with(sk, :p)",
//   ExpressionAttributeValues: { ":a": user.sub, ":p": "msg#" },
//   Limit: 25,
//   ScanIndexForward: false, // newest first
// }));
// const items = (res.Items ?? []).map(x => ({ ...x }));

/* -------------------------------------------------------------------------- */
/*                             Response Helper                                */
/* -------------------------------------------------------------------------- */

/**
 * json() — basic response builder for API Gateway.
 * Sets headers for CORS + JSON output.
 *
 * Note: Adjust CORS settings as needed depending on your frontend setup.
 */
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

/* -------------------------------------------------------------------------- */
/*                              Main Lambda Handler                           */
/* -------------------------------------------------------------------------- */

/**
 * Handler entrypoint for API Gateway.
 * Authenticates the incoming request and returns a list of messages.
 *
 * Future work:
 *  - Replace mock messages with DynamoDB query results.
 *  - Possibly add pagination or filtering by date/sender.
 */
export const handler = async (event: any): Promise<APIGatewayProxyResult> => {
  try {
    // Support both REST v1 and HTTP v2 header shapes + casing
    const headers = event?.headers ?? {};
    const authHeader =
      headers.authorization ??
      headers.Authorization ??
      headers.AUTHORIZATION ??
      null;

    const user = await verifyJwt(authHeader);

    // sample payload
    const items = [
      {
        id: "mock-1",
        platform: "instagram",
        sender: "user_123",
        text: "Hey! Is your agency taking new clients?",
        sentiment: "POSITIVE",
        intent: "lead",
        ts: new Date().toISOString(),
      },
    ];

    return json(200, { items, user: { sub: user.sub } });
  } catch (err: any) {
    console.error("getMessages error:", err);
    const isAuth = /token|jwt|kid|issuer|audience|No token|Unauthorized/i.test(
      err?.message ?? ""
    );
    return json(isAuth ? 401 : 500, {
      error: isAuth ? "Unauthorized" : "InternalError",
      detail: err?.message ?? String(err),
    });
  }
};