import { useEffect, useState } from "react";
import { AlertTriangle, Swords } from "lucide-react";
import { Card, Empty, Loading, SectionTitle } from "@/components/ui";
import { useApp } from "@/lib/store";
import { useT } from "@/lib/i18n";
import { fetchNui } from "@/lib/nui";
import { dateTime, safeColor } from "@/lib/format";
import type { RaceResults } from "@/lib/types";
import { Kv, ModeBadge, useMoney } from "./common";
import { Podium, ResultsTable } from "./ResultsTable";
import { History } from "./History";

function CrewVsSummary({ results }: { results: RaceResults }) {
  const t = useT();
  const money = useMoney();
  const vs = results.crewVs;
  if (!vs) return null;
  const winner = vs.winnerCrew;
  return (
    <Card className="border-fuchsia-500/30">
      <SectionTitle>
        <span className="flex items-center gap-2">
          <Swords className="size-4 text-accent" /> {t("p.results.crewVs")}
        </span>
      </SectionTitle>
      {winner ? (
        <div className="racing-title text-2xl" style={{ color: safeColor(winner.color) }}>
          {t("p.results.winnerCrew", { name: `[${winner.tag}] ${winner.name}` })}
        </div>
      ) : (
        <div className="racing-title text-2xl">{t("p.results.draw")}</div>
      )}
      <div className="mt-3 grid gap-x-8 sm:grid-cols-2">
        <Kv label={t("p.results.scoreA")}>{vs.scoreA ?? "-"}</Kv>
        <Kv label={t("p.results.scoreB")}>{vs.scoreB ?? "-"}</Kv>
        <Kv label={t("p.results.payout")}>{money(vs.payout ?? 0)}</Kv>
        <Kv label={t("p.results.crewPointsWon")}>{vs.points ?? 0}</Kv>
      </div>
      <p className="mt-2 text-xs text-mute">{t(`p.formula.${vs.formula}`)}</p>
    </Card>
  );
}

export function Results() {
  const t = useT();
  const { results, setResults, state, config } = useApp();
  const money = useMoney();
  const [fetching, setFetching] = useState(!results);

  // Sin resultados en memoria se intenta recuperar el ultimo guardado (una sola vez)
  useEffect(() => {
    if (results) return setFetching(false);
    let alive = true;
    void fetchNui<RaceResults | null>("getLastResult").then((res) => {
      if (!alive) return;
      if (res.ok && res.data) setResults(res.data);
      setFetching(false);
    });
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const rw = results?.rewards;
  return (
    <div className="space-y-5">
      {results ? (
        <>
          <Card>
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="racing-title mr-auto text-2xl">{results.trackName}</h2>
              <ModeBadge mode={results.mode} />
              <span className="text-xs text-mute">
                {results.laps} {t("laps").toLowerCase()} · {dateTime(results.at, config.locale)}
              </span>
            </div>
            {!results.eligible && (
              <p className="mt-3 flex items-start gap-2 rounded-lg bg-warn/10 p-3 text-sm text-warn">
                <AlertTriangle className="mt-0.5 size-4 shrink-0" /> {t("p.results.notEligible")}
              </p>
            )}
            <div className="mt-5">
              <Podium rows={results.rows} />
            </div>
          </Card>
          <div className={`grid gap-4 ${rw ? "lg:grid-cols-[2fr_1fr]" : ""}`}>
            <Card>
              <SectionTitle>{t("p.results.classification")}</SectionTitle>
              <ResultsTable rows={results.rows} you={results.you} />
            </Card>
            {rw && (
              <Card>
                <SectionTitle>{t("p.results.rewards")}</SectionTitle>
                <Kv label={t("p.prize.entries")}>{money(rw.entries)}</Kv>
                <Kv label={t("p.prize.commission", { pct: config.commissionPct })}>-{money(rw.commission)}</Kv>
                <Kv label={t("p.prize.extra")}>{money(rw.extra)}</Kv>
                <Kv label={t("p.prize.base")}>{money(rw.base)}</Kv>
                <Kv label={t("p.prize.total")}>
                  <span className="text-accent">{money(rw.total)}</span>
                </Kv>
              </Card>
            )}
          </div>
          <CrewVsSummary results={results} />
        </>
      ) : fetching ? (
        <Loading />
      ) : (
        <Card>
          <Empty text={state.hasResult ? t("p.results.unavailable") : t("p.results.none")} />
        </Card>
      )}
      <History />
    </div>
  );
}
