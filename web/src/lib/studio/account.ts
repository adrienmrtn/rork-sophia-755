import "server-only";
import { cache } from "react";
import type { SupabaseClient, User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

export type OnboardingStep = "identity" | "credentials" | "profile" | "agreement" | "guide" | "done";
export const ONBOARDING_STEPS: OnboardingStep[] = ["identity", "credentials", "profile", "agreement", "guide", "done"];

export interface CreatorAccount {
  user_id: string;
  slug: string | null;
  status: "pending" | "approved" | "suspended";
  first_name: string | null;
  last_name: string | null;
  display_name: string | null;
  email: string | null;
  writing_lang: string;
  title: string | null;
  institution: string | null;
  country: string | null;
  links: Record<string, string>;
  bio: string | null;
  long_bio: string | null;
  education: { degree: string; institution: string; year?: string }[];
  photo_path: string | null;
  onboarding_step: OnboardingStep;
  guide_read_at: string | null;
  approved_at: string | null;
  suspended_reason: string | null;
  created_at: string;
}

export interface StudioSession {
  supabase: SupabaseClient;
  user: User;
  account: CreatorAccount | null;
  isAdmin: boolean;
  agreementSigned: boolean;
}

/** La session du Studio : l'utilisateur, son compte créateur (s'il existe), son rôle, son contrat. */
export const getStudioSession = cache(async (): Promise<StudioSession | null> => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  const [{ data: account }, { data: isAdmin }, { data: signed }] = await Promise.all([
    supabase.from("creator_accounts").select("*").eq("user_id", user.id).maybeSingle(),
    supabase.rpc("studio_admin_touch"),
    supabase.rpc("creator_agreement_current"),
  ]);
  return {
    supabase,
    user,
    account: (account as CreatorAccount | null) ?? null,
    isAdmin: Boolean(isAdmin),
    agreementSigned: Boolean(signed),
  };
});

/** Le prochain écran du parcours d'accueil, ou null quand il est terminé. */
export function nextOnboardingPath(account: CreatorAccount | null, agreementSigned: boolean): string | null {
  if (!account) return "/studio/onboarding/identity";
  if (account.onboarding_step === "done") return null;
  if (account.onboarding_step === "agreement" && agreementSigned) return "/studio/onboarding/guide";
  return `/studio/onboarding/${account.onboarding_step}`;
}

export function displayName(account: CreatorAccount | null, user: User): string {
  return account?.display_name || [account?.first_name, account?.last_name].filter(Boolean).join(" ") || (user.user_metadata?.full_name as string | undefined) || user.email?.split("@")[0] || "You";
}

export function initialsOf(name: string): string {
  const parts = name.split(/[\s-]+/).filter(Boolean);
  const picked = parts.length >= 2 ? [parts[0], parts[parts.length - 1]] : parts.slice(0, 1);
  return picked.map((p) => p[0]?.toUpperCase() ?? "").join("") || "S";
}

/** Un slug public depuis un nom : minuscules, sans accents, tirets, 60 caractères. */
export function slugFromName(first: string, last: string): string {
  return `${first} ${last}`
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60)
    .replace(/-+$/g, "");
}
