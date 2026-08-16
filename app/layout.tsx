import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "IE Operating System",
  description: "IETA internal OS — SOPs, content ideas, tasks, knowledge base.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
