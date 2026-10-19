import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Keep the interactive UAT server isolated from `next build`, which writes
  // production artifacts to `.next` and can otherwise invalidate dev assets.
  distDir: process.env.NODE_ENV === "development" ? ".next-dev" : ".next",
};

export default nextConfig;
