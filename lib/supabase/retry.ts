/**
 * Retries once after a short delay when a Supabase/PostgREST call fails with
 * PGRST303 ("JWT issued at future") — a transient clock-skew race between
 * Supabase Auth (which just minted the session's JWT) and PostgREST (which
 * validates it), most likely to appear on the very first query made
 * immediately after a fresh login. It self-heals within roughly a second in
 * practice, so retrying once with a short delay is enough — this is not a
 * bug in the query itself.
 */
export async function withJwtClockSkewRetry<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    const code = (err as { code?: string } | null)?.code;
    if (code !== "PGRST303") throw err;
    await new Promise((resolve) => setTimeout(resolve, 1200));
    return await fn();
  }
}
