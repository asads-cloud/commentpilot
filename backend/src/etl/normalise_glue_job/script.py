from pyspark.sql import SparkSession, functions as F
from awsglue.utils import getResolvedOptions
import sys, json, datetime

# Try uppercase first (Glue style), then fall back to manual parse (lowercase)
try:
    gargs = getResolvedOptions(sys.argv, ["JOB_NAME", "SOURCE", "TARGET", "ENV"])
    SRC = gargs["SOURCE"].rstrip("/")
    TGT = gargs["TARGET"].rstrip("/")
    ENV = gargs["ENV"]
except Exception:
    # fallback for --source/--target/--env
    kv = {}
    for i, a in enumerate(sys.argv):
        if a.startswith("--") and i + 1 < len(sys.argv):
            kv[a.lstrip("-")] = sys.argv[i + 1]
    SRC = (kv.get("SOURCE") or kv.get("source") or "").rstrip("/")
    TGT = (kv.get("TARGET") or kv.get("target") or "").rstrip("/")
    ENV = kv.get("ENV") or kv.get("env") or "dev"

if not SRC or not TGT:
    raise ValueError(f"Missing required args. Got SRC='{SRC}', TGT='{TGT}'. Please pass --SOURCE/--TARGET or --source/--target.")


spark = SparkSession.builder.appName(f"commentpilot_normalise_{ENV}").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

def infer_intent(text):
    t = (text or "").lower()
    if any(k in t for k in ["price","cost","rate","how much","subscribe"]): return "lead"
    if any(k in t for k in ["refund","broken","issue","problem","help"]):    return "support"
    if any(k in t for k in ["how do i","can you","where is","when is"]):     return "question"
    if any(k in t for k in ["buy now","promo","giveaway","free followers"]): return "spam"
    return "other"

infer_intent_udf = F.udf(infer_intent)

# Read
df_ig = spark.read.option("multiLine","true").json(f"{SRC}/instagram/dt=*/*.json")
df_tt = spark.read.option("multiLine","true").json(f"{SRC}/tiktok/dt=*/*.json")

def explode_msgs(df, platform):
    if df is None:
        return None
    return (
        df.withColumn("platform", F.lit(platform))
          # dt from ISO timestamp; prefer message ts if present else fetched_at
          .withColumn("raw_ts",
                      F.coalesce(F.col("messages.ts").getItem(0), F.col("fetched_at")))
          .withColumn("dt", F.to_date(F.to_timestamp("raw_ts")))
          .withColumn("msg", F.explode_outer(F.col("messages")))
          .select(
              "platform",
              F.col("dt").cast("string").alias("dt"),
              F.col("msg.id").alias("message_id"),
              F.col("msg.from").alias("sender"),
              F.col("msg.to").alias("recipient"),
              F.col("msg.text").alias("text"),
              F.col("msg.ts").alias("message_ts"),
              F.col("msg.meta").alias("meta")
          )
    )

ig = explode_msgs(df_ig, "instagram")
tt = explode_msgs(df_tt, "tiktok")
dfs = [d for d in [ig, tt] if d is not None]
if not dfs:
    print("No input found; exiting gracefully.")
    sys.exit(0)

unioned = dfs[0]
for d in dfs[1:]:
    unioned = unioned.unionByName(d, allowMissingColumns=True)

out = (
    unioned
      .withColumn("intent", infer_intent_udf(F.col("text")))
      .withColumn("sentiment", F.lit("NEUTRAL"))
      .withColumn("ingested_at", F.lit(datetime.datetime.utcnow().isoformat() + "Z"))
)

out = out.withColumn("platform_part", F.col("platform"))

# Write to TGT, partitioned
(out.repartition("platform_part","dt")
    .write.mode("overwrite")
    .partitionBy("platform_part","dt")
    .json(TGT))

print(json.dumps({
    "ok": True,
    "source": SRC,
    "target": TGT,
    "count": out.count()
}))
