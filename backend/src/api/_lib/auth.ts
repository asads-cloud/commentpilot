import { createRemoteJWKSet, jwtVerify, errors, type JWTPayload } from "jose";

/**
 * === Auth Utilities (Cognito + jose) ===
 * - Verifies Cognito JWTs using the pool's JWKS (cached & rotated automatically).
 * - Strictly enforces issuer and audience.
 * - Clear, actionable error messages for logs & clients.
 *
 * Env required:
 *   COGNITO_ISSUER   -> "https://cognito-idp.<region>.amazonaws.com/<userPoolId>"
 *   COGNITO_AUDIENCE -> App client ID
 */

// -------------------- Config sanity --------------------
const ISSUER   = process.env.COGNITO_ISSUER;
const AUDIENCE = process.env.COGNITO_AUDIENCE;

if (!ISSUER)  throw new Error("Missing required env var: COGNITO_ISSUER");
if (!AUDIENCE) throw new Error("Missing required env var: COGNITO_AUDIENCE");

// Normalize issuer (strip trailing slash to avoid subtle mismatches)
const ISS = ISSUER.replace(/\/+$/, "");

// -------------------- JWKS setup (cached) --------------------
// jose caches keys by default and respects cache headers.
// We also set a conservative cooldown to avoid thundering herds.
const JWKS = createRemoteJWKSet(new URL(`${ISS}/.well-known/jwks.json`), {
  cooldownDuration: 30_000, // 30s
});

// Accept a small clock skew to avoid edge failures around token mint/refresh.
const CLOCK_TOLERANCE_SEC = 60;

// -------------------- Error helpers --------------------
class AuthError extends Error {
  status = 401;
  constructor(message: string) { super(message); this.name = "AuthError"; }
}

function mapJoseError(e: unknown): AuthError {
  if (e instanceof errors.JWTExpired)        return new AuthError("JWT expired");
  if (e instanceof errors.JWTInvalid)        return new AuthError("Invalid JWT");
  if (e instanceof errors.JWSSignatureVerificationFailed)
                                            return new AuthError("Signature verification failed");
  if (e instanceof errors.JWSInvalid)        return new AuthError("Invalid JWS");
  if (e instanceof errors.JOSEError)         return new AuthError(e.message);
  return new AuthError((e as any)?.message ?? "Unauthorized");
}

// -------------------- Public API --------------------
/**
 * verifyJwt(authHeader)
 * - Expects "Authorization: Bearer <token>"
 * - Returns the verified JWT payload (claims).
 * - Throws AuthError(401) with clear messages on failure.
 */
export async function verifyJwt(
  authHeader?: string
): Promise<JWTPayload & Record<string, any>> {
  if (!authHeader?.startsWith("Bearer ")) {
    throw new AuthError("Missing or malformed Authorization header");
  }

  const token = authHeader.slice("Bearer ".length);

  try {
    const { payload } = await jwtVerify(token, JWKS, {
      algorithms: ["RS256"],
      issuer: ISS,
      audience: AUDIENCE,
      clockTolerance: CLOCK_TOLERANCE_SEC,
    });

    // Optional extra sanity logs (useful during bring-up)
    if (payload.iss !== ISS) {
      console.warn("Issuer mismatch (post-verify)", { tokenIss: payload.iss, expected: ISS });
    }
    if (payload.aud !== AUDIENCE) {
      console.warn("Audience mismatch (post-verify)", { tokenAud: payload.aud, expected: AUDIENCE });
    }

    return payload as JWTPayload & Record<string, any>;
  } catch (e) {
    // Log detailed context to CloudWatch; throw a clean 401 for the caller.
    console.error("JWT verification failed", {
      message: (e as any)?.message,
      name: (e as any)?.name,
    });
    throw mapJoseError(e);
  }
}

/**
 * Optional helper to make auth handling nice in handlers.
 * Wrap your handler body with:
 *   const user = await requireAuth(event.headers);
 */
export async function requireAuth(
  headers?: Record<string, string | undefined>
) {
  const auth =
    headers?.authorization ??
    (headers as any)?.Authorization ??
    (headers as any)?.AUTHORIZATION;

  return verifyJwt(typeof auth === "string" ? auth : undefined);
}
