import Image from "next/image";
import { links } from "@/lib/site";

type Tone = "saffron" | "pink" | "violet" | "cream" | "ink" | "mint" | "sky";

const toneClass: Record<Tone, string> = {
  saffron: "bg-saffron text-ink",
  pink: "bg-pink text-ink",
  violet: "bg-violet text-white",
  cream: "bg-paper text-ink",
  ink: "bg-ink text-cream",
  mint: "bg-mint text-ink",
  sky: "bg-sky text-ink",
};

export function Button({
  href,
  children,
  tone = "saffron",
  size = "md",
  className = "",
}: {
  href: string;
  children: React.ReactNode;
  tone?: Tone;
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const sizes = {
    sm: "px-4 py-2 text-sm",
    md: "px-6 py-3 text-base",
    lg: "px-8 py-4 text-lg",
  };
  const external = href.startsWith("http");
  return (
    <a
      href={href}
      {...(external ? { target: "_blank", rel: "noopener" } : {})}
      className={`brutal press inline-flex items-center justify-center gap-2 rounded-full font-display font-bold tracking-tight ${toneClass[tone]} ${sizes[size]} ${className}`}
    >
      {children}
    </a>
  );
}

export function Eyebrow({ children, tone = "cream" }: { children: React.ReactNode; tone?: Tone }) {
  return (
    <span
      className={`brutal-sm inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-[0.14em] ${toneClass[tone]}`}
    >
      {children}
    </span>
  );
}

function AppleLogo() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-6 w-6 fill-current">
      <path d="M16.37 12.6c-.02-2.2 1.8-3.26 1.88-3.31-1.02-1.5-2.62-1.7-3.19-1.72-1.36-.14-2.65.8-3.34.8-.7 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.62 1.11 8.79.73 1.06 1.6 2.25 2.75 2.2 1.1-.04 1.52-.71 2.85-.71 1.33 0 1.71.71 2.88.69 1.19-.02 1.94-1.08 2.66-2.15.84-1.23 1.19-2.42 1.21-2.48-.03-.01-2.32-.89-2.34-3.54ZM14.18 6.13c.6-.74 1.01-1.75.9-2.77-.87.04-1.94.59-2.56 1.32-.56.64-1.05 1.68-.92 2.68.98.07 1.97-.5 2.58-1.23Z" />
    </svg>
  );
}

function PlayLogo() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className="h-6 w-6">
      <path fill="#34A853" d="M3.6 2.3 13.4 12l-9.8 9.7c-.4-.2-.6-.6-.6-1.1V3.4c0-.5.2-.9.6-1.1Z" />
      <path fill="#FBBC04" d="m16.7 15.3-3.3-3.3 3.3-3.3 3.8 2.2c1 .6 1 1.6 0 2.2l-3.8 2.2Z" />
      <path fill="#EA4335" d="M16.7 15.3 13.4 12l-9.8 9.7c.4.2.9.2 1.4-.1l11.7-6.3Z" />
      <path fill="#4285F4" d="M16.7 8.7 5 2.4c-.5-.3-1-.3-1.4-.1l9.8 9.7 3.3-3.3Z" />
    </svg>
  );
}

export function StoreBadges({ className = "" }: { className?: string }) {
  const badge =
    "brutal-sm press flex items-center gap-3 rounded-2xl bg-ink px-4 py-2.5 text-cream";
  return (
    <div className={`flex flex-wrap gap-3 ${className}`}>
      <a href={links.appStore} target="_blank" rel="noopener" className={badge}>
        <AppleLogo />
        <span className="leading-tight">
          <span className="block text-[10px] font-medium opacity-80">Télécharger dans</span>
          <span className="block text-base font-bold">l&apos;App Store</span>
        </span>
      </a>
      <a href={links.playStore} target="_blank" rel="noopener" className={badge}>
        <PlayLogo />
        <span className="leading-tight">
          <span className="block text-[10px] font-medium opacity-80">Disponible sur</span>
          <span className="block text-base font-bold">Google Play</span>
        </span>
      </a>
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
      className={`h-auto w-[132px] ${className}`}
    />
  );
}

/* ---------- Stickers décoratifs (SVG maison) ---------- */

export function Starburst({ className = "", fill = "var(--color-saffron)" }: { className?: string; fill?: string }) {
  const pts: string[] = [];
  for (let i = 0; i < 24; i++) {
    const r = i % 2 === 0 ? 50 : 34;
    const a = (Math.PI * 2 * i) / 24 - Math.PI / 2;
    pts.push(`${60 + r * Math.cos(a)},${60 + r * Math.sin(a)}`);
  }
  return (
    <svg viewBox="0 0 120 120" aria-hidden className={className}>
      <polygon points={pts.join(" ")} fill={fill} stroke="var(--color-ink)" strokeWidth="4" strokeLinejoin="round" />
    </svg>
  );
}

export function Flower({ className = "", fill = "var(--color-pink)" }: { className?: string; fill?: string }) {
  return (
    <svg viewBox="0 0 120 120" aria-hidden className={className}>
      <g stroke="var(--color-ink)" strokeWidth="4" fill={fill}>
        {[0, 72, 144, 216, 288].map((r) => (
          <ellipse key={r} cx="60" cy="32" rx="18" ry="28" transform={`rotate(${r} 60 60)`} />
        ))}
        <circle cx="60" cy="60" r="14" fill="var(--color-saffron)" />
      </g>
    </svg>
  );
}

export function Spark({ className = "", fill = "var(--color-sky)" }: { className?: string; fill?: string }) {
  return (
    <svg viewBox="0 0 120 120" aria-hidden className={className}>
      <path
        d="M60 6c6 30 24 48 54 54-30 6-48 24-54 54-6-30-24-48-54-54 30-6 48-24 54-54Z"
        fill={fill}
        stroke="var(--color-ink)"
        strokeWidth="4"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function Squiggle({ className = "", stroke = "var(--color-ink)" }: { className?: string; stroke?: string }) {
  return (
    <svg viewBox="0 0 200 40" aria-hidden className={className} fill="none">
      <path
        d="M4 28c16-24 32-24 48 0s32 24 48 0 32-24 48 0 32 24 48 0"
        stroke={stroke}
        strokeWidth="6"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function Phi({ className = "", fill = "var(--color-pink)" }: { className?: string; fill?: string }) {
  return (
    <svg viewBox="0 0 100 120" aria-hidden className={className}>
      <g stroke="var(--color-ink)" strokeWidth="5" fill="none" strokeLinecap="round">
        <path d="M38 30C20 34 12 48 12 62s8 28 26 32" stroke={fill} strokeWidth="14" />
        <path d="M62 30c18 4 26 18 26 32s-8 28-26 32" stroke={fill} strokeWidth="14" />
        <path d="M50 10v100" stroke={fill} strokeWidth="14" />
      </g>
    </svg>
  );
}

export function Laurel({ className = "", flip = false }: { className?: string; flip?: boolean }) {
  return (
    <svg viewBox="0 0 40 80" aria-hidden className={className} style={flip ? { transform: "scaleX(-1)" } : undefined}>
      <path d="M30 76C12 62 8 40 18 6" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
      {[14, 26, 38, 50, 62].map((y, i) => (
        <ellipse
          key={y}
          cx={i < 2 ? 12 : 10 + i}
          cy={y}
          rx="7"
          ry="3.6"
          transform={`rotate(${-40 + i * 6} ${10 + i} ${y})`}
          fill="currentColor"
        />
      ))}
    </svg>
  );
}
