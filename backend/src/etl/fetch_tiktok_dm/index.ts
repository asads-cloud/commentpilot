import { putJson } from "../_lib/s3";

const RAW_BUCKET = process.env.RAW_BUCKET!;
const PLATFORM_PREFIX = "tiktok";

export const handler = async () => {
  const now = new Date();
  const payload = {
    platform: "tiktok",
    fetched_at: now.toISOString(),
    messages: [
      {
        id: `tt_${now.getTime()}`,
        from: "tiktok_fan_000",
        to: "brand_account",
        text: "Collab idea: 30-sec review?",
        ts: now.toISOString(),
        meta: { video_ref: "v12345", likes: 3402 }
      }
    ]
  };

  const key = `${PLATFORM_PREFIX}/dt=${now.toISOString().slice(0,10)}/${now.getTime()}.json`;
  await putJson({ bucket: RAW_BUCKET, key, data: payload });

  return { ok: true, bucket: RAW_BUCKET, key, count: payload.messages.length };
};
