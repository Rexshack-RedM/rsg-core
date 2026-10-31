(() => {
const root = document.getElementById('notify-root');
const stacks = {};
const active = new Map(); // id -> { el, timeout }
const POSITIONS = ['top-right', 'top-left', 'top', 'bottom-right', 'bottom-left', 'bottom', 'center-right', 'center-left'];
const ICONS = {
    success: 'fa-solid fa-check',
    error: 'fa-solid fa-xmark',
    warning: 'fa-solid fa-triangle-exclamation',
    inform: 'fa-solid fa-info',
};
const LABELS = { success: 'Success', error: 'Error', warning: 'Warning', inform: 'Notice' };
let counter = 0;

function getStack(position) {
    if (!POSITIONS.includes(position)) position = 'top-right';
    if (!stacks[position]) {
        const el = document.createElement('div');
        el.className = `stack ${position}`;
        root.appendChild(el);
        stacks[position] = el;
    }
    return stacks[position];
}

function removeToast(id) {
    const entry = active.get(id);
    if (!entry) return;
    active.delete(id);
    clearTimeout(entry.timeout);
    entry.el.classList.remove('show');
    entry.el.classList.add('leave');
    setTimeout(() => entry.el.remove(), 260);
}

function text(tag, cls, value) {
    const el = document.createElement(tag);
    el.className = cls;
    el.textContent = value; // textContent: never render player-supplied HTML
    return el;
}

function notify(data) {
    const type = ICONS[data.type] ? data.type : 'inform';
    const duration = Math.max(500, Number(data.duration) || 5000);
    const id = data.id != null ? String(data.id) : `n${++counter}`;

    // same id replaces the existing toast instead of stacking
    if (active.has(id)) removeToast(id);

    const stack = getStack(data.position);
    const el = document.createElement('div');
    el.className = `toast ${type}`;

    const badge = document.createElement('div');
    badge.className = 'badge';
    const icon = document.createElement('i');
    icon.className = (typeof data.icon === 'string' && /^[\w\s-]+$/.test(data.icon)) ? data.icon : ICONS[type];
    badge.appendChild(icon);

    const body = document.createElement('div');
    body.className = 'body';
    if (data.title) {
        body.appendChild(text('div', 'label', LABELS[type]));
        body.appendChild(text('div', 'title', data.title));
    }
    if (data.description) body.appendChild(text('div', 'desc', data.description));

    const timer = document.createElement('div');
    timer.className = 'timer';
    timer.style.transition = `transform ${duration}ms linear`;

    el.append(badge, body, timer);
    stack.appendChild(el);

    // keep at most `max` visible per stack
    const max = Number(data.max) || 5;
    const items = [...stack.children].filter(c => !c.classList.contains('leave'));
    if (items.length > max) {
        items.slice(0, items.length - max).forEach(old => {
            for (const [k, v] of active) if (v.el === old) removeToast(k);
        });
    }

    requestAnimationFrame(() => requestAnimationFrame(() => {
        el.classList.add('show');
        timer.style.transform = 'scaleX(0)';
    }));

    active.set(id, { el, timeout: setTimeout(() => removeToast(id), duration) });
}

window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || msg.action !== 'notify' || !msg.data) return;
    notify(msg.data);
});

// text UI (DrawText)
const textui = document.getElementById('textui');
const TEXT_POSITIONS = ['right-center', 'left-center', 'top-center', 'bottom-center'];
window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || msg.action !== 'textui' || !msg.data) return;
    if (!msg.data.show) { textui.classList.add('hidden'); return; }
    const pos = TEXT_POSITIONS.includes(msg.data.position) ? msg.data.position : 'right-center';
    textui.className = `textui ${pos}`;
    // ox_lib-style [E] key hints are kept as plain text
    textui.textContent = String(msg.data.text);
});
})();

// progress bar / circle
(() => {
    const root = document.getElementById('progress');
    const fill = document.getElementById('progressFill');
    const ring = document.getElementById('progressRing');
    const pct = document.getElementById('progressPct');
    const ringPct = document.getElementById('progressRingPct');
    const label = document.getElementById('progressLabel');
    const ringLabel = document.getElementById('progressRingLabel');
    const hint = document.getElementById('progressHint');
    const CIRC = 276.46; // 2 * PI * 44
    let raf = null, hideTimer = null, start = 0, duration = 0;

    const setProgress = (p) => {
        const v = Math.max(0, Math.min(1, p));
        fill.style.width = (v * 100) + '%';
        ring.style.strokeDashoffset = CIRC * (1 - v);
        pct.textContent = ringPct.textContent = Math.floor(v * 100) + '%';
    };

    const tick = (t) => {
        setProgress((t - start) / duration);
        if (t - start < duration) raf = requestAnimationFrame(tick);
    };

    window.addEventListener('message', (e) => {
        const msg = e.data;
        if (!msg || msg.action !== 'progress' || !msg.data) return;
        const d = msg.data;
        cancelAnimationFrame(raf);
        clearTimeout(hideTimer);
        if (!d.show) {
            if (d.cancelled) root.classList.add('cancelled');
            root.classList.add('fade');
            hideTimer = setTimeout(() => { root.className = 'progress hidden'; }, d.cancelled ? 600 : 250);
            return;
        }
        const kind = d.kind === 'circle' ? 'circle' : 'bar';
        const pos = d.position === 'middle' ? 'middle' : 'bottom';
        root.className = `progress ${kind} ${pos}`;
        label.textContent = ringLabel.textContent = d.label ? String(d.label) : '';
        hint.textContent = d.cancelHint ? String(d.cancelHint) : '';
        duration = Math.max(1, Number(d.duration) || 1);
        setProgress(0);
        start = performance.now();
        raf = requestAnimationFrame(tick);
    });
})();
