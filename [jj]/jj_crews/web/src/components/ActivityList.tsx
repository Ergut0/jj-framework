import { useT, formatLog } from "@/lib/i18n";
import { dateTime } from "@/lib/format";
import { useApp } from "@/lib/store";
import type { ActivityItem } from "@/lib/types";
import { Empty } from "./ui";

/** Lista de actividad legible (historial de crew y visor de auditoria) */
export function ActivityList({ items, showCrew }: { items: (ActivityItem & { crewName?: string; admin?: boolean })[]; showCrew?: boolean }) {
  const t = useT();
  const { config } = useApp();
  if (!items.length) return <Empty text={t("act.empty")} />;
  return (
    <ul className="flex flex-col divide-y divide-line">
      {items.map((it) => (
        <li key={it.id} className="flex items-start gap-3 py-2.5 text-sm">
          <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-accent" />
          <div className="min-w-0 flex-1">
            <div className="break-words">{formatLog(t, it.action, it.actor, it.details)}</div>
            <div className="text-xs text-mute">
              {dateTime(it.createdAt, config.locale)}
              {showCrew && it.crewName ? ` · ${it.crewName}` : ""}
              {it.admin ? ` · ${t("adm.logs.admin")}` : ""}
            </div>
          </div>
        </li>
      ))}
    </ul>
  );
}
