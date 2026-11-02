import { useEffect, useId, type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes } from "react";
import { AlertTriangle, ChevronLeft, ChevronRight, Inbox, Loader2, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useT } from "@/lib/i18n";
import { safeLogo } from "@/lib/format";

// Botones ----------------------------------------------------------------------

type Variant = "primary" | "ghost" | "danger" | "outline";
const variants: Record<Variant, string> = {
  primary: "bg-accent text-white hover:brightness-110 shadow-[0_0_18px_-6px_var(--accent)]",
  ghost: "bg-white/5 text-ink hover:bg-white/10",
  outline: "border border-line text-ink hover:border-accent hover:text-accent",
  danger: "bg-bad/15 text-bad hover:bg-bad/25 border border-bad/30",
};

export function Button({
  variant = "primary",
  loading,
  size = "md",
  className,
  children,
  disabled,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; loading?: boolean; size?: "sm" | "md" }) {
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={cn(
        "cut-sm racing-title inline-flex items-center justify-center gap-2 transition-all duration-150 active:scale-[0.97] disabled:pointer-events-none disabled:opacity-40",
        size === "sm" ? "px-3 py-1.5 text-xs" : "px-5 py-2.5 text-sm",
        variants[variant],
        className,
      )}
    >
      {loading && <Loader2 className="size-4 animate-spin" />}
      {children}
    </button>
  );
}

// Formularios ---------------------------------------------------------------------

export function Field({ label, hint, children }: { label: string; hint?: string; children: (id: string) => ReactNode }) {
  const id = useId();
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-xs font-semibold tracking-wide text-mute uppercase">
        {label}
      </label>
      {children(id)}
      {hint && <span className="text-xs text-mute">{hint}</span>}
    </div>
  );
}

const fieldClass =
  "w-full rounded-md border border-line bg-bg/70 px-3 py-2 text-sm text-ink outline-none transition-colors placeholder:text-mute/60 focus:border-accent disabled:opacity-50";

export function Input({ className, ...rest }: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...rest} className={cn(fieldClass, className)} />;
}

export function Select({ className, children, ...rest }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...rest} className={cn(fieldClass, "cursor-pointer", className)}>
      {children}
    </select>
  );
}

export function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <label className="flex cursor-pointer items-center gap-3 text-sm">
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={cn("relative h-5 w-9 shrink-0 rounded-full transition-colors", checked ? "bg-accent" : "bg-line")}
      >
        <span className={cn("absolute top-0.5 left-0.5 size-4 rounded-full bg-white transition-transform", checked && "translate-x-4")} />
      </button>
      {label}
    </label>
  );
}

// Contenedores -----------------------------------------------------------------------

export function Card({ className, children }: { className?: string; children: ReactNode }) {
  return <div className={cn("animate-rise rounded-xl border border-line bg-panel/90 p-5 backdrop-blur", className)}>{children}</div>;
}

export function SectionTitle({ children, action }: { children: ReactNode; action?: ReactNode }) {
  return (
    <div className="mb-4 flex items-center justify-between gap-3">
      <h3 className="racing-title text-base text-ink">{children}</h3>
      {action}
    </div>
  );
}

export function Badge({ children, color, className }: { children: ReactNode; color?: string; className?: string }) {
  return (
    <span
      className={cn("inline-flex items-center rounded px-2 py-0.5 text-[11px] font-bold tracking-wide uppercase", !color && "bg-white/10 text-ink", className)}
      style={color ? { background: `${color}26`, color } : undefined}
    >
      {children}
    </span>
  );
}

export function StatTile({ label, value, icon, hint }: { label: string; value: ReactNode; icon?: ReactNode; hint?: ReactNode }) {
  return (
    <div className="animate-rise rounded-xl border border-line bg-panel2/70 p-4">
      <div className="flex items-center gap-2 text-xs font-semibold tracking-wide text-mute uppercase">
        {icon}
        {label}
      </div>
      <div className="racing-title mt-1 text-2xl">{value}</div>
      {hint && <div className="mt-1 text-xs text-mute">{hint}</div>}
    </div>
  );
}

/** Logo del crew (si es valido) o su tag sobre el color del crew */
export function Emblem({ color, tag, logo, size = 44 }: { color: string; tag: string; logo?: string; size?: number }) {
  const src = safeLogo(logo);
  return (
    <div
      className="cut flex shrink-0 items-center justify-center overflow-hidden font-display text-xs font-extrabold text-white italic"
      style={{ width: size, height: size, background: color, fontSize: size * 0.3 }}
    >
      {src ? (
        <img src={src} alt="" referrerPolicy="no-referrer" className="size-full object-cover" onError={(e) => (e.currentTarget.style.display = "none")} />
      ) : (
        tag.slice(0, 4)
      )}
    </div>
  );
}

// Estados ------------------------------------------------------------------------------

export function Spinner({ className }: { className?: string }) {
  return <Loader2 className={cn("size-5 animate-spin text-accent", className)} />;
}

export function Loading() {
  const t = useT();
  return (
    <div className="flex items-center justify-center gap-3 py-16 text-sm text-mute">
      <Spinner /> {t("loading")}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message?: string; onRetry?: () => void }) {
  const t = useT();
  return (
    <div className="flex flex-col items-center gap-3 py-12 text-center text-sm text-mute">
      <AlertTriangle className="size-8 text-bad" />
      <p>{message || t("error.generic")}</p>
      {onRetry && (
        <Button variant="outline" size="sm" onClick={onRetry}>
          {t("retry")}
        </Button>
      )}
    </div>
  );
}

export function Empty({ text }: { text?: string }) {
  const t = useT();
  return (
    <div className="flex flex-col items-center gap-2 py-12 text-sm text-mute">
      <Inbox className="size-8 opacity-50" />
      {text ?? t("empty")}
    </div>
  );
}

// Dialogos --------------------------------------------------------------------------------

export function Modal({ title, onClose, children, wide }: { title: string; onClose: () => void; children: ReactNode; wide?: boolean }) {
  const t = useT();
  useEffect(() => {
    // Gestiona ESC en el documento antes que el cierre global de la NUI
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="animate-fade fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div role="dialog" aria-modal="true" aria-label={title} className={cn("animate-rise max-h-[90vh] w-full overflow-y-auto rounded-xl border border-line bg-panel p-6 shadow-2xl", wide ? "max-w-2xl" : "max-w-md")}>
        <div className="mb-4 flex items-center justify-between">
          <h3 className="racing-title text-lg">{title}</h3>
          <button onClick={onClose} aria-label={t("close")} className="rounded p-1 text-mute hover:bg-white/10 hover:text-ink">
            <X className="size-4" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function ConfirmDialog({
  title,
  message,
  danger,
  loading,
  onConfirm,
  onClose,
  children,
  disabled,
}: {
  title: string;
  message: string;
  danger?: boolean;
  loading?: boolean;
  disabled?: boolean;
  onConfirm: () => void;
  onClose: () => void;
  children?: ReactNode;
}) {
  const t = useT();
  return (
    <Modal title={title} onClose={onClose}>
      <p className="mb-4 text-sm text-mute">{message}</p>
      {children}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          {t("cancel")}
        </Button>
        <Button variant={danger ? "danger" : "primary"} loading={loading} disabled={disabled} onClick={onConfirm}>
          {t("confirm")}
        </Button>
      </div>
    </Modal>
  );
}

// Paginacion -------------------------------------------------------------------------------

export function Pagination({ page, total, pageSize, onChange }: { page: number; total: number; pageSize: number; onChange: (p: number) => void }) {
  const t = useT();
  const pages = Math.max(1, Math.ceil(total / pageSize));
  if (pages <= 1) return null;
  return (
    <div className="mt-4 flex items-center justify-center gap-3 text-xs text-mute">
      <Button variant="ghost" size="sm" disabled={page <= 1} onClick={() => onChange(page - 1)} aria-label={t("prev")}>
        <ChevronLeft className="size-4" />
      </Button>
      {t("page", { page, pages })}
      <Button variant="ghost" size="sm" disabled={page >= pages} onClick={() => onChange(page + 1)} aria-label={t("next")}>
        <ChevronRight className="size-4" />
      </Button>
    </div>
  );
}

export function NavItem({ active, icon, label, badge, onClick }: { active: boolean; icon: ReactNode; label: string; badge?: number; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      aria-current={active ? "page" : undefined}
      className={cn(
        "group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors",
        active ? "bg-white/8 text-ink" : "text-mute hover:bg-white/5 hover:text-ink",
      )}
    >
      <span className={cn("absolute top-2 bottom-2 left-0 w-0.5 rounded bg-accent transition-opacity", active ? "opacity-100" : "opacity-0")} />
      <span className={cn("transition-colors", active && "text-accent")}>{icon}</span>
      <span className="hidden md:inline">{label}</span>
      {!!badge && <span className="ml-auto hidden rounded-full bg-accent px-1.5 text-[10px] text-white md:inline">{badge}</span>}
    </button>
  );
}
