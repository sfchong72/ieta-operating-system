import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  const localUat = process.env.IEOS_LOCAL_UAT === "1";

  return (
    <main className="flex min-h-screen items-center justify-center p-8">
      <div className="w-full max-w-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold tracking-tight">Inter Excel Operating System</h1>
          <p className="mt-1 text-xs text-neutral-400">IETA — Marketing &amp; Social Media</p>
        </div>
        <LoginForm localUat={localUat} />
      </div>
    </main>
  );
}
