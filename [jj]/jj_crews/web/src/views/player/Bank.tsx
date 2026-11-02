import { useState } from "react";
import { ArrowDownToLine, ArrowUpFromLine } from "lucide-react";
import { Badge, Button, Card, ErrorState, Empty, Field, Input, Loading, Pagination, SectionTitle, Select } from "@/components/ui";
import type { CrewCtx } from "@/components/ctx";
import { useApp } from "@/lib/store";
import { useAsync } from "@/lib/hooks";
import { useT, type Key } from "@/lib/i18n";
import { dateTime, money } from "@/lib/format";
import type { Page, Transaction } from "@/lib/types";

export function Bank({ ctx }: { ctx: CrewCtx }) {
  const t = useT();
  const { state, config, call, reload } = useApp();
  const { crew } = ctx;
  const [page, setPage] = useState(1);
  const [amount, setAmount] = useState("");
  const [account, setAccount] = useState(config.depositAccounts[0] ?? "cash");
  const [busy, setBusy] = useState<"deposit" | "withdraw" | null>(null);
  const tx = useAsync(() => call<Page<Transaction>>("getTransactions", { page }), [page, crew.money]);

  const value = Math.floor(Number(amount));
  const valid = Number.isFinite(value) && value > 0 && value <= config.maxTransaction;

  const submit = async (kind: "deposit" | "withdraw") => {
    setBusy(kind);
    const payload = kind === "deposit" ? { amount: value, account } : { amount: value };
    const res = await call(kind, payload, t(kind === "deposit" ? "bank.deposited" : "bank.withdrawn"));
    setBusy(null);
    if (res.ok) {
      setAmount("");
      await reload();
    }
  };

  const wallet = state.player[account as "cash" | "bank"] ?? 0;

  return (
    <div className="grid gap-4 xl:grid-cols-[22rem_1fr]">
      <div className="flex flex-col gap-4">
        <Card>
          <div className="text-xs font-semibold tracking-wide text-mute uppercase">{t("bank.balance")}</div>
          <div className="racing-title mt-1 text-4xl" style={{ color: crew.color }}>
            {money(crew.money, config.currency)}
          </div>
        </Card>
        <Card className="flex flex-col gap-4">
          {ctx.can("deposit") && (
            <Field label={t("bank.account")} hint={t("bank.yours", { account: t(`bank.${account}` as Key), amount: money(wallet, config.currency) })}>
              {(id) => (
                <Select id={id} value={account} onChange={(e) => setAccount(e.target.value)}>
                  {config.depositAccounts.map((a) => (
                    <option key={a} value={a}>{t(`bank.${a}` as Key)}</option>
                  ))}
                </Select>
              )}
            </Field>
          )}
          <Field label={t("bank.amount")}>
            {(id) => <Input id={id} type="number" min={1} max={config.maxTransaction} value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0" />}
          </Field>
          <div className="flex gap-2">
            {ctx.can("deposit") && (
              <Button className="flex-1" loading={busy === "deposit"} disabled={!valid || crew.frozen} onClick={() => submit("deposit")}>
                <ArrowDownToLine className="size-4" /> {t("bank.deposit")}
              </Button>
            )}
            {ctx.can("withdraw") && (
              <Button variant="outline" className="flex-1" loading={busy === "withdraw"} disabled={!valid || crew.frozen} onClick={() => submit("withdraw")}>
                <ArrowUpFromLine className="size-4" /> {t("bank.withdraw")}
              </Button>
            )}
          </div>
        </Card>
      </div>

      <Card>
        <SectionTitle>{t("bank.history")}</SectionTitle>
        {tx.loading && !tx.data ? (
          <Loading />
        ) : tx.error ? (
          <ErrorState message={tx.error} onRetry={tx.reload} />
        ) : !tx.data?.items.length ? (
          <Empty text={t("bank.empty")} />
        ) : (
          <>
            <ul className="flex flex-col divide-y divide-line">
              {tx.data.items.map((r) => (
                <li key={r.id} className="flex items-center gap-3 py-2.5 text-sm">
                  <Badge color={r.amount >= 0 ? "#22c55e" : "#ef4444"}>{t(`tx.${r.type}` as Key)}</Badge>
                  <div className="min-w-0 flex-1">
                    <div className="truncate">{r.name || "-"}{r.note && r.type !== "deposit" && r.type !== "withdraw" ? ` · ${r.note}` : ""}</div>
                    <div className="text-xs text-mute">{dateTime(r.createdAt, config.locale)}</div>
                  </div>
                  <div className="text-right">
                    <div className={`font-bold ${r.amount >= 0 ? "text-ok" : "text-bad"}`}>
                      {r.amount >= 0 ? "+" : "-"}{money(Math.abs(r.amount), config.currency)}
                    </div>
                    <div className="text-xs text-mute">{money(r.balance, config.currency)}</div>
                  </div>
                </li>
              ))}
            </ul>
            <Pagination page={tx.data.page} total={tx.data.total} pageSize={tx.data.pageSize} onChange={setPage} />
          </>
        )}
      </Card>
    </div>
  );
}
