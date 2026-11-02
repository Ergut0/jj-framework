import { useState } from "react";
import { Button, Emblem, Field, Input } from "./ui";
import { useT } from "@/lib/i18n";
import { useApp } from "@/lib/store";

export interface IdentityValues {
  name: string;
  tag: string;
  color: string;
  logo: string;
}

/** Formulario de identidad de crew (crear / editar / solo aspecto) con vista previa */
export function IdentityForm({
  initial,
  mode,
  submitLabel,
  onSubmit,
  children,
}: {
  initial?: Partial<IdentityValues>;
  mode: "full" | "style";
  submitLabel: string;
  onSubmit: (v: IdentityValues) => Promise<boolean | void>;
  children?: React.ReactNode;
}) {
  const t = useT();
  const { config, toast } = useApp();
  const [v, setV] = useState<IdentityValues>({ name: "", tag: "", color: "#a855f7", logo: "", ...initial });
  const [busy, setBusy] = useState(false);
  const set = (k: keyof IdentityValues) => (e: React.ChangeEvent<HTMLInputElement>) => setV((s) => ({ ...s, [k]: e.target.value }));

  const full = mode === "full";
  const invalid = full && (v.name.trim().length < config.nameMin || v.name.trim().length > config.nameMax || v.tag.trim().length < config.tagMin || v.tag.trim().length > config.tagMax);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (invalid) return toast(t("error.generic"), "error");
    setBusy(true);
    await onSubmit({ ...v, name: v.name.trim(), tag: v.tag.trim().toUpperCase() });
    setBusy(false);
  };

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <div className="flex items-center gap-4 rounded-lg border border-line bg-bg/50 p-3">
        <Emblem color={v.color} tag={v.tag || "TAG"} logo={v.logo} size={56} />
        <div className="min-w-0">
          <div className="text-[11px] tracking-wide text-mute uppercase">{t("f.preview")}</div>
          <div className="racing-title truncate text-lg" style={{ color: v.color }}>
            [{(v.tag || "TAG").toUpperCase()}] {v.name || "…"}
          </div>
        </div>
      </div>

      {full && (
        <div className="grid gap-4 sm:grid-cols-[1fr_8rem]">
          <Field label={t("f.name")}>
            {(id) => <Input id={id} value={v.name} onChange={set("name")} maxLength={config.nameMax} autoComplete="off" required />}
          </Field>
          <Field label={t("f.tag")}>
            {(id) => <Input id={id} value={v.tag} onChange={set("tag")} maxLength={config.tagMax} className="uppercase" autoComplete="off" required />}
          </Field>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-[8rem_1fr]">
        <Field label={t("f.color")}>
          {(id) => (
            <div className="flex items-center gap-2">
              <input id={id} type="color" value={v.color} onChange={set("color")} className="h-9 w-12 cursor-pointer rounded border border-line bg-transparent p-0.5" />
              <span className="text-xs text-mute">{v.color}</span>
            </div>
          )}
        </Field>
        {config.allowLogo && (
          <Field label={t("f.logo")}>
            {(id) => <Input id={id} value={v.logo} onChange={set("logo")} placeholder="https://" maxLength={255} autoComplete="off" />}
          </Field>
        )}
      </div>

      {children}
      <Button type="submit" loading={busy} disabled={invalid}>
        {submitLabel}
      </Button>
    </form>
  );
}
