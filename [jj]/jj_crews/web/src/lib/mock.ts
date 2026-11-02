/**
 * Backend simulado para desarrollar la UI en el navegador (bun run dev).
 * Imita el contrato de respuesta de los callbacks de Lua: { ok, data } | { ok, error }.
 * No se usa dentro del juego.
 */
import type { ActivityItem, Crew, CrewSummary, GameConfig, GameState, Invite, LogItem, Member, NuiResponse, Page, Rank, RankingRow, SettingsValues, Transaction } from "./types";

const ME = "MOCK0001";
const PERMS = ["invite", "kick", "setRank", "deposit", "withdraw", "manageRanks", "editCrew"];
const now = () => Math.floor(Date.now() / 1000);

const config: GameConfig = {
  locale: new URLSearchParams(location.search).get("lang") === "en" ? "en" : "es",
  currency: "$",
  createCost: 25000,
  maxMembers: 20,
  nameMin: 3,
  nameMax: 24,
  tagMin: 2,
  tagMax: 5,
  allowLogo: true,
  maxRanks: 8,
  permissionKeys: PERMS,
  depositAccounts: ["cash", "bank"],
  maxTransaction: 10000000,
  pageSize: 15,
  levelPoints: [0, 500, 1500, 3500, 7000, 12000, 20000, 35000, 60000, 100000],
  leaderLevel: 99,
  withdrawAccount: "cash",
};

let seq = 100;
const id = () => ++seq;

function makeRanks(): Rank[] {
  const p = (...k: string[]) => Object.fromEntries(k.map((x) => [x, true]));
  return [
    { id: id(), name: "Líder", level: 99, isLeader: true, permissions: p(...PERMS) },
    { id: id(), name: "Sublíder", level: 4, isLeader: false, permissions: p("invite", "kick", "setRank", "deposit", "withdraw") },
    { id: id(), name: "Oficial", level: 3, isLeader: false, permissions: p("invite", "kick", "deposit") },
    { id: id(), name: "Piloto", level: 2, isLeader: false, permissions: p("deposit") },
    { id: id(), name: "Novato", level: 1, isLeader: false, permissions: {} },
  ];
}

function makeCrew(name: string, tag: string, color: string, leaderCid: string, leaderName: string, extra: Partial<Crew> = {}): Crew {
  const ranks = makeRanks();
  const leader = ranks[0]!;
  const names = ["Alex Vega", "Marta Cruz", "Dani Ríos", "Lucía Mora", "Hugo Prieto"];
  const members: Member[] = [{ citizenid: leaderCid, name: leaderName, rankId: leader.id, rankLevel: 99, online: true, joinedAt: now() - 86400 * 30, isLeader: true }];
  names.slice(0, 2 + (seq % 4)).forEach((n, i) => {
    const r = ranks[1 + (i % 4)]!;
    members.push({ citizenid: `${tag}${i}`, name: n, rankId: r.id, rankLevel: r.level, online: i % 2 === 0, joinedAt: now() - 86400 * (i + 1), isLeader: false });
  });
  return { id: id(), name, tag, color, logo: "", level: 3, points: 2400, wins: 12, money: 150000, frozen: false, leader: leaderCid, createdAt: now() - 86400 * 40, ranks, members, ...extra };
}

const crews: Crew[] = [
  makeCrew("Apex Predators", "APX", "#a855f7", ME, "Tú (Mock)", { points: 4200, wins: 31, level: 4 }),
  makeCrew("Night Drifters", "NDR", "#a855f7", "L2", "Kenji Sato", { points: 9800, wins: 58, level: 5 }),
  makeCrew("Redline Society", "RLS", "#f59e0b", "L3", "Ana Ruiz", { points: 1300, wins: 6, level: 2 }),
  makeCrew("Turbo Kings", "TRB", "#22d3ee", "L4", "Leo Marín", { points: 600, wins: 2, level: 2, frozen: true }),
];

const txs: Transaction[] = Array.from({ length: 23 }, (_, i) => ({
  id: i + 1,
  name: ["Tú (Mock)", "Alex Vega", "Marta Cruz"][i % 3]!,
  type: i % 4 === 0 ? "withdraw" : "deposit",
  amount: (i % 4 === 0 ? -1 : 1) * (1000 + i * 350),
  balance: 150000 - i * 900,
  note: "",
  createdAt: now() - i * 7200,
}));

const logs: LogItem[] = [];
function log(crew: Crew | null, action: string, details: Record<string, unknown> = {}, admin = false) {
  logs.unshift({ id: id(), crewId: crew?.id ?? 0, crewName: crew?.name ?? "", actorCid: ME, actor: "Tú (Mock)", action, details, admin, createdAt: now() });
}
log(crews[0]!, "crew_create", { name: "Apex Predators" });
log(crews[0]!, "member_join", { target: "Alex Vega", rank: "Piloto" });
log(crews[0]!, "bank_deposit", { amount: 5000, balance: 150000 });

let invites: Invite[] = [
  { id: id(), crewId: crews[1]!.id, crewName: "Night Drifters", crewTag: "NDR", color: "#a855f7", logo: "", invitedBy: "Kenji Sato", expiresAt: now() + 1800, members: 5 },
];

const settings: SettingsValues = { maxMembers: 20, createCost: 25000, nameMin: 3, nameMax: 24, maxRanks: 8, inviteExpiryMinutes: 30, allowLogo: true, bannedNames: ["admin", "staff", "policia"] };
const schema = {
  maxMembers: { t: "int", min: 2, max: 100 }, createCost: { t: "int", min: 0, max: 100000000 }, nameMin: { t: "int", min: 2, max: 16 },
  nameMax: { t: "int", min: 8, max: 40 }, maxRanks: { t: "int", min: 3, max: 20 }, inviteExpiryMinutes: { t: "int", min: 1, max: 10080 },
};

const wallet = { cash: 80000, bank: 120000 };
const myCrew = () => crews.find((c) => c.members.some((m) => m.citizenid === ME));

const ok = <T,>(data: T): NuiResponse<T> => ({ ok: true, data });
const fail = <T,>(error: string): NuiResponse<T> => ({ ok: false, error });

function withMe(c: Crew): Crew {
  const m = c.members.find((x) => x.citizenid === ME)!;
  const rank = c.ranks.find((r) => r.id === m.rankId)!;
  const next = config.levelPoints[c.level];
  return {
    ...structuredClone(c),
    nextLevelPoints: next,
    me: { citizenid: ME, rankId: rank.id, level: rank.level, isLeader: m.isLeader, permissions: Object.fromEntries(PERMS.map((p) => [p, m.isLeader || !!rank.permissions[p]])) },
  };
}

function page<T>(items: T[], p: unknown, size = config.pageSize): Page<T> {
  const n = Math.max(1, Number(p) || 1);
  return { items: items.slice((n - 1) * size, n * size), total: items.length, page: n, pageSize: size };
}

const summary = (c: Crew): CrewSummary => ({
  id: c.id, name: c.name, tag: c.tag, color: c.color, logo: c.logo, level: c.level, points: c.points, wins: c.wins, money: c.money,
  frozen: c.frozen, members: c.members.length, leaderName: c.members.find((m) => m.isLeader)?.name ?? "-", createdAt: c.createdAt,
});

type D = Record<string, any>;

function crewOf(d: D) {
  return crews.find((c) => c.id === d.id);
}

function handle(action: string, d: D): NuiResponse<any> {
  const mine = myCrew();
  switch (action) {
    case "getState": {
      const state: GameState = { player: { citizenid: ME, name: "Tú (Mock)", cash: wallet.cash, bank: wallet.bank }, isAdmin: true, crew: mine ? withMe(mine) : null, invites, config };
      return ok(state);
    }
    case "createCrew": {
      if (mine) return fail("Ya perteneces a un crew.");
      if (!d.name || d.name.length < 3) return fail("Nombre inválido.");
      if (crews.some((c) => c.name.toLowerCase() === String(d.name).toLowerCase())) return fail("Ese nombre ya está en uso.");
      if (wallet.bank < config.createCost) return fail("No tienes dinero suficiente.");
      wallet.bank -= config.createCost;
      const c = makeCrew(d.name, d.tag, d.color, ME, "Tú (Mock)", { points: 0, wins: 0, level: 1, money: 0 });
      c.members = c.members.slice(0, 1);
      crews.push(c);
      return ok({ id: c.id });
    }
    case "updateCrew":
      if (!mine) return fail("No perteneces a ningún crew.");
      mine.color = d.color;
      mine.logo = d.logo ?? "";
      return ok(null);
    case "invite":
      return ok(null);
    case "respondInvite": {
      const inv = invites.find((i) => i.id === d.inviteId);
      if (!inv) return fail("Invitación no encontrada.");
      invites = invites.filter((i) => i !== inv);
      if (d.accept) {
        const c = crews.find((x) => x.id === inv.crewId)!;
        const low = c.ranks.filter((r) => !r.isLeader).sort((a, b) => a.level - b.level)[0]!;
        c.members.push({ citizenid: ME, name: "Tú (Mock)", rankId: low.id, rankLevel: low.level, online: true, joinedAt: now(), isLeader: false });
      }
      return ok(null);
    }
    case "leave":
      if (!mine) return fail("No perteneces a ningún crew.");
      if (mine.leader === ME) return fail("El líder no puede salir: transfiere el liderazgo o disuelve el crew.");
      mine.members = mine.members.filter((m) => m.citizenid !== ME);
      return ok(null);
    case "disband":
      if (!mine || d.confirm !== mine.name) return fail("La confirmación no coincide.");
      if (mine.money > 0) return fail("Retira los fondos del banco antes de disolver el crew.");
      crews.splice(crews.indexOf(mine), 1);
      return ok(null);
    case "deposit":
    case "withdraw": {
      if (!mine) return fail("No perteneces a ningún crew.");
      const amount = Number(d.amount);
      if (!Number.isInteger(amount) || amount < 1) return fail("Importe inválido.");
      if (action === "deposit") {
        const acc = d.account === "cash" ? "cash" : "bank";
        if (wallet[acc] < amount) return fail("No tienes dinero suficiente.");
        wallet[acc] -= amount;
        mine.money += amount;
      } else {
        if (mine.money < amount) return fail("El banco del crew no tiene fondos suficientes.");
        mine.money -= amount;
        wallet.cash += amount;
      }
      txs.unshift({ id: id(), name: "Tú (Mock)", type: action, amount: action === "deposit" ? amount : -amount, balance: mine.money, note: "", createdAt: now() });
      log(mine, action === "deposit" ? "bank_deposit" : "bank_withdraw", { amount });
      return ok({ balance: mine.money });
    }
    case "getTransactions":
      return ok(page(txs, d.page));
    case "getActivity":
      return ok(page(logs.filter((l) => l.crewId === mine?.id && !l.admin) as ActivityItem[], d.page));
    case "getRanking": {
      const sorted = [...crews].sort((a, b) => b.points - a.points);
      const rows: RankingRow[] = sorted.map((c, i) => ({ pos: i + 1, id: c.id, name: c.name, tag: c.tag, color: c.color, logo: c.logo, level: c.level, points: c.points, wins: c.wins, members: c.members.length }));
      return ok({ top: rows, mine: rows.find((r) => r.id === mine?.id) });
    }
    case "kick":
    case "adminKick": {
      const c = action === "kick" ? mine : crewOf(d);
      if (!c) return fail("El crew no existe.");
      const m = c.members.find((x) => x.citizenid === d.citizenid);
      if (!m || m.isLeader) return fail("No puedes hacerlo sobre el líder.");
      c.members = c.members.filter((x) => x !== m);
      log(c, "member_kick", { target: m.name }, action !== "kick");
      return ok(null);
    }
    case "setRank":
    case "adminSetRank": {
      const c = action === "setRank" ? mine : crewOf(d);
      const m = c?.members.find((x) => x.citizenid === d.citizenid);
      const r = c?.ranks.find((x) => x.id === d.rankId);
      if (!c || !m || !r || r.isLeader) return fail("Rango inválido.");
      m.rankId = r.id;
      m.rankLevel = r.level;
      return ok(null);
    }
    case "transferLeader":
    case "adminSetLeader": {
      const c = action === "transferLeader" ? mine : crewOf(d);
      const m = c?.members.find((x) => x.citizenid === d.citizenid);
      if (!c || !m) return fail("Ese jugador no es miembro del crew.");
      const lr = c.ranks.find((r) => r.isLeader)!;
      const top = c.ranks.filter((r) => !r.isLeader).sort((a, b) => b.level - a.level)[0]!;
      const old = c.members.find((x) => x.isLeader)!;
      old.isLeader = false; old.rankId = top.id; old.rankLevel = top.level;
      m.isLeader = true; m.rankId = lr.id; m.rankLevel = lr.level;
      c.leader = m.citizenid;
      return ok(null);
    }
    case "createRank":
    case "adminCreateRank": {
      const c = action === "createRank" ? mine : crewOf(d);
      if (!c) return fail("El crew no existe.");
      if (c.ranks.some((r) => r.level === d.level)) return fail("Ya existe un rango con ese nivel.");
      c.ranks.push({ id: id(), name: d.name, level: d.level, isLeader: false, permissions: d.permissions ?? {} });
      c.ranks.sort((a, b) => b.level - a.level);
      return ok(null);
    }
    case "updateRank":
    case "adminUpdateRank": {
      const c = action === "updateRank" ? mine : crewOf(d);
      const r = c?.ranks.find((x) => x.id === d.rankId);
      if (!r || r.isLeader) return fail("Ese rango no se puede modificar.");
      r.name = d.name;
      r.permissions = d.permissions ?? {};
      return ok(null);
    }
    case "deleteRank":
    case "adminDeleteRank": {
      const c = action === "deleteRank" ? mine : crewOf(d);
      const r = c?.ranks.find((x) => x.id === d.rankId);
      if (!c || !r || r.isLeader) return fail("Ese rango no se puede modificar.");
      if (c.members.some((m) => m.rankId === r.id)) return fail("El rango tiene miembros asignados.");
      c.ranks = c.ranks.filter((x) => x !== r);
      return ok(null);
    }

    // Admin -------------------------------------------------------------------------
    case "adminList": {
      const s = String(d.search ?? "").toLowerCase();
      let list = crews.map(summary).filter((c) => (d.filter === "frozen" ? c.frozen : d.filter === "active" ? !c.frozen : true));
      if (s) list = list.filter((c) => [c.name, c.tag, c.leaderName, String(c.id)].some((v) => v.toLowerCase().includes(s)));
      const sortMap: Record<string, keyof CrewSummary> = { name: "name", members: "members", created: "createdAt", money: "money" };
      const key = sortMap[String(d.sort)] ?? "points";
      list.sort((a, b) => (key === "name" ? a.name.localeCompare(b.name) : Number(b[key]) - Number(a[key])));
      return ok(page(list, d.page));
    }
    case "adminGetCrew": {
      const c = crewOf(d);
      return c ? ok(structuredClone(c)) : fail("El crew no existe.");
    }
    case "adminCreate": {
      const c = makeCrew(d.name, d.tag, d.color, d.leaderCid, "Jugador " + d.leaderCid, { points: 0, wins: 0, level: 1, money: 0 });
      c.members = c.members.slice(0, 1);
      crews.push(c);
      return ok({ id: c.id });
    }
    case "adminUpdate": {
      const c = crewOf(d);
      if (!c) return fail("El crew no existe.");
      Object.assign(c, { name: d.name, tag: d.tag, color: d.color, logo: d.logo ?? "" });
      return ok(null);
    }
    case "adminFreeze": {
      const c = crewOf(d);
      if (!c) return fail("El crew no existe.");
      c.frozen = !!d.frozen;
      return ok(null);
    }
    case "adminDelete": {
      const c = crewOf(d);
      if (!c) return fail("El crew no existe.");
      crews.splice(crews.indexOf(c), 1);
      log(c, "crew_delete", { name: c.name }, true);
      return ok(null);
    }
    case "adminAddMember": {
      const c = crewOf(d);
      if (!c) return fail("El crew no existe.");
      const low = c.ranks.filter((r) => !r.isLeader).sort((a, b) => a.level - b.level)[0]!;
      c.members.push({ citizenid: d.citizenid, name: "Jugador " + d.citizenid, rankId: low.id, rankLevel: low.level, online: false, joinedAt: now(), isLeader: false });
      return ok(null);
    }
    case "adminEditStat": {
      const c = crewOf(d);
      if (!c) return fail("El crew no existe.");
      if (!d.reason || String(d.reason).length < 3) return fail("Debes indicar un motivo (min. 3 caracteres).");
      const stat = d.stat as "money" | "points" | "wins" | "level";
      const before = c[stat];
      const target = d.mode === "set" ? d.value : before + d.value;
      if (target < 0) return fail("Importe inválido.");
      c[stat] = target;
      log(c, `stat_${stat}`, { from: before, to: target, reason: d.reason }, true);
      return ok(null);
    }
    case "adminLogs": {
      let list = logs.filter((l) => (!d.crewId || l.crewId === d.crewId) && (!d.action || l.action === d.action));
      if (d.search) list = list.filter((l) => `${l.actor} ${l.actorCid} ${l.crewName}`.toLowerCase().includes(String(d.search).toLowerCase()));
      return ok(page(list, d.page));
    }
    case "adminGetSettings":
      return ok({ values: settings, schema });
    case "adminSaveSettings":
      Object.assign(settings, d.settings);
      return ok(settings);
    case "close":
      return ok(null);
    default:
      return fail(`Acción desconocida: ${action}`);
  }
}

export async function mockNui<T>(action: string, data: unknown): Promise<NuiResponse<T>> {
  await new Promise((r) => setTimeout(r, 150));
  return handle(action, (data ?? {}) as D) as NuiResponse<T>;
}
