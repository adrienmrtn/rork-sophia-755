"use client";

import Image from "next/image";
import { motion, useInView, animate } from "motion/react";
import { useEffect, useRef } from "react";
import { links } from "@/lib/site";

export function Button({
  href,
  children,
  variant = "primary",
  size = "md",
  className = "",
}: {
  href: string;
  children: React.ReactNode;
  variant?: "primary" | "secondary" | "light" | "saffron";
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const sizes = { sm: "h-10 px-4 text-sm", md: "h-12 px-6 text-[15px]", lg: "h-14 px-7 text-base" };
  const variants = {
    primary: "bg-navy text-white hover:bg-navy-deep shadow-[0_8px_20px_-8px_rgba(26,58,107,0.6)]",
    secondary: "bg-paper text-navy ring-1 ring-line hover:ring-navy/30",
    light: "bg-paper text-navy hover:bg-cream",
    saffron: "bg-saffron text-ink hover:brightness-105 shadow-[0_8px_20px_-8px_rgba(242,177,52,0.8)]",
  };
  const external = href.startsWith("http");
  return (
    <motion.a
      href={href}
      {...(external ? { target: "_blank", rel: "noopener" } : {})}
      whileHover={{ y: -2 }}
      whileTap={{ scale: 0.97 }}
      transition={{ type: "spring", stiffness: 400, damping: 22 }}
      className={`inline-flex items-center justify-center gap-2 rounded-xl font-bold tracking-tight transition-colors ${variants[variant]} ${sizes[size]} ${className}`}
    >
      {children}
    </motion.a>
  );
}

function AppleLogo() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-5 w-5 fill-current">
      <path d="M16.37 12.6c-.02-2.2 1.8-3.26 1.88-3.31-1.02-1.5-2.62-1.7-3.19-1.72-1.36-.14-2.65.8-3.34.8-.7 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.62 1.11 8.79.73 1.06 1.6 2.25 2.75 2.2 1.1-.04 1.52-.71 2.85-.71 1.33 0 1.71.71 2.88.69 1.19-.02 1.94-1.08 2.66-2.15.84-1.23 1.19-2.42 1.21-2.48-.03-.01-2.32-.89-2.34-3.54ZM14.18 6.13c.6-.74 1.01-1.75.9-2.77-.87.04-1.94.59-2.56 1.32-.56.64-1.05 1.68-.92 2.68.98.07 1.97-.5 2.58-1.23Z" />
    </svg>
  );
}

function PlayLogo() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-5 w-5">
      <path fill="#34A853" d="M3.6 2.3 13.4 12l-9.8 9.7c-.4-.2-.6-.6-.6-1.1V3.4c0-.5.2-.9.6-1.1Z" />
      <path fill="#FBBC04" d="m16.7 15.3-3.3-3.3 3.3-3.3 3.8 2.2c1 .6 1 1.6 0 2.2l-3.8 2.2Z" />
      <path fill="#EA4335" d="M16.7 15.3 13.4 12l-9.8 9.7c.4.2.9.2 1.4-.1l11.7-6.3Z" />
      <path fill="#4285F4" d="M16.7 8.7 5 2.4c-.5-.3-1-.3-1.4-.1l9.8 9.7 3.3-3.3Z" />
    </svg>
  );
}

export function StoreBadges({ className = "", dark = true }: { className?: string; dark?: boolean }) {
  const tone = dark ? "bg-ink text-white hover:bg-navy" : "bg-paper text-ink hover:bg-cream";
  const badge = `flex h-12 items-center gap-2.5 rounded-xl px-4 transition-colors ${tone}`;
  return (
    <div className={`flex flex-wrap gap-3 ${className}`}>
      <motion.a whileHover={{ y: -2 }} whileTap={{ scale: 0.97 }} href={links.appStore} target="_blank" rel="noopener" className={badge}>
        <AppleLogo />
        <span className="leading-none">
          <span className="block text-[10px] font-medium opacity-70">Télécharger dans</span>
          <span className="mt-0.5 block text-[15px] font-bold">l&apos;App Store</span>
        </span>
      </motion.a>
      <motion.a whileHover={{ y: -2 }} whileTap={{ scale: 0.97 }} href={links.playStore} target="_blank" rel="noopener" className={badge}>
        <PlayLogo />
        <span className="leading-none">
          <span className="block text-[10px] font-medium opacity-70">Disponible sur</span>
          <span className="mt-0.5 block text-[15px] font-bold">Google Play</span>
        </span>
      </motion.a>
    </div>
  );
}

export function Logo({ white = false, className = "" }: { white?: boolean; className?: string }) {
  return (
    <Image
      src={white ? "/img/brand/sophia_logo_white.webp" : "/img/brand/sophia_logo.webp"}
      alt="Sophia"
      width={600}
      height={168}
      priority
      className={`h-auto w-[118px] ${className}`}
    />
  );
}

type Author = { name: string; title: string; photo: string | null };

export function Avatar({ author, size = 28, className = "" }: { author: Author; size?: number; className?: string }) {
  if (author.photo) {
    return (
      <Image
        src={author.photo}
        alt=""
        width={size}
        height={size}
        className={`shrink-0 rounded-full object-cover ring-2 ring-paper ${className}`}
        style={{ width: size, height: size }}
      />
    );
  }
  if (author.name.startsWith("La rédaction")) {
    return (
      <span
        className={`flex shrink-0 items-center justify-center rounded-full bg-ink ring-2 ring-paper ${className}`}
        style={{ width: size, height: size }}
      >
        <Image src="/img/brand/app_icon.webp" alt="" width={size} height={size} className="rounded-full" />
      </span>
    );
  }
  const initials = author.name.split(" ").slice(0, 2).map((p) => p[0]).join("");
  return (
    <span
      className={`flex shrink-0 items-center justify-center rounded-full bg-saffron-soft font-bold text-navy ring-2 ring-paper ${className}`}
      style={{ width: size, height: size, fontSize: size * 0.38 }}
    >
      {initials}
    </span>
  );
}

/** Fait monter un bloc quand il entre à l'écran. Le contenu reste toujours visible. */
export function Rise({
  children,
  delay = 0,
  className = "",
  y = 28,
}: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
  y?: number;
}) {
  return (
    <motion.div
      className={className}
      initial={{ y }}
      whileInView={{ y: 0 }}
      viewport={{ once: true, margin: "0px 0px -60px 0px" }}
      transition={{ type: "spring", stiffness: 90, damping: 18, delay: delay / 1000 }}
    >
      {children}
    </motion.div>
  );
}

/** Nombre qui défile jusqu'à sa valeur quand il apparaît (la valeur finale est rendue côté serveur). */
export function Counter({ value, className = "" }: { value: number; className?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "0px 0px -40px 0px" });
  useEffect(() => {
    if (!inView || !ref.current) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const el = ref.current;
    const controls = animate(0, value, {
      duration: 1.6,
      ease: [0.2, 0.8, 0.2, 1],
      onUpdate: (v) => (el.textContent = Math.round(v).toLocaleString("fr-FR")),
    });
    return () => controls.stop();
  }, [inView, value]);
  return (
    <span ref={ref} className={`tabular-nums ${className}`}>
      {value.toLocaleString("fr-FR")}
    </span>
  );
}

export function Arrow({ className = "h-4 w-4" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}
