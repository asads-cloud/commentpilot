import { putJson } from "../_lib/s3";

const RAW_BUCKET = process.env.RAW_BUCKET!;
const PLATFORM_PREFIX = "instagram";

export const handler = async () => {
  const now = new Date();
  const payload = {
    platform: "instagram",
    fetched_at: now.toISOString(),
    messages: [
      {
        id: `ig_${now.getTime()}`,
        from: "insta_user_42",
        to: "brand_account",
        text: "Hi! Do you ship to EU?",
        ts: now.toISOString(),
        meta: { thread_id: "t_001", followers: 1280 }
      }
    ]
  };

  const key = `${PLATFORM_PREFIX}/dt=${now.toISOString().slice(0,10)}/${now.getTime()}.json`;
  await putJson({ bucket: RAW_BUCKET, key, data: payload });

  return { ok: true, bucket: RAW_BUCKET, key, count: payload.messages.length };
};
