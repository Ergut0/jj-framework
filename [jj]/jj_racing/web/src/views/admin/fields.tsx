import { useEffect, useState, type InputHTMLAttributes, type ReactNode } from "react";
import { Button, ConfirmDialog, Input } from "@/components/ui";
import { useT } from "@/lib/i18n";
import { cn } from "@/lib/utils";
import { parseCoords } from "./draft";

const clamp = (n: number, min?: number, max?: number) => Math.min(max ?? Infinity, Math.max(min ?? -Infinity, n));

/**
 * Numero editable por texto: acepta estados intermedios ("-", "12.") sin saltar al minimo
 * y solo ajusta a los limites al perder el foco.
 */
export function DecimalInput({
  value,
  onChange,
  min,
  max,
  integer,
  className,
  ...rest
}: Omit<InputHTMLAttributes<HTMLInputElement>, "value" | "onChange" | "min" | "max"> & {
  value: number;
  onChange: (v: number) => void;
  min?: number;
  max?: number;
  integer?: boolean;
}) {
  const [text, setText] = useState(String(value));
  useEffect(() => {
    setText((prev) => (prev.trim() !== "" && Number(prev) === value ? prev : String(value)));
  }, [value]);

  return (
    <Input
      {...rest}
      inputMode={integer ? "numeric" : "decimal"}
      value={text}
      onChange={(e) => {
        const raw = e.target.value;
        setText(raw);
        const n = Number(raw);
        if (raw.trim() !== "" && Number.isFinite(n)) onChange(integer ? Math.trunc(n) : n);
      }}
      onBlur={() => {
        const n = Number(text);
        const next = text.trim() === "" || !Number.isFinite(n) ? (min ?? 0) : clamp(integer ? Math.trunc(n) : n, min, max);
        setText(String(next));
        onChange(next);
      }}
      className={cn("tabular", className)}
    />
  );
}

export const MIN_REASON = 3;

/** Confirmacion con motivo obligatorio (minimo 3 caracteres, como exige el servidor) */
export function ReasonDialog({
  title,
  message,
  loading,
  danger = true,
  onConfirm,
  onClose,
  children,
}: {
  title: string;
  message: string;
  loading?: boolean;
  danger?: boolean;
  onConfirm: (reason: string) => void;
  onClose: () => void;
  children?: ReactNode;
}) {
  const t = useT();
  const [reason, setReason] = useState("");
  const clean = reason.trim();
  return (
    <ConfirmDialog title={title} message={message} danger={danger} loading={loading} disabled={clean.length < MIN_REASON} onConfirm={() => onConfirm(clean)} onClose={onClose}>
      <div className="flex flex-col gap-3">
        <div className="flex flex-col gap-1.5">
          <label htmlFor="admin-reason" className="text-xs font-semibold tracking-wide text-mute uppercase">
            {t("reason")}
          </label>
          <Input id="admin-reason" autoFocus maxLength={120} value={reason} onChange={(e) => setReason(e.target.value)} placeholder={t("a.reasonHint", { min: MIN_REASON })} />
        </div>
        {children}
      </div>
    </ConfirmDialog>
  );
}

/** Copia al portapapeles; si la API no esta disponible (NUI sin contexto seguro) usa execCommand */
export async function copyText(text: string, fallback?: HTMLTextAreaElement | null): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    if (!fallback) return false;
    fallback.focus();
    fallback.select();
    try {
      return document.execCommand("copy");
    } catch {
      return false;
    }
  }
}

export function IconButton({ label, onClick, children, danger, disabled }: { label: string; onClick: () => void; children: ReactNode; danger?: boolean; disabled?: boolean }) {
  return (
    <button
      type="button"
      title={label}
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
      className={cn(
        "rounded-md p-2 transition-colors disabled:pointer-events-none disabled:opacity-40",
        danger ? "text-mute hover:bg-bad/15 hover:text-bad" : "text-mute hover:bg-white/10 hover:text-ink",
      )}
    >
      {children}
    </button>
  );
}

/** Caja para pegar coordenadas ("vector4(1, 2, 3, 90)", "1 2 3"...) y anadirlas como nueva fila */
export function PasteCoords({ min, placeholder, onAdd }: { min: number; placeholder: string; onAdd: (nums: number[]) => void }) {
  const t = useT();
  const [text, setText] = useState("");
  const nums = parseCoords(text);
  const valid = nums.length >= min;
  const submit = () => {
    if (!valid) return;
    onAdd(nums);
    setText("");
  };
  return (
    <div className="flex gap-2">
      <Input
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => e.key === "Enter" && submit()}
        placeholder={placeholder}
        aria-label={t("a.paste.label")}
        className={cn("font-mono text-xs", text && !valid && "border-bad")}
      />
      <Button variant="outline" size="sm" disabled={!valid} onClick={submit}>
        {t("add")}
      </Button>
    </div>
  );
}
