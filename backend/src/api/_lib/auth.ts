// backend/src/api/_lib/auth.ts
import {
  createRemoteJWKSet,
  jwtVerify,
  errors as joseErrors,
  type JWTPayload,
  type JWSHeaderParameters,
} from "jose";

/**
 * Auth utilities (Cognito + jose)
 *
 * - Verifies Cognito JWTs against the pool JWKS (cached & rotated).
 * - Enforces issuer & audience.
 * - Exposes small helpers for handlers (getAuthHeader / requireAuth).
 *
 * Env:
 *   COGNITO_ISSUER   = https://cognito-idp.<region>.amazonaws.com/<userPoolId>
 *   COGNITO_AUDIENCE = <app client id>
 */

/* -------------------------------------------------------------------------- */
/* Config                                                                      */
/* -------------------------------------------------------------------------- */

const ISSUER = process.env.COGNITO_ISSUER;
const AUDIENCE = process.env.COGNITO_AUDIENCE;

if (!ISSUER) throw new Error("Missing required env var: COGNITO_ISSUER");
if (!AUDIENCE) throw new Error("Missing required env var: COGNITO_AUDIENCE");

/** normalised issuer (strip trailing slash to avoid mismatch) */
const ISS = ISSUER.replace(/\/+$/, "");

/* -------------------------------------------------------------------------- */
/* JWKS (remote, cached)                                                       */
/* -------------------------------------------------------------------------- */

const JWKS = createRemoteJWKSet(new URL(`${ISS}/.well-known/jwks.json`), {
  // jose caches keys and respects cache headers; add a small cooldown
  cooldownDuration: 30_000, // 30s
});

/** allow small skew around issue/refresh windows */
const CLOCK_TOLERANCE_SEC = 60;

/* -------------------------------------------------------------------------- */
/* Errors                                                                      */
/* -------------------------------------------------------------------------- */

export class AuthError extends Error {
  readonly status = 401 as const;
  constructor(message: string) {
    super(message);
    this.name = "AuthError";
  }
}
export const isAuthError = (e: unknown): e is AuthError =>
  e instanceof AuthError;

function mapJoseError(e: unknown): AuthError {
  if (e instanceof joseErrors.JWTExpired) return new AuthError("JWT expired");
  if (e instanceof joseErrors.JWTInvalid) return new AuthError("Invalid JWT");
  if (e instanceof joseErrors.JWSSignatureVerificationFailed)
    return new AuthError("Signature verification failed");
  if (e instanceof joseErrors.JWSInvalid) return new AuthError("Invalid JWS");
  if (e instanceof joseErrors.JOSEError) return new AuthError(e.message);
  return new AuthError((e as any)?.message ?? "Unauthorized");
}

/* -------------------------------------------------------------------------- */
/* Types                                                                       */
/* -------------------------------------------------------------------------- */

/** Typical Cognito claims you might care about; extend as needed. */
export type VerifiedUser = JWTPayload & {
  sub: string;
  email?: string;
  "cognito:username"?: string;
  token_use?: "access" | "id";
  [k: string]: unknown;
};

/* -------------------------------------------------------------------------- */
/* Public API                                                                  */
/* -------------------------------------------------------------------------- */

/**
 * Extract "Authorization: Bearer <token>" in a case-insensitive way.
 */
export function getAuthHeader(
  headers?:
    | Record<string, string | undefined>
    | undefined
): string | undefined {
  if (!headers) return undefined;
  for (const [k, v] of Object.entries(headers)) {
    if (k.toLowerCase() === "authorization") {
      return typeof v === "string" ? v : undefined;
    }
  }
  return undefined;
}

/**
 * Verify a JWT from an Authorization header.
 * - Expects "Bearer <token>"
 * - Returns typed claims on success
 * - Throws AuthError(401) on failure
 */
export async function verifyJwt(authHeader?: string): Promise<VerifiedUser> {
  if (!authHeader?.startsWith("Bearer ")) {
    throw new AuthError("Missing or malformed Authorization header");
  }
  const token = authHeader.slice("Bearer ".length);

  try {
    const { payload /*, protectedHeader*/ } = await jwtVerify(token, JWKS, {
      algorithms: ["RS256"],
      issuer: ISS,
      audience: AUDIENCE,
      clockTolerance: CLOCK_TOLERANCE_SEC,
    });

    // Optional sanity check logs (kept terse to avoid token leakage)
    if (payload.iss && payload.iss !== ISS) {
      console.warn("Issuer mismatch (post-verify)", {
        tokenIss: payload.iss,
        expected: ISS,
      });
    }
    if (payload.aud && payload.aud !== AUDIENCE) {
      console.warn("Audience mismatch (post-verify)", {
        tokenAud: payload.aud,
        expected: AUDIENCE,
      });
    }

    return payload as VerifiedUser;
  } catch (e) {
    console.error("JWT verification failed", {
      name: (e as any)?.name,
      message: (e as any)?.message,
    });
    throw mapJoseError(e);
  }
}

/**
 * Convenience wrapper used inside handlers:
 *
 *   const user = await requireAuth(event.headers);
 */
export async function requireAuth(
  headers?: Record<string, string | undefined>
): Promise<VerifiedUser> {
  const header = getAuthHeader(headers);
  return verifyJwt(header);
}
