import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center p-8">
      <div className="w-full max-w-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold tracking-tight">IEOS</h1>
          <p className="text-sm text-neutral-500">Inter Excel Operations System</p>
          <p className="mt-1 text-xs text-neutral-400">IETA — Marketing &amp; Social Media</p>
        </div>
        <LoginForm />
      </div>
    </main>
  );
}
