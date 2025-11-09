//import { putJson } from "../_lib/s3";

//const RAW_BUCKET = process.env.RAW_BUCKET!;
//const PLATFORM_PREFIX = "tiktok";

//export const handler = async () => {
//  const now = new Date();
//  const payload = {
//    platform: "tiktok",
//    fetched_at: now.toISOString(),
//    messages: [
//      {
//        id: `tt_${now.getTime()}`,
//        from: "tiktok_fan_000",
//        to: "brand_account",
//        text: "Collab idea: 30-sec review?",
//        ts: now.toISOString(),
//        meta: { video_ref: "v12345", likes: 3402 }
//      }
//    ]
//  };

//  const key = `${PLATFORM_PREFIX}/dt=${now.toISOString().slice(0,10)}/${now.getTime()}.json`;
//  await putJson({ bucket: RAW_BUCKET, key, data: payload });

//  return { ok: true, bucket: RAW_BUCKET, key, count: payload.messages.length };
//};

import { randomUUID } from "crypto";
import { putJson } from "../_lib/s3";

const RAW_BUCKET = process.env.RAW_BUCKET!;
const PLATFORM_PREFIX = process.env.PLATFORM!;     // "instagram"
const TENANT_ID = process.env.TENANT_ID!;   // e.g. "tenant_dev_demo"

function buildS3Key(now: Date) {
  const dtPartition = now.toISOString().slice(0, 10); // YYYY-MM-DD

  // Build UTC YYYYMMDDTHHMM for idempotent minute-level key
  const pad = (n: number) => n.toString().padStart(2, "0");
  const year = now.getUTCFullYear();
  const month = pad(now.getUTCMonth() + 1);
  const day = pad(now.getUTCDate());
  const hour = pad(now.getUTCHours());
  const minute = pad(now.getUTCMinutes());
  const batchTsMinute = `${year}${month}${day}T${hour}${minute}`;

  const key = `${PLATFORM_PREFIX}/dt=${dtPartition}/tenant=${TENANT_ID}/batch_ts=${batchTsMinute}.json`;

  return { dtPartition, batchTsMinute, key };
}

export const handler = async (event: any, context: any) => {
  const now = new Date();
  const { dtPartition, batchTsMinute, key } = buildS3Key(now);

  const batchId = `${TENANT_ID}-${PLATFORM_PREFIX}-${batchTsMinute}`;

  // Mock messages for now
  const messages = [
    {
      platform: PLATFORM_PREFIX,
      tenant_id: TENANT_ID,
      message_id: `mock-${randomUUID()}`,
      message_ts: now.toISOString(),
      sender_id: "mock_sender",
      text: `Hello from ${PLATFORM_PREFIX} at ${now.toISOString()}`,
    },
  ];

  const payload = {
    batch_id: batchId,
    platform: PLATFORM_PREFIX,
    tenant_id: TENANT_ID,
    fetched_at: now.toISOString(),
    request_id: context?.awsRequestId ?? null,
    partition: {
      dt: dtPartition,
    },
    messages,
  };

  await putJson({
    bucket: RAW_BUCKET,
    key,
    data: payload,
  });

  // Structured log
  console.log(
    JSON.stringify({
      level: "INFO",
      event: "fetch_dm_batch_written",
      platform: PLATFORM_PREFIX,
      tenant_id: TENANT_ID,
      batch_id: batchId,
      s3_bucket: RAW_BUCKET,
      s3_key: key,
      message_count: messages.length,
      request_id: context?.awsRequestId ?? null,
    })
  );

  return {
    statusCode: 200,
    batch_id: batchId,
    s3_key: key,
    message_count: messages.length,
  };
};

