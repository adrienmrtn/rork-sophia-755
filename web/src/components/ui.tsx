import Link from "next/link";
import type { ComponentProps, ReactNode } from "react";

/** Les briques de la maquette : boutons, pastilles, cartes. Classes Tailwind partagées. */

export const container = "mx-auto w-full max-w-[1240px] px-6";

const button = {
  primary: "inline-flex h-11 items-center justify-center gap-2 rounded-btn bg-navy px-[18px] text-[15px] font-bold text-white hover:bg-ink",
  secondary: "inline-flex h-11 items-center justify-center gap-2 rounded-btn border border-line bg-white px-[18px] text-[15px] font-bold text-navy hover:bg-paper",
  ghost: "inline-flex h-11 items-center justify-center gap-2 rounded-btn px-4 text-[15px] font-bold text-navy hover:bg-paper",
  dark: "inline-flex h-11 items-center justify-center gap-2 rounded-btn bg-ink px-[18px] text-[15px] font-bold text-white hover:bg-navy",
  light: "inline-flex h-11 items-center justify-center gap-2 rounded-btn bg-white px-[18px] text-[15px] font-extrabold text-navy hover:bg-tint",
} as const;

export type ButtonVariant = keyof typeof button;

export function buttonClass(variant: ButtonVariant = "primary", extra = "") {
  return `${button[variant]} ${extra}`.trim();
}

export function ButtonLink({ variant = "primary", className = "", ...props }: ComponentProps<typeof Link> & { variant?: ButtonVariant }) {
  return <Link {...props} className={buttonClass(variant, className)} />;
}

export function Pill({ tone = "tint", children, className = "" }: { tone?: "tint" | "green" | "amber" | "red" | "cream"; children: ReactNode; className?: string }) {
  const tones = {
    tint: "bg-tint text-navy",
    green: "bg-green-bg text-green",
    amber: "bg-amber-bg text-amber",
    red: "bg-red-bg text-red",
    cream: "bg-cream text-amber",
  };
  return <span className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-[13px] font-bold ${tones[tone]} ${className}`}>{children}</span>;
}

export function Eyebrow({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <span className={`text-[13px] font-bold uppercase tracking-[1.2px] text-blue ${className}`}>{children}</span>;
}

export function Card({ children, className = "", id }: { children: ReactNode; className?: string; id?: string }) {
  return (
    <div id={id} className={`rounded-card border border-line bg-white ${className}`}>
      {children}
    </div>
  );
}

export function Dot() {
  return <span aria-hidden="true" className="inline-block h-1 w-1 rounded-full bg-line-2" />;
}

export function ArrowIcon({ className = "" }: { className?: string }) {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={className}>
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

export function CheckIcon({ className = "" }: { className?: string }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={className}>
      <path d="M5 12l5 5L20 7" />
    </svg>
  );
}

export function Initials({ name, size = 56, className = "" }: { name: string; size?: number; className?: string }) {
  const parts = name.split(/[\s-]+/).filter(Boolean);
  const picked = parts.length >= 2 ? [parts[0], parts[parts.length - 1]] : parts.slice(0, 1);
  const initials = picked.map((p) => p[0]?.toUpperCase() ?? "").join("");
  return (
    <span
      aria-hidden="true"
      className={`inline-flex shrink-0 items-center justify-center rounded-full bg-tint font-extrabold text-navy ${className}`}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}
    >
      {initials}
    </span>
  );
}
