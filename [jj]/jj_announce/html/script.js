const stack = document.getElementById('stack');
const esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

window.addEventListener('message', e => {
  if (!e.data || e.data.action !== 'show') return;
  const d = e.data.data;
  const el = document.createElement('div');
  el.className = 'ann';
  el.style.setProperty('--c', d.color);
  el.style.setProperty('--d', d.duration + 'ms');
  el.innerHTML = `<div class="t">${esc(d.title)}<small>por ${esc(d.author)}</small></div><p>${esc(d.message)}</p><div class="bar"></div>`;
  stack.appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 500); }, d.duration);
});
