import { APP_STORE_URL, PLAY_STORE_URL } from "@/lib/env";
import { t } from "@/lib/copy/en";

function AppleIcon({ color = "#FFFFFF" }: { color?: string }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill={color} aria-hidden="true">
      <path d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.9-.8-3.1-.8c-1.6 0-3.1.9-3.9 2.4-1.7 2.9-.4 7.2 1.2 9.5.8 1.2 1.8 2.5 3 2.4 1.2 0 1.7-.8 3.1-.8s1.9.8 3.2.8c1.3 0 2.1-1.2 2.9-2.3.9-1.3 1.3-2.6 1.3-2.7 0 0-2.8-1-2.8-4.1zM14.1 5.9c.6-.8 1.1-1.8 1-2.9-.9 0-2.1.6-2.7 1.4-.6.7-1.1 1.8-1 2.8 1 .1 2.1-.5 2.7-1.3z" />
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg width="20" height="22" viewBox="0 0 22 24" aria-hidden="true">
      <path d="M1.5 1.2 12.6 12 1.5 22.8c-.3-.3-.5-.8-.5-1.3V2.5c0-.5.2-1 .5-1.3z" fill="#4FC3F7" />
      <path d="M16.2 8.4 12.6 12 1.5 1.2c.4-.4 1.1-.5 1.7-.1l13 7.3z" fill="#81C784" />
      <path d="M16.2 15.6 3.2 22.9c-.6.3-1.3.3-1.7-.1L12.6 12l3.6 3.6z" fill="#E57373" />
      <path d="M20.4 10.8c.8.5.8 1.9 0 2.4l-4.2 2.4L12.6 12l3.6-3.6 4.2 2.4z" fill="#FFD54F" />
    </svg>
  );
}

/** Les deux boutons des stores, grands (avec la ligne du haut) ou compacts. */
export function StoreButtons({ size = "large", className = "" }: { size?: "large" | "compact"; className?: string }) {
  if (size === "compact") {
    return (
      <div className={`flex flex-wrap gap-2.5 ${className}`}>
        <a href={APP_STORE_URL} className="inline-flex h-[46px] items-center gap-2 rounded-btn bg-ink px-[18px] text-[14px] font-extrabold text-white" aria-label={`${t.stores.appStoreTop} ${t.stores.appStore}`}>
          <AppleIcon /> {t.stores.appStore}
        </a>
        <a href={PLAY_STORE_URL} className="inline-flex h-[46px] items-center gap-2 rounded-btn bg-ink px-[18px] text-[14px] font-extrabold text-white" aria-label={`${t.stores.playTop} ${t.stores.play}`}>
          <PlayIcon /> {t.stores.play}
        </a>
      </div>
    );
  }
  return (
    <div className={`flex flex-wrap items-center gap-3 ${className}`}>
      <a href={APP_STORE_URL} className="inline-flex h-14 items-center gap-2.5 rounded-btn bg-ink px-[18px] text-white" aria-label={`${t.stores.appStoreTop} ${t.stores.appStore}`}>
        <AppleIcon />
        <span className="flex flex-col leading-[1.1]">
          <span className="text-[11px] font-medium opacity-85">{t.stores.appStoreTop}</span>
          <span className="text-[17px] font-bold">{t.stores.appStore}</span>
        </span>
      </a>
      <a href={PLAY_STORE_URL} className="inline-flex h-14 items-center gap-2.5 rounded-btn bg-ink px-[18px] text-white" aria-label={`${t.stores.playTop} ${t.stores.play}`}>
        <PlayIcon />
        <span className="flex flex-col leading-[1.1]">
          <span className="text-[11px] font-medium opacity-85">{t.stores.playTop}</span>
          <span className="text-[17px] font-bold">{t.stores.play}</span>
        </span>
      </a>
    </div>
  );
}
