/** Icônes au trait, même épaisseur partout. */
type P = { className?: string; filled?: boolean };
const base = (className = "h-5 w-5") => ({
  className,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
  "aria-hidden": true,
});

export const IconHome = ({ className, filled }: P) => (
  <svg {...base(className)} fill={filled ? "currentColor" : "none"}>
    <path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" />
  </svg>
);
export const IconCompass = ({ className }: P) => (
  <svg {...base(className)}>
    <circle cx="12" cy="12" r="9" />
    <path d="m15.5 8.5-2 5-5 2 2-5z" />
  </svg>
);
export const IconUsers = ({ className }: P) => (
  <svg {...base(className)}>
    <circle cx="9" cy="8" r="3.5" />
    <path d="M2.5 20c.6-3.6 3.3-5.5 6.5-5.5s5.9 1.9 6.5 5.5" />
    <path d="M16 4.6a3.5 3.5 0 0 1 0 6.8M18 14.8c2 .7 3.2 2.5 3.5 5.2" />
  </svg>
);
export const IconLayers = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="m12 3 9 5-9 5-9-5z" />
    <path d="m3 13 9 5 9-5" />
  </svg>
);
export const IconSpark = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="M12 3c.9 4.7 3.3 7.1 8 8-4.7.9-7.1 3.3-8 8-.9-4.7-3.3-7.1-8-8 4.7-.9 7.1-3.3 8-8z" />
  </svg>
);
export const IconCrown = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="m3 7 4.5 4L12 4l4.5 7L21 7l-2 12H5z" />
  </svg>
);
export const IconPen = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z" />
    <path d="m13.5 6.5 4 4" />
  </svg>
);
export const IconDownload = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="M12 4v11M7 10l5 5 5-5M5 20h14" />
  </svg>
);
export const IconHeart = ({ className, filled }: P) => (
  <svg {...base(className)} fill={filled ? "currentColor" : "none"}>
    <path d="M12 20s-7.5-4.6-9-9.4C2 7.2 4.2 4.5 7.2 4.5c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3 0 5.2 2.7 4.2 6.1-1.5 4.8-9 9.4-9 9.4z" />
  </svg>
);
export const IconBookmark = ({ className, filled }: P) => (
  <svg {...base(className)} fill={filled ? "currentColor" : "none"}>
    <path d="M6 3h12v18l-6-4.5L6 21z" />
  </svg>
);
export const IconShare = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="M12 3v12M7.5 7.5 12 3l4.5 4.5M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6" />
  </svg>
);
export const IconLock = ({ className }: P) => (
  <svg {...base(className)}>
    <rect x="4.5" y="10.5" width="15" height="10.5" rx="2.5" />
    <path d="M8 10.5V7a4 4 0 0 1 8 0v3.5" />
  </svg>
);
export const IconSearch = ({ className }: P) => (
  <svg {...base(className)}>
    <circle cx="11" cy="11" r="7" />
    <path d="m20 20-3.5-3.5" />
  </svg>
);
export const IconCheck = ({ className }: P) => (
  <svg {...base(className)}>
    <path d="m5 12.5 4.5 4.5L19 7.5" />
  </svg>
);
export const IconClock = ({ className }: P) => (
  <svg {...base(className)}>
    <circle cx="12" cy="12" r="9" />
    <path d="M12 7v5l3 2" />
  </svg>
);
export const IconVerified = ({ className }: P) => (
  <svg className={className ?? "h-4 w-4"} viewBox="0 0 24 24" aria-label="Auteur vérifié">
    <path
      fill="currentColor"
      d="m12 1.5 2.6 2 3.2-.3 1 3.1 2.7 1.8-.9 3.1.9 3.1-2.7 1.8-1 3.1-3.2-.3-2.6 2-2.6-2-3.2.3-1-3.1-2.7-1.8.9-3.1-.9-3.1 2.7-1.8 1-3.1 3.2.3z"
    />
    <path d="m8 12.2 2.6 2.6L16.2 9" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
