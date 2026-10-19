/**
 * A drop-in `fetch` replacement that retries once, after a short delay, when
 * a request fails with PGRST303 ("JWT issued at future") — a transient
 * clock-skew race between Supabase Auth (which just minted the session's
 * JWT) and PostgREST (which validates it). Most likely to appear on the
 * very first query made immediately after a fresh login; self-heals within
 * roughly a second in practice.
 *
 * Plugged into every Supabase client this app creates (`lib/supabase/
 * server.ts`, `client.ts`, `admin.ts`, and the auth callback route) via the
 * `global: { fetch }` client option — every `.from(...)`/`.rpc(...)` call
 * made through any of those clients is covered automatically, including
 * ones added by future milestones. No per-function wrapping needed, and
 * none should be added going forward — fix it here if this ever needs
 * adjusting, not query-by-query.
 */
const CLOCK_SKEW_RETRY_DELAY_MS = 1200;

export const fetchWithJwtClockSkewRetry: typeof fetch = async (input, init) => {
  const response = await fetch(input, init);
  if (response.ok) return response;

  let isClockSkew = false;
  try {
    const body = await response.clone().json();
    isClockSkew = body?.code === "PGRST303";
  } catch {
    // Response body isn't JSON (or is a stream that can't be cloned safely)
    // — not the case we're guarding against.
  }
  if (!isClockSkew) return response;

  await new Promise((resolve) => setTimeout(resolve, CLOCK_SKEW_RETRY_DELAY_MS));
  return fetch(input, init);
};
