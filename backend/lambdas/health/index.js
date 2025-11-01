exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      ok: true,
      service: "CommentPilot",
      env: process.env.ENV || "dev",
      ts: new Date().toISOString(),
    }),
  };
};
