import { NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/data/access";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

/** Authenticated database readiness; /api/health remains process liveness. */
export async function GET() {
  try {
    const currentUser = await getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ ready: false }, { status: 401 });
    }
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("ieos_readiness");
    return NextResponse.json(
      { ready: !error && data === true },
      { status: !error && data === true ? 200 : 503 },
    );
  } catch {
    return NextResponse.json({ ready: false }, { status: 503 });
  }
}
