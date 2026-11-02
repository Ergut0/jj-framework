'use strict';

const inGame = typeof window.invokeNative !== 'undefined' || typeof window.GetParentResourceName === 'function';
const resource = typeof window.GetParentResourceName === 'function' ? window.GetParentResourceName() : 'jj_boosting';

// Textos
const STRINGS = {
  es: {
    home: 'Inicio', contracts: 'Contratos', progress: 'Progresión', profile: 'Perfil', store: 'Tienda', history: 'Historial',
    leaderboard: 'Clasificación', admin: 'Administración', balance: 'Saldo', level: 'Nivel', experience: 'Experiencia',
    completed: 'Completados', failed: 'Perdidos', currentClass: 'Clase actual', activeContract: 'Contrato en marcha',
    noActive: 'No tienes ningún contrato en marcha.', queue: 'Cola de contratos', queueOn: 'Buscando contratos…',
    queueOff: 'No estás en la cola.', join: 'Entrar en la cola', leave: 'Salir de la cola', offers: 'Contratos disponibles',
    noOffers: 'No hay contratos disponibles. Entra en la cola para recibirlos.', accept: 'Aceptar', decline: 'Rechazar',
    abandon: 'Abandonar', zone: 'Zona', dropoff: 'Entrega', money: 'Dinero', xp: 'EXP', expires: 'Caduca en', plate: 'Matrícula',
    buyContracts: 'Comprar contratos', buy: 'Comprar', locked: 'Bloqueada', unlockAt: 'Se desbloquea con', hack: 'Hackeo',
    tracker: 'Rastreador', guards: 'Protectores', electronicLock: 'Cerradura', minPolice: 'Policías mínimos', rewards: 'Recompensas',
    toNext: 'para el siguiente nivel', maxLevel: 'Nivel máximo', editProfile: 'Editar perfil', displayName: 'Nombre visible',
    avatarUrl: 'URL de la imagen (https)', save: 'Guardar', stats: 'Estadísticas', moneyEarned: 'Dinero ganado', cryptoEarned: 'Cripto ganada',
    transactions: 'Movimientos', noTransactions: 'Sin movimientos.', concept: 'Concepto', amount: 'Cantidad', date: 'Fecha',
    stock: 'Stock', unlimited: 'Sin límite', limit: 'Límite', pickup: 'Se recoge en el punto', pending: 'Pendientes de recoger', collect: 'Recoger',
    requires: 'Requiere', noItems: 'No hay artículos a la venta.', allResults: 'Todos los resultados', allClasses: 'Todas las clases',
    result: 'Resultado', class: 'Clase', vehicle: 'Vehículo', duration: 'Duración', noHistory: 'Sin registros.', previous: 'Anterior', next: 'Siguiente',
    position: 'Pos.', player: 'Jugador', lastActivity: 'Última actividad', noLeaderboard: 'Todavía no hay nadie en la clasificación.',
    r_completed: 'Completado', r_failed: 'Perdido', r_expired: 'Caducado', r_abandoned: 'Abandonado', r_declined: 'Rechazado',
    s_searching: 'Busca el vehículo en la zona marcada', s_located: 'Encuentra y roba el vehículo', s_stolen: 'Llévalo al punto de entrega',
    trackerActive: 'RASTREADOR ACTIVO', trackerKey: 'Pulsa %s dentro del vehículo para desactivarlo', trackerWait: 'Accesible en %s',
    hackLock: 'CERRADURA ELECTRÓNICA', hackTracker: 'RASTREADOR GPS', hackHelp: 'Pulsa los códigos en el orden indicado.', attemptsLeft: 'Intentos', hackOk: 'ACCESO CONCEDIDO', hackFail: 'ACCESO DENEGADO',
    a_summary: 'Resumen', a_players: 'Jugadores', a_history: 'Historial', a_config: 'Contratos', a_logs: 'Registros', profiles: 'Perfiles', lost: 'Perdidos',
    moneyPaid: 'Dinero pagado', cryptoCirculating: 'Cripto en circulación', policeOnDuty: 'Policías de servicio', activeContracts: 'Contratos en marcha', noActiveAdmin: 'Ningún contrato en marcha.',
    cancel: 'Cancelar', search: 'Buscar por nombre o identificador', find: 'Buscar', noPlayers: 'Sin resultados.', back: 'Volver', assign: 'Asignar contrato', adjustXp: 'Ajustar EXP', adjustCrypto: 'Ajustar cripto',
    apply: 'Aplicar', delta: 'Cantidad, + o -', resetStock: 'Reponer stock de la tienda', multiplier: 'Multiplicador de recompensas', enabled: 'Activo', disabled: 'Desactivado', allCategories: 'Todas las categorías', action: 'Acción', actor: 'Autor', target: 'Objetivo', details: 'Detalles', status: 'Estado', online: 'Conectado', offline: 'Desconectado', error: 'No se ha podido completar', identifier: 'Identificador',
  },
  en: {
    home: 'Home', contracts: 'Contracts', progress: 'Progress', profile: 'Profile', store: 'Store', history: 'History',
    leaderboard: 'Leaderboard', admin: 'Admin', balance: 'Balance', level: 'Level', experience: 'Experience',
    completed: 'Completed', failed: 'Lost', currentClass: 'Current class', activeContract: 'Active contract',
    noActive: 'You have no active contract.', queue: 'Contract queue', queueOn: 'Searching for contracts…',
    queueOff: 'You are not in the queue.', join: 'Join queue', leave: 'Leave queue', offers: 'Available contracts',
    noOffers: 'No contracts available. Join the queue to receive them.', accept: 'Accept', decline: 'Decline',
    abandon: 'Give up', zone: 'Area', dropoff: 'Drop-off', money: 'Money', xp: 'XP', expires: 'Expires in', plate: 'Plate',
    buyContracts: 'Buy contracts', buy: 'Buy', locked: 'Locked', unlockAt: 'Unlocks at', hack: 'Hack',
    tracker: 'Tracker', guards: 'Guards', electronicLock: 'Lock', minPolice: 'Minimum police', rewards: 'Rewards',
    toNext: 'to next level', maxLevel: 'Max level', editProfile: 'Edit profile', displayName: 'Display name',
    avatarUrl: 'Image URL (https)', save: 'Save', stats: 'Statistics', moneyEarned: 'Money earned', cryptoEarned: 'Crypto earned',
    transactions: 'Transactions', noTransactions: 'No transactions.', concept: 'Concept', amount: 'Amount', date: 'Date',
    stock: 'Stock', unlimited: 'Unlimited', limit: 'Limit', pickup: 'Collected at the point', pending: 'Waiting for pick-up', collect: 'Collect',
    requires: 'Requires', noItems: 'Nothing for sale.', allResults: 'All results', allClasses: 'All classes',
    result: 'Result', class: 'Class', vehicle: 'Vehicle', duration: 'Duration', noHistory: 'No records.', previous: 'Previous', next: 'Next',
    position: 'Pos.', player: 'Player', lastActivity: 'Last activity', noLeaderboard: 'Nobody on the leaderboard yet.',
    r_completed: 'Completed', r_failed: 'Lost', r_expired: 'Expired', r_abandoned: 'Abandoned', r_declined: 'Declined',
    s_searching: 'Find the vehicle in the marked area', s_located: 'Find and steal the vehicle', s_stolen: 'Take it to the drop-off',
    trackerActive: 'TRACKER ACTIVE', trackerKey: 'Press %s inside the vehicle to disable it', trackerWait: 'Reachable in %s',
    hackLock: 'ELECTRONIC LOCK', hackTracker: 'GPS TRACKER', hackHelp: 'Press the codes in the given order.', attemptsLeft: 'Attempts', hackOk: 'ACCESS GRANTED', hackFail: 'ACCESS DENIED',
    a_summary: 'Summary', a_players: 'Players', a_history: 'History', a_config: 'Contracts', a_logs: 'Logs', profiles: 'Profiles', lost: 'Lost',
    moneyPaid: 'Money paid', cryptoCirculating: 'Crypto in circulation', policeOnDuty: 'Police on duty', activeContracts: 'Active contracts', noActiveAdmin: 'No active contracts.',
    cancel: 'Cancel', search: 'Search by name or identifier', find: 'Search', noPlayers: 'No results.', back: 'Back', assign: 'Assign contract', adjustXp: 'Adjust XP', adjustCrypto: 'Adjust crypto',
    apply: 'Apply', delta: 'Amount, + or -', resetStock: 'Restock the store', multiplier: 'Reward multiplier', enabled: 'Enabled', disabled: 'Disabled', allCategories: 'All categories', action: 'Action', actor: 'Author', target: 'Target', details: 'Details', status: 'Status', online: 'Online', offline: 'Offline', error: 'Could not be completed', identifier: 'Identifier',
  },
};

let locale = 'es';
const t = (key, ...args) => {
  let text = (STRINGS[locale] && STRINGS[locale][key]) || STRINGS.es[key] || key;
  args.forEach((arg) => { text = text.replace('%s', arg); });
  return text;
};

// Todo lo que llega de fuera pasa por aquí antes de pintarse
const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const num = (value) => Number(value || 0).toLocaleString(locale === 'en' ? 'en-US' : 'es-ES');
const $ = (selector) => document.querySelector(selector);

function clock(seconds) {
  const total = Math.max(0, Math.floor(seconds || 0));
  const m = Math.floor(total / 60);
  const s = String(total % 60).padStart(2, '0');
  return m >= 60 ? `${Math.floor(m / 60)}h ${String(m % 60).padStart(2, '0')}m` : `${m}:${s}`;
}

function formatDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? esc(value) : date.toLocaleString(locale === 'en' ? 'en-GB' : 'es-ES', { dateStyle: 'short', timeStyle: 'short' });
}

const ICONS = {
  home: 'M3 11l9-8 9 8M5 10v10h14V10',
  contracts: 'M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h7',
  progress: 'M4 20V10M10 20V4M16 20v-7M21 20H3',
  profile: 'M12 12a4 4 0 100-8 4 4 0 000 8zM4 21c1-5 4-7 8-7s7 2 8 7',
  store: 'M4 8h16l-1 13H5zM8 8a4 4 0 018 0',
  history: 'M12 7v5l3 2M4 12a8 8 0 108-8 8 8 0 00-7 4M4 4v4h4',
  leaderboard: 'M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0zM7 6H4v2a3 3 0 003 3M17 6h3v2a3 3 0 01-3 3',
  admin: 'M12 3l8 3v6c0 5-3 8-8 9-5-1-8-4-8-9V6z',
};
const icon = (name) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="${ICONS[name]}"/></svg>`;

// Comunicación con el juego

async function post(endpoint, body) {
  const response = await fetch(`https://${resource}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body || {}),
  });
  return response.json();
}

async function api(name, payload) {
  try {
    const result = inGame ? await post('api', { name, payload }) : await mockApi(name, payload);
    if (result && result.message) toast(result.message, result.ok ? 'ok' : 'error');
    return result || { ok: false };
  } catch (error) {
    toast(t('error'), 'error');
    return { ok: false };
  }
}

function toast(message, kind) {
  const element = document.createElement('div');
  element.className = `toast ${kind === 'error' ? 'error' : ''}`;
  element.textContent = message;
  $('#toasts').appendChild(element);
  setTimeout(() => element.remove(), 3200);
}

// Estado

const state = {
  tab: 'home',
  dash: null,
  history: { page: 0, result: '', class: '' },
  admin: { tab: 'summary', term: '', page: 0, category: '', selected: null, histPage: 0 },
  countdowns: [],
};

const TABS = ['home', 'contracts', 'progress', 'profile', 'store', 'history', 'leaderboard'];

function renderNav() {
  const tabs = state.dash && state.dash.isAdmin ? [...TABS, 'admin'] : TABS;
  $('#nav').innerHTML = tabs.map((tab) => `<button type="button" class="nav-item ${state.tab === tab ? 'active' : ''}" data-tab="${tab}">${icon(tab)}<span>${esc(t(tab))}</span></button>`).join('');
  const profile = state.dash && state.dash.profile;
  $('#balance').innerHTML = profile ? `<small>${esc(t('balance'))}</small><strong>${num(profile.crypto)}</strong> <span class="muted">${esc(state.dash.cryptoName)}</span>` : '';
  $('#title').textContent = t(state.tab);
}

async function loadDash() {
  const result = await api('getDashboard');
  if (result.ok) {
    state.dash = result;
    if (result.locale) locale = result.locale;
  }
  return result.ok;
}

async function go(tab) {
  state.tab = tab;
  await render();
}

let renderId = 0;

async function render() {
  const id = ++renderId;
  if (!state.dash) await loadDash();
  if (state.tab === 'admin' && !(state.dash && state.dash.isAdmin)) state.tab = 'home';
  renderNav();
  state.countdowns = [];
  const view = $('#view');
  const html = await VIEWS[state.tab]();
  // Otra pantalla pedida mientras tanto: esta ya no vale
  if (id !== renderId) return;
  view.innerHTML = html;
  view.scrollTop = 0;
  view.style.animation = 'none';
  void view.offsetWidth;
  view.style.animation = '';
}

const statTile = (label, value, extra = '') => `<div class="card stat"><small>${esc(label)}</small><strong>${value}</strong>${extra}</div>`;

function offerCard(offer) {
  const tags = [
    `<span class="badge">${esc(offer.tier)}</span>`,
    offer.hack ? `<span class="badge accent">${esc(t('hack'))}</span>` : '',
    offer.tracker ? `<span class="badge bad">${esc(t('tracker'))}</span>` : '',
    offer.guards ? `<span class="badge warn">${esc(t('guards'))}</span>` : '',
  ].join('');
  return `<article class="card contract">
    <div class="row"><span class="class-tag">${esc(offer.class)}</span><div style="min-width:0"><h3>${esc(offer.model)}</h3><div class="tags">${tags}</div></div></div>
    <dl>
      <div><dt>${esc(t('zone'))}</dt><dd>${esc(offer.zone)}</dd></div>
      <div><dt>${esc(t('dropoff'))}</dt><dd>${esc(offer.dropoff)}</dd></div>
      <div><dt>${esc(t('money'))}</dt><dd class="good">$${num(offer.money)}</dd></div>
      <div><dt>${esc(state.dash.cryptoName)}</dt><dd class="accent">+${num(offer.crypto)}</dd></div>
      <div><dt>${esc(t('xp'))}</dt><dd>+${num(offer.xp)}</dd></div>
      <div><dt>${esc(t('expires'))}</dt><dd class="mono">${clock(offer.remaining)}</dd></div>
    </dl>
    <div class="row">
      <button type="button" class="btn primary" data-act="accept" data-uid="${esc(offer.uid)}" ${state.dash.active ? 'disabled' : ''}>${esc(t('accept'))}</button>
      <button type="button" class="btn" data-act="decline" data-uid="${esc(offer.uid)}">${esc(t('decline'))}</button>
    </div>
  </article>`;
}

function activeCard(contract) {
  if (!contract) return `<div class="empty">${esc(t('noActive'))}</div>`;
  const line = contract.status === 'stolen' && contract.dropoff ? contract.dropoff.label : contract.zone.label;
  return `<article class="card contract">
    <div class="row between">
      <div class="row" style="min-width:0"><span class="class-tag">${esc(contract.class)}</span><div style="min-width:0"><h3>${esc(contract.model)}</h3><span class="muted mono">${esc(contract.plate)}</span></div></div>
      <button type="button" class="btn danger small" data-act="abandon">${esc(t('abandon'))}</button>
    </div>
    <div class="status-line"><span class="pulse"></span>${esc(t(`s_${contract.status}`))} — ${esc(line)}</div>
    <dl>
      <div><dt>${esc(t('money'))}</dt><dd class="good">$${num(contract.money)}</dd></div>
      <div><dt>${esc(state.dash.cryptoName)}</dt><dd class="accent">+${num(contract.crypto)}</dd></div>
      <div><dt>${esc(t('xp'))}</dt><dd>+${num(contract.xp)}</dd></div>
      <div><dt>${esc(t('expires'))}</dt><dd class="mono">${clock(contract.remaining)}</dd></div>
    </dl>
    ${contract.tracker ? `<div class="tags"><span class="badge bad">${esc(t('trackerActive'))}</span></div>` : ''}
  </article>`;
}

function queueCard() {
  const queued = state.dash.queued;
  return `<div class="card row between">
    <div class="status-line" style="${queued ? '' : 'color:var(--muted)'}">${queued ? '<span class="pulse"></span>' : ''}${esc(t(queued ? 'queueOn' : 'queueOff'))}</div>
    <button type="button" class="btn ${queued ? '' : 'primary'}" data-act="${queued ? 'leave' : 'join'}" ${state.dash.active ? 'disabled' : ''}>${esc(t(queued ? 'leave' : 'join'))}</button>
  </div>`;
}

function levelBar(profile) {
  const span = profile.nextLevelXp ? profile.nextLevelXp - profile.levelXp : 1;
  const done = profile.nextLevelXp ? profile.xp - profile.levelXp : 1;
  const percent = Math.max(0, Math.min(100, (done / span) * 100));
  const note = profile.nextLevelXp ? `${num(profile.nextLevelXp - profile.xp)} ${esc(t('xp'))} ${esc(t('toNext'))}` : esc(t('maxLevel'));
  return `<div class="row between" style="margin-bottom:6px"><strong>${esc(t('level'))} ${num(profile.level)}</strong><span class="muted">${note}</span></div><div class="bar"><i style="width:${percent}%"></i></div>`;
}

function pager(page, hasMore, action) {
  return `<div class="pager">
    <button type="button" class="btn small" data-act="${action}" data-page="${page - 1}" ${page <= 0 ? 'disabled' : ''}>${esc(t('previous'))}</button>
    <span class="mono muted">${page + 1}</span>
    <button type="button" class="btn small" data-act="${action}" data-page="${page + 1}" ${hasMore ? '' : 'disabled'}>${esc(t('next'))}</button>
  </div>`;
}

const resultBadge = (result) => {
  const kind = result === 'completed' ? 'good' : result === 'declined' ? '' : 'bad';
  return `<span class="badge ${kind}">${esc(t(`r_${result}`))}</span>`;
};

function historyTable(rows, withPlayer) {
  if (!rows.length) return `<div class="empty">${esc(t('noHistory'))}</div>`;
  return `<div class="table-wrap"><table>
    <thead><tr>${withPlayer ? `<th>${esc(t('player'))}</th>` : ''}<th>${esc(t('class'))}</th><th>${esc(t('vehicle'))}</th><th>${esc(t('result'))}</th><th>${esc(t('duration'))}</th><th>${esc(t('money'))}</th><th>${esc(state.dash.cryptoName)}</th><th>${esc(t('xp'))}</th><th>${esc(t('date'))}</th></tr></thead>
    <tbody>${rows.map((row) => `<tr>
      ${withPlayer ? `<td>${esc(row.player_name)}</td>` : ''}
      <td class="mono">${esc(row.class)}</td><td>${esc(row.label)}</td><td>${resultBadge(row.result)}</td><td class="mono">${clock(row.duration)}</td>
      <td>$${num(row.reward_money)}</td><td>${num(row.reward_crypto)}</td><td>${num(row.reward_xp)}</td><td class="muted">${formatDate(row.created_at)}</td>
    </tr>`).join('')}</tbody>
  </table></div>`;
}

const filterOptions = (selected) => ['completed', 'failed', 'expired', 'abandoned', 'declined'].map((r) => `<option value="${r}" ${selected === r ? 'selected' : ''}>${esc(t(`r_${r}`))}</option>`).join('');
const classOptions = (selected) => state.dash.classes.map((c) => `<option value="${esc(c.name)}" ${selected === c.name ? 'selected' : ''}>${esc(c.label)}</option>`).join('');

// Pantallas

const VIEWS = {
  async home() {
    const { profile, active, offers } = state.dash;
    return `<div class="grid grid-4 section">
      ${statTile(t('level'), num(profile.level))}
      ${statTile(t('currentClass'), esc(profile.currentClass))}
      ${statTile(t('completed'), num(profile.completed))}
      ${statTile(state.dash.cryptoName, num(profile.crypto))}
    </div>
    <div class="card section">${levelBar(profile)}</div>
    <div class="section"><h2 class="section-title">${esc(t('activeContract'))}</h2>${activeCard(active)}</div>
    <div class="section"><h2 class="section-title">${esc(t('queue'))}</h2>${queueCard()}</div>
    <div class="section"><h2 class="section-title">${esc(t('offers'))} (${offers.length})</h2>
      ${offers.length ? `<div class="grid grid-2">${offers.slice(0, 2).map(offerCard).join('')}</div>` : `<div class="empty">${esc(t('noOffers'))}</div>`}
    </div>`;
  },

  async contracts() {
    const { active, offers, classes, cryptoName } = state.dash;
    const purchasable = classes.filter((c) => c.price);
    return `<div class="section"><h2 class="section-title">${esc(t('activeContract'))}</h2>${activeCard(active)}</div>
    <div class="section"><h2 class="section-title">${esc(t('queue'))}</h2>${queueCard()}</div>
    <div class="section"><h2 class="section-title">${esc(t('offers'))} (${offers.length})</h2>
      ${offers.length ? `<div class="grid grid-2">${offers.map(offerCard).join('')}</div>` : `<div class="empty">${esc(t('noOffers'))}</div>`}
    </div>
    ${purchasable.length ? `<div class="section"><h2 class="section-title">${esc(t('buyContracts'))}</h2><div class="grid grid-3">
      ${purchasable.map((c) => `<div class="card row between">
        <div class="row" style="min-width:0"><span class="class-tag ${c.unlocked ? '' : 'off'}">${esc(c.name)}</span><div><strong>${esc(c.tier)}</strong><div class="accent mono">${num(c.price)} ${esc(cryptoName)}</div></div></div>
        <button type="button" class="btn small" data-act="buyContract" data-class="${esc(c.name)}" ${c.unlocked ? '' : 'disabled'}>${esc(t(c.unlocked ? 'buy' : 'locked'))}</button>
      </div>`).join('')}
    </div></div>` : ''}`;
  },

  async progress() {
    const { profile, classes, cryptoName } = state.dash;
    return `<div class="card section">${levelBar(profile)}<p class="muted" style="margin:10px 0 0">${esc(t('experience'))}: <span class="mono">${num(profile.xp)}</span></p></div>
    <div class="grid">
      ${classes.map((c) => `<div class="card row between wrap">
        <div class="row" style="min-width:0"><span class="class-tag ${c.unlocked ? '' : 'off'}">${esc(c.name)}</span>
          <div style="min-width:0"><strong>${esc(c.label)}</strong> <span class="badge">${esc(c.tier)}</span>
            <div class="tags" style="margin-top:4px">
              ${c.hack ? `<span class="badge accent">${esc(t('hack'))}</span>` : ''}${c.tracker ? `<span class="badge bad">${esc(t('tracker'))}</span>` : ''}${c.guards ? `<span class="badge warn">${esc(t('guards'))}</span>` : ''}
              ${c.minPolice ? `<span class="badge">${esc(t('minPolice'))}: ${num(c.minPolice)}</span>` : ''}
            </div>
          </div>
        </div>
        <div class="muted" style="text-align:right">
          <div>$${num(c.money[0])}–${num(c.money[1])} · ${num(c.crypto[0])}–${num(c.crypto[1])} ${esc(cryptoName)} · ${num(c.xp[0])}–${num(c.xp[1])} ${esc(t('xp'))}</div>
          <div class="mono ${c.unlocked ? 'good' : ''}">${c.unlocked ? '✓' : `${esc(t('unlockAt'))} ${num(c.unlockXp)} ${esc(t('xp'))}`}</div>
        </div>
      </div>`).join('')}
    </div>`;
  },

  async profile() {
    const { profile, cryptoName } = state.dash;
    const result = await api('getTransactions');
    const transactions = result.transactions || [];
    return `<div class="grid grid-2 section">
      <div class="card">
        <div class="row" style="margin-bottom:14px">
          <img class="avatar big" src="${esc(profile.avatar || 'assets/default-avatar.svg')}" alt="" onerror="this.src='assets/default-avatar.svg'" />
          <div style="min-width:0"><strong style="font-size:17px">${esc(profile.name)}</strong><div class="muted">${esc(t('level'))} ${num(profile.level)} · ${esc(t('class'))} ${esc(profile.currentClass)}</div></div>
        </div>
        <h2 class="section-title">${esc(t('editProfile'))}</h2>
        <div class="grid">
          <label class="field"><span>${esc(t('displayName'))}</span><input id="p-name" type="text" maxlength="24" value="${esc(profile.name)}" /></label>
          <label class="field"><span>${esc(t('avatarUrl'))}</span><input id="p-avatar" type="text" maxlength="250" value="${esc(profile.avatar || '')}" /></label>
          <div><button type="button" class="btn primary" data-act="saveProfile">${esc(t('save'))}</button></div>
        </div>
      </div>
      <div class="grid grid-2" style="align-content:start">
        ${statTile(t('experience'), num(profile.xp))}
        ${statTile(t('completed'), num(profile.completed))}
        ${statTile(t('failed'), num(profile.failed))}
        ${statTile(t('moneyEarned'), `$${num(profile.moneyEarned)}`)}
        ${statTile(t('cryptoEarned'), num(profile.cryptoEarned))}
        ${statTile(cryptoName, num(profile.crypto))}
      </div>
    </div>
    <div class="section"><h2 class="section-title">${esc(t('transactions'))}</h2>
      ${transactions.length ? `<div class="table-wrap"><table><thead><tr><th>${esc(t('concept'))}</th><th>${esc(t('amount'))}</th><th>${esc(t('date'))}</th></tr></thead><tbody>
        ${transactions.map((row) => `<tr><td>${esc(row.reason)}</td><td class="mono ${row.amount > 0 ? 'good' : 'bad'}">${row.amount > 0 ? '+' : ''}${num(row.amount)}</td><td class="muted">${formatDate(row.created_at)}</td></tr>`).join('')}
      </tbody></table></div>` : `<div class="empty">${esc(t('noTransactions'))}</div>`}
    </div>`;
  },

  async store() {
    const result = await api('getStore');
    const items = result.items || [];
    const pending = result.pending || [];
    return `${pending.length ? `<div class="section"><h2 class="section-title">${esc(t('pending'))} — ${esc(result.pickupPoint || '')}</h2><div class="grid">
      ${pending.map((row) => `<div class="card row between"><span>${esc(row.label)} × ${num(row.quantity)}</span><button type="button" class="btn small primary" data-act="collect" data-id="${esc(row.id)}">${esc(t('collect'))}</button></div>`).join('')}
    </div></div>` : ''}
    ${items.length ? `<div class="grid grid-3">
      ${items.map((item) => {
        const soldOut = item.stock !== undefined && item.stock !== null && item.stock <= 0;
        const limited = item.maxPerPlayer && item.bought >= item.maxPerPlayer;
        return `<article class="card contract">
          <div class="row between"><h3>${esc(item.label)}</h3><span class="accent mono">${num(item.price)}</span></div>
          <p class="muted" style="margin:0;min-height:36px">${esc(item.description)}</p>
          <div class="tags">
            <span class="badge">${esc(t('stock'))}: ${item.stock === undefined || item.stock === null ? esc(t('unlimited')) : num(item.stock)}</span>
            ${item.maxPerPlayer ? `<span class="badge">${esc(t('limit'))}: ${num(item.bought)}/${num(item.maxPerPlayer)}</span>` : ''}
            ${item.pickup ? `<span class="badge warn">${esc(t('pickup'))}</span>` : ''}
            ${item.locked ? `<span class="badge bad">${esc(t('requires'))} ${esc(item.requiredClass)}</span>` : ''}
          </div>
          <button type="button" class="btn primary" data-act="buyItem" data-id="${esc(item.id)}" ${item.locked || soldOut || limited || (result.crypto || 0) < item.price ? 'disabled' : ''}>${esc(t('buy'))}</button>
        </article>`;
      }).join('')}
    </div>` : `<div class="empty">${esc(t('noItems'))}</div>`}`;
  },

  async history() {
    const filter = state.history;
    const result = await api('getHistory', { page: filter.page, result: filter.result || undefined, class: filter.class || undefined });
    const rows = result.history || [];
    return `<div class="row wrap section">
      <select id="h-result" style="max-width:220px"><option value="">${esc(t('allResults'))}</option>${filterOptions(filter.result)}</select>
      <select id="h-class" style="max-width:180px"><option value="">${esc(t('allClasses'))}</option>${classOptions(filter.class)}</select>
    </div>
    ${historyTable(rows, false)}
    ${pager(filter.page, rows.length === (result.pageSize || 25), 'historyPage')}`;
  },

  async leaderboard() {
    const result = await api('getLeaderboard');
    const rows = result.leaderboard || [];
    if (!rows.length) return `<div class="empty">${esc(t('noLeaderboard'))}</div>`;
    return `<div class="table-wrap"><table>
      <thead><tr><th>${esc(t('position'))}</th><th>${esc(t('player'))}</th><th>${esc(t('class'))}</th><th>${esc(t('completed'))}</th><th>${esc(t('experience'))}</th><th>${esc(t('lastActivity'))}</th></tr></thead>
      <tbody>${rows.map((row) => `<tr class="${row.me ? 'me' : ''}">
        <td class="mono accent">#${num(row.position)}</td>
        <td><div class="row"><img class="avatar" src="${esc(row.avatar || 'assets/default-avatar.svg')}" alt="" onerror="this.src='assets/default-avatar.svg'" /><span>${esc(row.name)}</span></div></td>
        <td class="mono">${esc(row.class)}</td><td>${num(row.completed)}</td><td>${num(row.xp)}</td><td class="muted">${formatDate(row.lastActivity)}</td>
      </tr>`).join('')}</tbody>
    </table></div>`;
  },

  async admin() {
    const admin = state.admin;
    const tabs = ['summary', 'players', 'history', 'config', 'logs'];
    const body = await ADMIN_VIEWS[admin.tab]();
    return `<div class="tabs">${tabs.map((tab) => `<button type="button" class="btn small ${admin.tab === tab ? 'primary' : ''}" data-act="adminTab" data-tab="${tab}">${esc(t(`a_${tab}`))}</button>`).join('')}</div>${body}`;
  },
};

const ADMIN_VIEWS = {
  async summary() {
    const result = await api('adminOverview');
    if (!result.ok) return '';
    const stats = result.stats || {};
    const active = result.active || [];
    return `<div class="grid grid-3 section">
      ${statTile(t('profiles'), num(stats.profiles))}
      ${statTile(t('completed'), num(stats.completed))}
      ${statTile(t('lost'), num(stats.lost))}
      ${statTile(t('moneyPaid'), `$${num(stats.money)}`)}
      ${statTile(t('cryptoCirculating'), num(stats.crypto))}
      ${statTile(t('policeOnDuty'), num(result.police))}
    </div>
    <div class="section"><h2 class="section-title">${esc(t('activeContracts'))}</h2>
      ${active.length ? `<div class="table-wrap"><table><thead><tr><th>${esc(t('identifier'))}</th><th>${esc(t('class'))}</th><th>${esc(t('vehicle'))}</th><th>${esc(t('status'))}</th><th>${esc(t('expires'))}</th><th></th></tr></thead><tbody>
        ${active.map((c) => `<tr><td>${esc(c.identifier)} <span class="badge ${c.online ? 'good' : ''}">${esc(t(c.online ? 'online' : 'offline'))}</span></td><td class="mono">${esc(c.class)}</td><td>${esc(c.model)}</td><td class="mono">${esc(c.status)}</td><td class="mono">${clock(c.remaining)}</td><td><button type="button" class="btn danger small" data-act="adminCancel" data-uid="${esc(c.uid)}">${esc(t('cancel'))}</button></td></tr>`).join('')}
      </tbody></table></div>` : `<div class="empty">${esc(t('noActiveAdmin'))}</div>`}
    </div>
    <button type="button" class="btn" data-act="adminResetStock">${esc(t('resetStock'))}</button>`;
  },

  async players() {
    const admin = state.admin;
    if (admin.selected) return ADMIN_VIEWS.player();

    const result = await api('adminSearch', { term: admin.term, page: admin.page });
    const rows = result.profiles || [];
    return `<div class="row section"><input id="a-term" type="text" placeholder="${esc(t('search'))}" value="${esc(admin.term)}" /><button type="button" class="btn primary" data-act="adminFind">${esc(t('find'))}</button></div>
    ${rows.length ? `<div class="table-wrap"><table><thead><tr><th>${esc(t('player'))}</th><th>${esc(t('identifier'))}</th><th>${esc(t('xp'))}</th><th>${esc(state.dash.cryptoName)}</th><th>${esc(t('completed'))}</th><th>${esc(t('lastActivity'))}</th></tr></thead><tbody>
      ${rows.map((row) => `<tr class="clickable" data-act="adminSelect" data-id="${esc(row.identifier)}"><td>${esc(row.display_name)}</td><td class="mono muted">${esc(row.identifier)}</td><td>${num(row.xp)}</td><td>${num(row.crypto)}</td><td>${num(row.completed)}</td><td class="muted">${formatDate(row.last_activity)}</td></tr>`).join('')}
    </tbody></table></div>` : `<div class="empty">${esc(t('noPlayers'))}</div>`}
    ${pager(admin.page, rows.length === 25, 'adminPage')}`;
  },

  async player() {
    const result = await api('adminProfile', { identifier: state.admin.selected });
    if (!result.ok) { state.admin.selected = null; return ''; }
    const profile = result.profile;
    return `<button type="button" class="btn small section" data-act="adminBack">${esc(t('back'))}</button>
    <div class="grid grid-4 section">
      ${statTile(t('player'), esc(profile.name))}
      ${statTile(t('experience'), `${num(profile.xp)} <small class="muted">${esc(t('level'))} ${num(profile.level)}</small>`)}
      ${statTile(state.dash.cryptoName, num(profile.crypto))}
      ${statTile(t('completed'), `${num(profile.completed)} <small class="bad">/ ${num(profile.failed)}</small>`)}
    </div>
    <div class="grid grid-3 section">
      <div class="card"><h2 class="section-title">${esc(t('assign'))}</h2><div class="row"><select id="a-class">${classOptions('')}</select><button type="button" class="btn primary" data-act="adminAssign">${esc(t('apply'))}</button></div></div>
      <div class="card"><h2 class="section-title">${esc(t('adjustXp'))}</h2><div class="row"><input id="a-xp" type="number" placeholder="${esc(t('delta'))}" /><button type="button" class="btn" data-act="adminXp">${esc(t('apply'))}</button></div></div>
      <div class="card"><h2 class="section-title">${esc(t('adjustCrypto'))}</h2><div class="row"><input id="a-crypto" type="number" placeholder="${esc(t('delta'))}" /><button type="button" class="btn" data-act="adminCrypto">${esc(t('apply'))}</button></div></div>
    </div>
    <div class="section"><h2 class="section-title">${esc(t('history'))}</h2>${historyTable(result.history || [], false)}</div>`;
  },

  async history() {
    const admin = state.admin;
    const result = await api('adminHistory', { page: admin.histPage, result: admin.histResult || undefined, class: admin.histClass || undefined });
    const rows = result.history || [];
    return `<div class="row wrap section">
      <select id="ah-result" style="max-width:220px"><option value="">${esc(t('allResults'))}</option>${filterOptions(admin.histResult)}</select>
      <select id="ah-class" style="max-width:180px"><option value="">${esc(t('allClasses'))}</option>${classOptions(admin.histClass)}</select>
    </div>
    ${historyTable(rows, true)}
    ${pager(admin.histPage, rows.length === (result.pageSize || 25), 'adminHistPage')}`;
  },

  async config() {
    const result = await api('adminOverview');
    if (!result.ok) return '';
    return `<div class="card row between section">
      <label class="field" style="flex:1"><span>${esc(t('multiplier'))}</span><input id="a-mult" type="number" step="0.1" min="0.1" max="10" value="${esc(result.multiplier)}" /></label>
      <button type="button" class="btn primary" data-act="adminMultiplier" style="align-self:flex-end">${esc(t('save'))}</button>
    </div>
    <div class="grid">
      ${result.classes.map((c) => `<div class="card">
        <div class="row between" style="margin-bottom:8px"><strong>${esc(c.label)}</strong><button type="button" class="btn small ${c.disabled ? 'danger' : ''}" data-act="adminToggle" data-kind="class" data-name="${esc(c.name)}" data-disabled="${c.disabled ? '0' : '1'}">${esc(t(c.disabled ? 'disabled' : 'enabled'))}</button></div>
        <div class="row wrap">${c.models.map((m) => `<button type="button" class="btn small ${m.disabled ? 'danger' : ''}" data-act="adminToggle" data-kind="model" data-name="${esc(m.model)}" data-disabled="${m.disabled ? '0' : '1'}">${esc(m.label)}</button>`).join('')}</div>
      </div>`).join('')}
    </div>`;
  },

  async logs() {
    const admin = state.admin;
    const result = await api('adminLogs', { category: admin.category || undefined, page: admin.logPage || 0 });
    const rows = result.logs || [];
    const categories = ['admin', 'security', 'police', 'tracker', 'contract', 'store', 'economy'];
    return `<div class="row section"><select id="a-category" style="max-width:240px"><option value="">${esc(t('allCategories'))}</option>${categories.map((c) => `<option value="${c}" ${admin.category === c ? 'selected' : ''}>${c}</option>`).join('')}</select></div>
    ${rows.length ? `<div class="table-wrap"><table><thead><tr><th>${esc(t('date'))}</th><th></th><th>${esc(t('action'))}</th><th>${esc(t('actor'))}</th><th>${esc(t('target'))}</th><th>${esc(t('details'))}</th></tr></thead><tbody>
      ${rows.map((row) => `<tr><td class="muted">${formatDate(row.created_at)}</td><td><span class="badge">${esc(row.category)}</span></td><td class="mono">${esc(row.action)}</td><td class="mono muted">${esc(row.actor || '—')}</td><td class="mono muted">${esc(row.target || '—')}</td><td class="mono muted" title="${esc(row.details || '')}">${esc(row.details || '')}</td></tr>`).join('')}
    </tbody></table></div>` : `<div class="empty">${esc(t('noHistory'))}</div>`}
    ${pager(admin.logPage || 0, rows.length === 50, 'adminLogPage')}`;
  },
};

// Acciones

async function refreshAll() {
  await loadDash();
  await render();
}

const inputValue = (selector) => { const element = $(selector); return element ? element.value : ''; };

const ACTIONS = {
  join: async () => { await api('joinQueue'); await refreshAll(); },
  leave: async () => { await api('leaveQueue'); await refreshAll(); },
  accept: async (d) => { await api('acceptContract', { uid: d.uid }); await refreshAll(); },
  decline: async (d) => { await api('declineContract', { uid: d.uid }); await refreshAll(); },
  abandon: async () => { await api('abandonContract'); await refreshAll(); },
  buyContract: async (d) => { await api('buyContract', { class: d.class }); await refreshAll(); },
  buyItem: async (d) => { await api('buyItem', { id: d.id, quantity: 1 }); await refreshAll(); },
  collect: async (d) => { await api('collectPurchase', { id: Number(d.id) }); await refreshAll(); },
  saveProfile: async () => { await api('updateProfile', { name: inputValue('#p-name'), avatar: inputValue('#p-avatar') }); await refreshAll(); },
  historyPage: async (d) => { state.history.page = Number(d.page); await render(); },
  adminTab: async (d) => { state.admin.tab = d.tab; state.admin.selected = null; await render(); },
  adminFind: async () => { state.admin.term = inputValue('#a-term'); state.admin.page = 0; await render(); },
  adminPage: async (d) => { state.admin.page = Number(d.page); await render(); },
  adminHistPage: async (d) => { state.admin.histPage = Number(d.page); await render(); },
  adminLogPage: async (d) => { state.admin.logPage = Number(d.page); await render(); },
  adminSelect: async (d) => { state.admin.selected = d.id; await render(); },
  adminBack: async () => { state.admin.selected = null; await render(); },
  adminAssign: async () => { await api('adminAssign', { identifier: state.admin.selected, class: inputValue('#a-class') }); await render(); },
  adminXp: async () => { await api('adminSetXp', { identifier: state.admin.selected, delta: Number(inputValue('#a-xp')) }); await render(); },
  adminCrypto: async () => { await api('adminSetCrypto', { identifier: state.admin.selected, delta: Number(inputValue('#a-crypto')) }); await render(); },
  adminCancel: async (d) => { await api('adminCancelContract', { uid: d.uid }); await render(); },
  adminResetStock: async () => { await api('adminResetStock'); },
  adminMultiplier: async () => { await api('adminConfig', { kind: 'multiplier', value: Number(inputValue('#a-mult')) }); await render(); },
  adminToggle: async (d) => { await api('adminConfig', { kind: d.kind, name: d.name, disabled: d.disabled === '1' }); await render(); },
};

let acting = false;

document.addEventListener('click', async (event) => {
  const tabButton = event.target.closest('[data-tab].nav-item');
  if (tabButton) { await go(tabButton.dataset.tab); return; }

  const element = event.target.closest('[data-act]');
  if (!element || element.disabled || acting) return;
  const action = ACTIONS[element.dataset.act];
  if (!action) return;

  acting = true;
  try { await action(element.dataset); } finally { acting = false; }
});

document.addEventListener('change', async (event) => {
  const id = event.target.id;
  if (id === 'h-result') { state.history.result = event.target.value; state.history.page = 0; await render(); }
  if (id === 'h-class') { state.history.class = event.target.value; state.history.page = 0; await render(); }
  if (id === 'ah-result') { state.admin.histResult = event.target.value; state.admin.histPage = 0; await render(); }
  if (id === 'ah-class') { state.admin.histClass = event.target.value; state.admin.histPage = 0; await render(); }
  if (id === 'a-category') { state.admin.category = event.target.value; state.admin.logPage = 0; await render(); }
});

// Abrir y cerrar

function closeTerminal() {
  $('#terminal').classList.add('hidden');
  renderHud();
  if (inGame) post('close').catch(() => {});
}

$('#close').addEventListener('click', closeTerminal);

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return;
  if (hack.active) { hackFinish([], true); return; }
  if (!$('#terminal').classList.contains('hidden')) closeTerminal();
});

// Indicador del contrato

const hud = { contract: null, key: '', endsAt: 0, trackerAt: 0, timer: null };

function renderHud() {
  const element = $('#hud');
  const contract = hud.contract;
  if (!contract || !$('#terminal').classList.contains('hidden')) { element.classList.add('hidden'); return; }

  const remaining = Math.max(0, (hud.endsAt - Date.now()) / 1000);
  let tracker = '';
  if (contract.tracker) {
    const wait = Math.max(0, (hud.trackerAt - Date.now()) / 1000);
    tracker = `<p class="tracker">${esc(t('trackerActive'))}</p><p>${wait > 0 ? esc(t('trackerWait', clock(wait))) : esc(t('trackerKey', hud.key))}</p>`;
  }
  const place = contract.status === 'stolen' && contract.dropoff ? contract.dropoff.label : contract.zone.label;
  element.innerHTML = `<div class="row between"><h4>${esc(contract.class)} · ${esc(contract.model)}</h4><span class="mono muted">${clock(remaining)}</span></div>
    <p class="mono">${esc(contract.plate)}</p><p>${esc(t(`s_${contract.status}`))}: ${esc(place)}</p>${tracker}`;
  element.classList.remove('hidden');
}

function setHud(contract, key) {
  hud.contract = contract;
  hud.key = key || hud.key;
  clearInterval(hud.timer);
  if (contract) {
    hud.endsAt = Date.now() + (contract.remaining || 0) * 1000;
    hud.trackerAt = Date.now() + (contract.trackerDisableAt || 0) * 1000;
    hud.timer = setInterval(renderHud, 1000);
  }
  renderHud();
}

// Hackeo

const hack = { active: false, data: null, step: 0, answer: [], timer: null, startedAt: 0, sending: false };

function renderHack() {
  const data = hack.data;
  const sequence = data.sequence.map((code, index) => {
    const kind = index < hack.step ? 'ok' : index === hack.step ? 'next' : '';
    return `<span class="${kind}">${esc(code)}</span>`;
  }).join('');
  const grid = data.grid.map((code, index) => {
    const used = hack.answer.includes(code);
    return `<button type="button" class="hack-cell" data-code="${esc(code)}" style="animation-delay:${index * 12}ms" ${used ? 'disabled' : ''}>${esc(code)}</button>`;
  }).join('');

  $('#hack').innerHTML = `<div class="hack-box" id="hack-box">
    <div class="row between">
      <div><p class="hack-title">${esc(t(data.kind === 'lock' ? 'hackLock' : 'hackTracker'))}</p><span class="muted">${esc(t('hackHelp'))}</span></div>
      <span class="mono accent">${esc(t('attemptsLeft'))}: ${esc(data.attempts)}</span>
    </div>
    <div class="hack-timer"><i id="hack-bar"></i></div>
    <div class="hack-sequence">${sequence}</div>
    <div class="hack-grid" style="grid-template-columns:repeat(${Number(data.size)},1fr)">${grid}</div>
  </div>`;
}

function updateSequence() {
  document.querySelectorAll('.hack-sequence span').forEach((element, index) => {
    element.className = index < hack.step ? 'ok' : index === hack.step ? 'next' : '';
  });
}

function hackStart(data) {
  hack.active = true;
  hack.sending = false;
  hack.data = data;
  hack.step = 0;
  hack.answer = [];
  hack.startedAt = Date.now();
  renderHack();
  $('#hack').classList.remove('hidden');

  clearInterval(hack.timer);
  hack.timer = setInterval(() => {
    const left = data.time * 1000 - (Date.now() - hack.startedAt);
    const bar = $('#hack-bar');
    if (bar) {
      bar.style.width = `${Math.max(0, (left / (data.time * 1000)) * 100)}%`;
      bar.style.background = left < 5000 ? 'var(--bad)' : '';
    }
    if (left <= 0) hackFinish(hack.answer, true);
  }, 100);
}

function hackClose() {
  hack.active = false;
  clearInterval(hack.timer);
  $('#hack').classList.add('hidden');
  $('#hack').innerHTML = '';
  if (inGame) post('hackClose').catch(() => {});
}

// La respuesta la corrige el servidor: aquí solo se envía lo pulsado
async function hackFinish(answer, abort) {
  if (!hack.active || hack.sending) return;
  hack.sending = true;
  clearInterval(hack.timer);

  let result = { ok: false, success: false };
  try {
    const body = { token: hack.data.token, answer: answer.length ? answer : ['--'] };
    result = inGame ? await post('hackSubmit', body) : { ok: true, success: !abort && answer.join() === hack.data.sequence.join() };
  } catch (error) {
    result = { ok: false, success: false };
  }

  const box = $('#hack-box');
  if (box) {
    box.classList.add(result.success ? 'done' : 'shake');
    const title = box.querySelector('.hack-title');
    if (title) title.textContent = t(result.success ? 'hackOk' : 'hackFail');
  }
  setTimeout(hackClose, 900);
}

$('#hack').addEventListener('click', (event) => {
  const cell = event.target.closest('.hack-cell');
  if (!cell || cell.disabled || !hack.active || hack.sending) return;

  const code = cell.dataset.code;
  hack.answer.push(code);
  cell.disabled = true;

  if (code !== hack.data.sequence[hack.step]) {
    hackFinish(hack.answer, true);
    return;
  }

  hack.step += 1;
  updateSequence();
  if (hack.step >= hack.data.sequence.length) hackFinish(hack.answer, false);
});

// Mensajes del juego

window.addEventListener('message', async (event) => {
  const message = event.data || {};
  if (message.locale) locale = message.locale;

  switch (message.action) {
    case 'open':
      $('#terminal').classList.remove('hidden');
      renderHud();
      state.dash = null;
      state.tab = message.tab || 'home';
      await render();
      break;
    case 'close':
      $('#terminal').classList.add('hidden');
      renderHud();
      break;
    case 'refresh':
      if (!$('#terminal').classList.contains('hidden') && !acting) await refreshAll();
      break;
    case 'hud':
      setHud(message.contract, message.trackerKey);
      break;
    case 'hack':
      hackStart(message.hack);
      break;
    default:
      break;
  }
});

// En el navegador: datos de ejemplo para poder ver la interfaz sin el juego

const MOCK = {
  dash: {
    ok: true, locale: 'es', cryptoName: 'JJC', isAdmin: true, queued: true, levels: [0, 100, 250],
    profile: { name: 'Ghost_a1b2c3', avatar: null, xp: 860, crypto: 142, completed: 23, failed: 4, moneyEarned: 84500, cryptoEarned: 310, level: 5, levelXp: 800, nextLevelXp: 1200, currentClass: 'B', services: {} },
    active: { uid: 'ABCDEFGH23456789', status: 'located', class: 'B', model: 'Pfister Comet', plate: 'BTX4K7P2', money: 5600, crypto: 18, xp: 72, remaining: 1540, zone: { label: 'Mirror Park' }, tier: 'Intermedio' },
    offers: [
      { uid: 'OFFER00000000001', class: 'B', tier: 'Intermedio', model: 'Grotti Carbonizzare', zone: 'Legion Square', dropoff: 'Desguace de La Mesa', money: 6200, crypto: 19, xp: 80, remaining: 640, hack: true, locked: true },
      { uid: 'OFFER00000000002', class: 'C', tier: 'Básico', model: 'Karin Sultan', zone: 'Davis', dropoff: 'Terminal del puerto', money: 2400, crypto: 7, xp: 42, remaining: 410 },
    ],
    classes: [
      { name: 'D', label: 'Clase D', tier: 'Básico', unlockXp: 0, unlocked: true, minPolice: 0, money: [800, 1500], crypto: [2, 5], xp: [20, 30] },
      { name: 'C', label: 'Clase C', tier: 'Básico', unlockXp: 250, unlocked: true, minPolice: 0, money: [1800, 3200], crypto: [5, 10], xp: [35, 50] },
      { name: 'B', label: 'Clase B', tier: 'Intermedio', unlockXp: 800, unlocked: true, price: 40, hack: true, minPolice: 1, money: [4000, 7000], crypto: [12, 22], xp: [60, 85] },
      { name: 'A', label: 'Clase A', tier: 'Avanzado', unlockXp: 2300, unlocked: false, price: 90, hack: true, tracker: true, guards: true, minPolice: 2, money: [9000, 15000], crypto: [30, 50], xp: [100, 140] },
      { name: 'S', label: 'Clase S', tier: 'Avanzado', unlockXp: 5500, unlocked: false, price: 200, hack: true, tracker: true, guards: true, minPolice: 3, money: [20000, 35000], crypto: [70, 120], xp: [180, 260] },
    ],
  },
  history: [
    { player_name: 'Ana Ruiz', class: 'C', label: 'Bravado Buffalo', result: 'completed', duration: 412, reward_money: 2800, reward_crypto: 8, reward_xp: 44, created_at: '2026-11-01T18:21:00' },
    { player_name: 'Ana Ruiz', class: 'B', label: 'Pfister Comet', result: 'failed', duration: 655, reward_money: 0, reward_crypto: 0, reward_xp: -10, created_at: '2026-11-01T17:02:00' },
    { player_name: 'Ana Ruiz', class: 'D', label: 'Dinka Blista', result: 'expired', duration: 1500, reward_money: 0, reward_crypto: 0, reward_xp: -10, created_at: '2026-10-31T22:40:00' },
  ],
};

async function mockApi(name) {
  switch (name) {
    case 'getDashboard': return MOCK.dash;
    case 'getTransactions': return { ok: true, transactions: [{ amount: 18, reason: 'Contrato Clase B', created_at: '2026-11-01T18:21:00' }, { amount: -35, reason: 'Tienda: Dispositivo de hackeo', created_at: '2026-11-01T15:02:00' }] };
    case 'getHistory': return { ok: true, history: MOCK.history, pageSize: 25 };
    case 'adminHistory': return { ok: true, history: MOCK.history, pageSize: 25 };
    case 'getLeaderboard': return { ok: true, leaderboard: [{ position: 1, name: 'NightCrawler', completed: 88, xp: 7400, class: 'S', lastActivity: '2026-11-01T19:00:00' }, { position: 2, name: 'Ghost_a1b2c3', completed: 23, xp: 860, class: 'B', lastActivity: '2026-11-01T18:21:00', me: true }] };
    case 'getStore': return { ok: true, crypto: 142, pickupPoint: 'Recoger pedido', pending: [{ id: 1, label: 'Dispositivo de hackeo', quantity: 1 }], items: [
      { id: 'lockpick', label: 'Ganzúa', description: 'Para cerraduras sencillas.', price: 3, stock: 21, maxPerPlayer: 5, bought: 1 },
      { id: 'electronickit', label: 'Kit electrónico', description: 'Herramientas para electrónica de vehículos.', price: 15, stock: 0, maxPerPlayer: 2, bought: 0 },
      { id: 'hackingdevice', label: 'Dispositivo de hackeo', description: 'Desactiva un rastreador sin minijuego.', price: 35, stock: 4, maxPerPlayer: 1, bought: 0, pickup: true, locked: true, requiredClass: 'A' },
      { id: 'priority', label: 'Prioridad de cola', description: 'Tus 3 próximas ofertas llegan antes.', price: 20, maxPerPlayer: 2, bought: 0 },
    ] };
    case 'adminOverview': return { ok: true, police: 3, multiplier: 1, stats: { profiles: 41, completed: 212, lost: 57, money: 942000, crypto: 3120 }, active: [{ uid: 'ABCDEFGH23456789', identifier: 'char:12ab34', class: 'B', model: 'Pfister Comet', status: 'located', online: true, remaining: 1540 }], classes: MOCK.dash.classes.map((c) => ({ name: c.name, label: c.label, disabled: c.name === 'S', models: [{ model: 'x', label: 'Modelo', disabled: false }] })) };
    case 'adminSearch': return { ok: true, profiles: [{ identifier: 'char:12ab34', display_name: 'Ghost_a1b2c3', xp: 860, crypto: 142, completed: 23, last_activity: '2026-11-01T18:21:00' }] };
    case 'adminProfile': return { ok: true, profile: { ...MOCK.dash.profile, identifier: 'char:12ab34' }, history: MOCK.history };
    case 'adminLogs': return { ok: true, logs: [{ category: 'admin', actor: 'char:admin', target: 'char:12ab34', action: 'crypto', details: '{"delta":50}', created_at: '2026-11-01T18:00:00' }, { category: 'security', actor: 'char:99', action: 'deliver_too_fast', details: '{"elapsed":3}', created_at: '2026-11-01T17:30:00' }] };
    default: return { ok: true };
  }
}

if (!inGame) {
  document.body.style.background = '#2c3440';
  $('#terminal').classList.remove('hidden');
  render();
  setHud(MOCK.dash.active, 'F7');
  window.__showHack = () => hackStart({ token: 'demo', kind: 'lock', size: 5, time: 22, attempts: 3, sequence: ['3F', 'A1', '7C', 'E0', '12'], grid: ['3F', 'B2', '91', 'A1', '4D', '7C', '08', 'E0', '5A', '12', 'C7', '66', 'D3', '2E', 'F4', '81', '19', 'BD', '70', '4A', '95', '6B', 'E3', '27', 'AC'] });
}
