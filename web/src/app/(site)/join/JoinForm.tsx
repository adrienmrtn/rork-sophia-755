"use client";

import { useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";
import { t } from "@/lib/copy/en";

type Mode = "create" | "signin";

function GoogleIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.9h5.4a4.6 4.6 0 0 1-2 3v2.5h3.2c1.9-1.7 3-4.3 3-7.4z" fill="#4285F4" />
      <path d="M12 22c2.7 0 5-.9 6.6-2.4l-3.2-2.5c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H3.1v2.6A10 10 0 0 0 12 22z" fill="#34A853" />
      <path d="M6.4 14a6 6 0 0 1 0-3.9V7.5H3.1a10 10 0 0 0 0 9z" fill="#FBBC05" />
      <path d="M12 6c1.5 0 2.8.5 3.8 1.5l2.9-2.9A10 10 0 0 0 3.1 7.5l3.3 2.6C7.2 7.8 9.4 6 12 6z" fill="#EA4335" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="#16263D" aria-hidden="true">
      <path d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.9-.8-3.1-.8c-1.6 0-3.1.9-3.9 2.4-1.7 2.9-.4 7.2 1.2 9.5.8 1.2 1.8 2.5 3 2.4 1.2 0 1.7-.8 3.1-.8s1.9.8 3.2.8c1.3 0 2.1-1.2 2.9-2.3.9-1.3 1.3-2.6 1.3-2.7 0 0-2.8-1-2.8-4.1zM14.1 5.9c.6-.8 1.1-1.8 1-2.9-.9 0-2.1.6-2.7 1.4-.6.7-1.1 1.8-1 2.8 1 .1 2.1-.5 2.7-1.3z" />
    </svg>
  );
}

export function JoinForm({ next, initialMode = "create", initialError }: { next: string; initialMode?: Mode; initialError?: string | null }) {
  const [mode, setMode] = useState<Mode>(initialMode);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(initialError ?? null);
  const j = t.join;

  const callback = () => `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;

  async function oauth(provider: "google" | "apple") {
    setBusy(true);
    setError(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: callback() } });
    if (error) {
      setError(error.message);
      setBusy(false);
    }
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setMessage(null);
    const supabase = createClient();
    if (mode === "create") {
      const { data, error } = await supabase.auth.signUp({ email, password, options: { emailRedirectTo: callback() } });
      if (error) setError(error.message);
      else if (data.session) window.location.assign(next);
      else setMessage(j.confirmSent);
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) setError(error.message);
      else window.location.assign(next);
    }
    setBusy(false);
  }

  async function magicLink() {
    if (!email) {
      setError("Enter your email address first.");
      return;
    }
    setBusy(true);
    setError(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: callback() } });
    if (error) setError(error.message);
    else setMessage(j.magicSent);
    setBusy(false);
  }

  const tab = (m: Mode, label: string) => (
    <button
      type="button"
      onClick={() => {
        setMode(m);
        setError(null);
        setMessage(null);
      }}
      className={`flex h-[42px] flex-1 items-center justify-center rounded-[11px] text-[14px] font-bold ${mode === m ? "bg-white text-ink shadow-[0_1px_3px_rgba(22,38,61,.08)]" : "text-ink-3"}`}
      aria-pressed={mode === m}
    >
      {label}
    </button>
  );

  return (
    <section aria-labelledby="join-title" className="flex w-full max-w-[460px] flex-col gap-5 rounded-[28px] border border-line bg-white p-7 shadow-[0_20px_50px_rgba(22,38,61,.08)] md:p-9">
      <div className="flex gap-1.5 rounded-btn bg-paper p-1">
        {tab("create", j.tabCreate)}
        {tab("signin", j.tabSignIn)}
      </div>
      <div className="flex flex-col gap-1.5">
        <h2 id="join-title" className="text-[24px] font-extrabold tracking-[-0.5px]">
          {mode === "create" ? j.createTitle : j.signInTitle}
        </h2>
        <p className="text-[14px] leading-[1.5] text-ink-3">{mode === "create" ? j.createLead : j.signInLead}</p>
      </div>
      <div className="flex flex-col gap-2.5">
        <button type="button" disabled={busy} onClick={() => oauth("google")} className="inline-flex h-[50px] items-center justify-center gap-3 rounded-btn border border-line bg-white text-[15px] font-bold text-ink hover:bg-paper disabled:opacity-60">
          <GoogleIcon /> {j.google}
        </button>
        <button type="button" disabled={busy} onClick={() => oauth("apple")} className="inline-flex h-[50px] items-center justify-center gap-3 rounded-btn border border-line bg-white text-[15px] font-bold text-ink hover:bg-paper disabled:opacity-60">
          <AppleIcon /> {j.apple}
        </button>
      </div>
      <div className="flex items-center gap-3 text-[12px] font-semibold text-muted">
        <span className="h-px flex-1 bg-line" />
        {j.orEmail}
        <span className="h-px flex-1 bg-line" />
      </div>
      <form onSubmit={submit} className="flex flex-col gap-3">
        <label className="flex flex-col gap-1.5 text-[13px] font-bold text-ink-2">
          {j.email}
          <input type="email" required autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder={j.emailPlaceholder} className="h-12 rounded-xl border border-line px-3.5 text-[15px] font-normal text-ink outline-none focus:border-blue" />
        </label>
        <label className="flex flex-col gap-1.5 text-[13px] font-bold text-ink-2">
          {j.password}
          <input type="password" required minLength={8} autoComplete={mode === "create" ? "new-password" : "current-password"} value={password} onChange={(e) => setPassword(e.target.value)} placeholder={j.passwordPlaceholder} className="h-12 rounded-xl border border-line px-3.5 text-[15px] font-normal text-ink outline-none focus:border-blue" />
        </label>
        {error && (
          <p role="alert" className="rounded-xl bg-red-bg px-3.5 py-2.5 text-[13px] font-semibold text-red">
            {error}
          </p>
        )}
        {message && (
          <p role="status" className="rounded-xl bg-green-bg px-3.5 py-2.5 text-[13px] font-semibold text-green">
            {message}
          </p>
        )}
        <button type="submit" disabled={busy} className="h-[50px] rounded-btn bg-navy text-[15px] font-extrabold text-white hover:bg-ink disabled:opacity-60">
          {mode === "create" ? j.createButton : j.signInButton}
        </button>
        <button type="button" disabled={busy} onClick={magicLink} className="text-center text-[13px] font-bold text-blue">
          {j.magicLink}
        </button>
      </form>
      <p className="text-[12px] leading-[1.5] text-muted">{j.legal}</p>
    </section>
  );
}
