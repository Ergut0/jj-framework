import type { ReactNode } from "react";
import { Shield, ShieldCheck, X } from "lucide-react";
import { NavItem } from "./ui";
import logo from "@/assets/logo.webp";
import { useT } from "@/lib/i18n";
import type { View } from "@/lib/types";

export interface NavEntry {
  id: string;
  label: string;
  icon: ReactNode;
  badge?: number;
}

/** Marco comun de las dos vistas: cabecera racing, navegacion lateral y contenido */
export function Shell({
  title,
  subtitle,
  nav,
  active,
  onNav,
  onClose,
  view,
  canSwitch,
  onSwitch,
  children,
}: {
  title: ReactNode;
  subtitle?: ReactNode;
  nav: NavEntry[];
  active: string;
  onNav: (id: string) => void;
  onClose: () => void;
  view: View;
  canSwitch: boolean;
  onSwitch: (v: View) => void;
  children: ReactNode;
}) {
  const t = useT();
  return (
    <div className="flex h-full items-center justify-center p-3 sm:p-6">
      <div className="animate-rise stripes relative flex h-full max-h-[780px] w-full max-w-[1200px] flex-col overflow-hidden rounded-2xl border border-line bg-bg/95 shadow-[0_30px_80px_-20px_rgba(0,0,0,0.9)] backdrop-blur-md">
        <div className="checker h-2 w-full shrink-0 bg-accent/30" />
        <header className="flex shrink-0 items-center gap-4 border-b border-line px-5 py-3">
          <img src={logo} alt="Atlantis Roleplay" className="h-12 w-auto shrink-0 drop-shadow-[0_4px_14px_rgba(168,85,247,0.45)]" />
          <div className="h-9 w-px shrink-0 bg-line" />
          <div className="min-w-0 flex-1">
            <div className="racing-title truncate text-xl">{title}</div>
            {subtitle && <div className="truncate text-xs text-mute">{subtitle}</div>}
          </div>
          {canSwitch && (
            <div className="flex rounded-lg border border-line p-0.5 text-xs font-bold">
              {(["player", "admin"] as const).map((v) => (
                <button
                  key={v}
                  onClick={() => onSwitch(v)}
                  className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 transition-colors ${view === v ? "bg-accent text-white" : "text-mute hover:text-ink"}`}
                >
                  {v === "player" ? <Shield className="size-3.5" /> : <ShieldCheck className="size-3.5" />}
                  <span className="hidden sm:inline">{t(v === "player" ? "app.player" : "app.admin")}</span>
                </button>
              ))}
            </div>
          )}
          <button onClick={onClose} aria-label={t("close")} title={`${t("close")} (Esc)`} className="rounded-lg p-2 text-mute transition-colors hover:bg-white/10 hover:text-ink">
            <X className="size-5" />
          </button>
        </header>
        <div className="flex min-h-0 flex-1">
          <nav className="flex w-14 shrink-0 flex-col gap-1 border-r border-line p-2 md:w-52">
            {nav.map((n) => (
              <NavItem key={n.id} active={active === n.id} icon={n.icon} label={n.label} badge={n.badge} onClick={() => onNav(n.id)} />
            ))}
          </nav>
          <main className="min-w-0 flex-1 overflow-y-auto p-4 sm:p-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
