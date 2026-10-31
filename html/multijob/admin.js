/* rsg-multijob — Job Admin panel */
(function () {
    'use strict';

    const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rsg-core';
    const root = document.getElementById('adminApp');

    let L = {};
    let jobs = [];
    let selected = null;   // job name being edited, or null
    let isNew = false;
    let draft = null;      // working copy
    let original = '';     // JSON snapshot for dirty check
    let filter = '';
    let busy = false;
    let tab = 'details';     // 'details' | 'employees'
    let holders = null;      // employees of the selected job (null = loading)
    let onlinePlayers = [];
    let openDd = null;       // currently open custom dropdown

    const DEFAULT_ICON = 'fa-solid fa-briefcase';

    // ---------- helpers ----------
    const t = (k, ...args) => {
        let s = L[k] || k;
        args.forEach(a => { s = s.replace('%s', a); });
        return s;
    };

    function post(endpoint, data) {
        return fetch(`https://${RES}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).then(r => r.json()).catch(() => ({ ok: false }));
    }

    function el(tag, cls, text) {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined && text !== null) e.textContent = text;
        return e;
    }

    function iconEl(cls) {
        const i = el('i');
        i.className = cls && /^[\w\s-]+$/.test(cls) ? cls : DEFAULT_ICON;
        return i;
    }

    const clone = o => JSON.parse(JSON.stringify(o));
    const isDirty = () => !!draft && JSON.stringify(draft) !== original;
    const asArray = v => Array.isArray(v) ? v : (v && typeof v === 'object' ? Object.values(v) : []);
    const normalise = list => asArray(list).map(j => ({ ...j, grades: asArray(j.grades) }));

    // ---------- toasts ----------
    let toastWrap;
    function toast(msg, type) {
        if (!msg || !toastWrap) return;
        const tEl = el('div', `adm-toast ${type || ''}`);
        tEl.appendChild(el('div', 'lbl', type === 'error' ? t('adm_ui_error') : t('adm_ui_success')));
        tEl.appendChild(el('div', null, msg));
        toastWrap.appendChild(tEl);
        setTimeout(() => { tEl.classList.add('out'); setTimeout(() => tEl.remove(), 260); }, 3500);
    }

    // ---------- confirm modal ----------
    let modal, modalTitle, modalText, modalCb;
    function confirmBox(title, text, cb) {
        modalTitle.textContent = title;
        modalText.textContent = text;
        modalCb = cb;
        modal.classList.remove('hidden');
    }
    function closeModal() { modal.classList.add('hidden'); modalCb = null; }

    // ---------- skeleton ----------
    let listEl, countEl, mainEl, searchEl;

    function button(cls, icon, label, onClick) {
        const b = el('button', cls);
        b.append(iconEl(icon), el('span', null, ' ' + label));
        if (onClick) b.onclick = onClick;
        return b;
    }

    function buildShell() {
        root.innerHTML = '';
        const stage = el('div', 'stage');
        const panel = el('div', 'panel admin-panel');

        // header
        const head = el('div', 'panel-head');
        const seal = el('div', 'seal-badge'); seal.appendChild(iconEl('fa-solid fa-scroll'));
        const titles = el('div', 'panel-titles');
        titles.appendChild(el('h1', 'panel-title', t('adm_ui_title')));
        titles.appendChild(el('div', 'panel-subtitle', t('adm_ui_subtitle')));
        const close = el('button', 'circle-btn'); close.appendChild(iconEl('fa-solid fa-xmark'));
        close.onclick = requestClose;
        head.append(seal, titles, close);

        const div = el('div', 'section-divider'); div.appendChild(el('span', null, '◆'));

        // body
        const body = el('div', 'admin-body');
        const side = el('div', 'adm-side');
        searchEl = el('input', 'adm-input');
        searchEl.placeholder = t('adm_ui_search');
        searchEl.value = filter;
        searchEl.oninput = () => { filter = searchEl.value.toLowerCase(); renderList(); };

        const bar = el('div', 'adm-toolbar');
        bar.append(
            button('wood-btn', 'fa-solid fa-plus', t('adm_ui_new'), () => guard(startNew)),
            button('wood-btn wood-btn-muted', 'fa-solid fa-file-import', t('adm_ui_import'),
                () => confirmBox(t('adm_ui_import_title'), t('adm_ui_import_text'), doImport)),
        );

        countEl = el('div', 'adm-count');
        listEl = el('div', 'adm-list');
        side.append(searchEl, bar, countEl, listEl);

        mainEl = el('div', 'adm-main');
        body.append(side, mainEl);

        panel.append(head, div, body);
        stage.appendChild(panel);

        // modal
        modal = el('div', 'modal-wrap hidden');
        const m = el('div', 'modal');
        const mi = el('div', 'icon-badge modal-icon'); mi.appendChild(iconEl('fa-solid fa-exclamation'));
        modalTitle = el('h3', 'modal-title');
        modalText = el('p', 'modal-text');
        const ma = el('div', 'modal-actions');
        ma.append(
            button('wood-btn', 'fa-solid fa-check', t('adm_ui_confirm'), () => { const cb = modalCb; closeModal(); if (cb) cb(); }),
            button('wood-btn wood-btn-muted', 'fa-solid fa-xmark', t('adm_ui_cancel'), closeModal),
        );
        m.append(mi, modalTitle, el('div', 'ink-divider'), modalText, ma);
        modal.appendChild(m);

        toastWrap = el('div', 'adm-toasts');
        root.append(stage, modal, toastWrap);
    }

    // ---------- list ----------
    function renderList() {
        listEl.innerHTML = '';
        const shown = jobs.filter(j => !filter
            || j.label.toLowerCase().includes(filter)
            || j.name.includes(filter)
            || (j.type || '').toLowerCase().includes(filter));

        countEl.textContent = `${shown.length} / ${jobs.length} ${t('adm_ui_jobs_count')}`;

        shown.forEach(j => {
            const row = el('div', 'row-card adm-job' + (j.name === selected && !isNew ? ' selected' : ''));
            const badge = el('div', 'icon-badge'); badge.appendChild(iconEl(j.icon));
            const main = el('div', 'row-main');
            main.appendChild(el('span', 'row-title', j.label));
            main.appendChild(el('span', 'row-desc', `${j.name}${j.type ? ' · ' + j.type : ''} · ${j.grades.length} ${t('adm_ui_grades').toLowerCase()}`));
            const pill = el('span', 'pill pill-muted', `${j.holders}`);
            pill.title = `${j.holders} ${t('adm_ui_holders')} · ${j.active} ${t('adm_ui_active')}`;
            row.append(badge, main, pill);
            row.onclick = () => { if (j.name !== selected || isNew) guard(() => select(j.name)); };
            listEl.appendChild(row);
        });
    }

    // ---------- editor ----------
    function guard(fn) {
        if (isDirty()) confirmBox(t('adm_ui_discard_title'), t('adm_ui_discard_text'), fn);
        else fn();
    }

    function select(name) {
        if (name !== selected) { tab = 'details'; holders = null; }
        const j = jobs.find(x => x.name === name);
        if (!j) { selected = null; draft = null; isNew = false; renderList(); renderEditor(); return; }
        selected = name;
        isNew = false;
        draft = clone({
            name: j.name, label: j.label, type: j.type || '', icon: j.icon || '',
            defaultDuty: !!j.defaultDuty, offDutyPay: !!j.offDutyPay,
            grades: j.grades.map(g => ({ name: g.name, payment: Number(g.payment) || 0, isboss: !!g.isboss })),
        });
        original = JSON.stringify(draft);
        renderList();
        renderEditor();
    }

    function startNew() {
        tab = 'details';
        selected = null;
        isNew = true;
        draft = {
            name: '', label: '', type: '', icon: DEFAULT_ICON,
            defaultDuty: true, offDutyPay: false,
            grades: [{ name: 'Employee', payment: 0, isboss: false }, { name: 'Boss', payment: 0, isboss: true }],
        };
        original = JSON.stringify(draft);
        renderList();
        renderEditor();
        const first = mainEl.querySelector('input');
        if (first) first.focus();
    }

    function field(labelKey, input, hintKey) {
        const f = el('div', 'adm-field');
        f.appendChild(el('label', null, t(labelKey)));
        f.appendChild(input);
        if (hintKey) f.appendChild(el('span', 'adm-hint', t(hintKey)));
        return f;
    }

    function textInput(key, opts = {}) {
        const i = el('input', 'adm-input');
        i.type = 'text';
        i.value = draft[key] ?? '';
        if (opts.max) i.maxLength = opts.max;
        if (opts.placeholder) i.placeholder = opts.placeholder;
        if (opts.disabled) i.disabled = true;
        i.oninput = () => {
            let v = i.value;
            if (opts.slug) { v = v.toLowerCase().replace(/[^a-z0-9_]/g, ''); i.value = v; }
            draft[key] = v;
            if (opts.onChange) opts.onChange(v);
            updateFooter();
        };
        return i;
    }

    function toggle(labelKey, key) {
        const row = el('div', 'adm-toggle');
        row.appendChild(el('span', null, t(labelKey)));
        const sw = el('div', 'adm-switch' + (draft[key] ? ' on' : ''));
        row.appendChild(sw);
        row.onclick = () => { draft[key] = !draft[key]; sw.classList.toggle('on', draft[key]); updateFooter(); };
        return row;
    }

    let footerSave, footerRevert, footerDirty;

    function renderEditor() {
        closeDd();
        mainEl.innerHTML = '';
        footerSave = null;

        if (!draft) {
            const empty = el('div', 'adm-empty');
            empty.append(iconEl('fa-solid fa-briefcase'), el('div', 't', t('adm_ui_empty_title')), el('div', 's', t('adm_ui_empty_sub')));
            mainEl.appendChild(empty);
            return;
        }

        const scrollTop = 0;
        const ed = el('div', 'adm-editor');

        const h = el('div', 'adm-heading');
        const hb = el('div', 'icon-badge'); hb.appendChild(iconEl(draft.icon));
        h.append(hb, el('span', null, isNew ? t('adm_ui_new_title') : t('adm_ui_edit_title')));
        if (!isNew) {
            const j = jobs.find(x => x.name === selected);
            if (j) h.appendChild(el('span', 'pill pill-muted', `${j.holders} ${t('adm_ui_holders')} · ${j.active} ${t('adm_ui_active')}`));
        }
        ed.appendChild(h);

        if (canHaveEmployees()) {
            const tabs = el('div', 'adm-tabs');
            [['details', 'fa-solid fa-pen', 'adm_ui_tab_details'], ['employees', 'fa-solid fa-users', 'adm_ui_employees']].forEach(([id, icon, key]) => {
                const b = button('adm-tab' + (tab === id ? ' active' : ''), icon, t(key), () => {
                    if (tab === id) return;
                    tab = id;
                    renderEditor();
                    if (id === 'employees') loadHolders();
                });
                tabs.appendChild(b);
            });
            ed.appendChild(tabs);
        }

        if (tab === 'employees' && canHaveEmployees()) {
            renderEmployees(ed);
            mainEl.appendChild(ed);
            return;
        }

        const grid = el('div', 'adm-grid');
        grid.appendChild(field('adm_ui_name', textInput('name', { max: 50, slug: true, disabled: !isNew, placeholder: 'e.g. blacksmith' }), 'adm_ui_name_hint'));
        grid.appendChild(field('adm_ui_label', textInput('label', { max: 100, placeholder: 'e.g. Valentine Blacksmith' })));
        grid.appendChild(field('adm_ui_type', textInput('type', { max: 50, placeholder: 'leo' }), 'adm_ui_type_hint'));

        const iconRow = el('div', 'adm-icon-row');
        const prev = el('div', 'icon-badge'); prev.appendChild(iconEl(draft.icon));
        const iconIn = textInput('icon', {
            max: 100, placeholder: DEFAULT_ICON,
            onChange: v => {
                prev.innerHTML = ''; prev.appendChild(iconEl(v));
                hb.innerHTML = ''; hb.appendChild(iconEl(v));
            },
        });
        iconRow.append(prev, iconIn);
        grid.appendChild(field('adm_ui_icon', iconRow));

        const toggles = el('div', 'adm-toggles');
        toggles.append(toggle('adm_ui_default_duty', 'defaultDuty'), toggle('adm_ui_offduty_pay', 'offDutyPay'));
        grid.appendChild(toggles);
        ed.appendChild(grid);

        // grades
        const gh = el('div', 'adm-grades-head');
        gh.appendChild(el('span', 'adm-sub', `${t('adm_ui_grades')} (${draft.grades.length})`));
        const add = button('wood-btn wood-btn-muted', 'fa-solid fa-plus', t('adm_ui_add_grade'), () => {
            const st = ed.scrollTop;
            draft.grades.push({ name: '', payment: 0, isboss: false });
            renderEditor();
            const newEd = mainEl.querySelector('.adm-editor');
            if (newEd) newEd.scrollTop = st + 60;
            const inputs = mainEl.querySelectorAll('.adm-grade input[type=text]');
            if (inputs.length) inputs[inputs.length - 1].focus();
        });
        add.disabled = draft.grades.length >= 25;
        gh.appendChild(add);
        ed.appendChild(gh);

        const cols = el('div', 'adm-grade-cols');
        ['#', t('adm_ui_grade_name'), t('adm_ui_payment'), t('adm_ui_boss'), ''].forEach(c => cols.appendChild(el('span', null, c)));
        ed.appendChild(cols);

        const list = el('div', 'adm-grades');
        draft.grades.forEach((g, idx) => {
            const row = el('div', 'adm-grade');
            row.appendChild(el('div', 'adm-level', String(idx)));

            const n = el('input', 'adm-input');
            n.type = 'text'; n.maxLength = 50; n.value = g.name; n.placeholder = t('adm_ui_grade_name');
            n.oninput = () => { g.name = n.value; n.classList.toggle('invalid', !n.value.trim()); updateFooter(); };

            const payWrap = el('div', 'adm-pay');
            const p = el('input', 'adm-input');
            p.type = 'number'; p.min = '0'; p.step = '0.01'; p.value = g.payment;
            p.oninput = () => {
                const v = parseFloat(p.value);
                g.payment = isNaN(v) ? -1 : v;
                p.classList.toggle('invalid', isNaN(v) || v < 0);
                updateFooter();
            };
            payWrap.append(el('span', null, '$'), p);

            const sw = el('div', 'adm-switch' + (g.isboss ? ' on' : ''));
            sw.onclick = () => { g.isboss = !g.isboss; sw.classList.toggle('on', g.isboss); updateFooter(); };

            // Only the top grade can be removed so levels stay 0..n-1
            const rm = el('button', 'circle-btn sm'); rm.appendChild(iconEl('fa-solid fa-trash-can'));
            rm.disabled = idx !== draft.grades.length - 1 || draft.grades.length <= 1;
            rm.onclick = () => { const st = ed.scrollTop; draft.grades.pop(); renderEditor(); const ne = mainEl.querySelector('.adm-editor'); if (ne) ne.scrollTop = st; };

            row.append(n, payWrap, sw, rm);
            list.appendChild(row);
        });
        ed.appendChild(list);
        ed.appendChild(el('div', 'adm-note', t('adm_ui_required_note')));
        ed.scrollTop = scrollTop;
        mainEl.appendChild(ed);

        // footer
        const foot = el('div', 'adm-actions');
        if (!isNew && selected !== 'unemployed') {
            foot.appendChild(button('wood-btn wood-btn-muted wood-btn-danger', 'fa-solid fa-trash-can', t('adm_ui_delete'), () => {
                const j = jobs.find(x => x.name === selected);
                confirmBox(t('adm_ui_delete_title'), t('adm_ui_delete_text', j ? j.label : selected, j ? j.holders : 0), doDelete);
            }));
        }
        foot.appendChild(el('div', 'spacer'));
        footerDirty = el('span', 'adm-dirty');
        footerRevert = button('wood-btn wood-btn-muted', 'fa-solid fa-rotate-left', isNew ? t('adm_ui_cancel') : t('adm_ui_revert'), () => {
            if (isNew) { isNew = false; draft = null; renderList(); renderEditor(); }
            else select(selected);
        });
        footerSave = button('wood-btn', 'fa-solid fa-floppy-disk', isNew ? t('adm_ui_create') : t('adm_ui_save'), doSave);
        foot.append(footerDirty, footerRevert, footerSave);
        mainEl.appendChild(foot);
        updateFooter();
    }

    // ---------- employees ----------
    function canHaveEmployees() {
        return !isNew && selected && selected !== 'unemployed';
    }

    function gradeOptions() {
        const j = jobs.find(x => x.name === selected);
        return (j ? j.grades : []).map((g, i) => ({ value: i, label: `${i} · ${g.name}`, sub: g.isboss ? t('adm_ui_boss') : '' }));
    }

    // Pure HTML dropdown (never native <select> in RedM NUI).
    // opts.editable: free-text input with suggestions; onChange(value, picked)
    function setupDd(options, value, onChange, opts = {}) {
        const dd = el('div', 'dd');
        dd.dataset.value = value ?? '';
        let display;
        if (opts.editable) {
            display = el('input', 'dd-value dd-input');
            display.type = 'text';
            display.maxLength = 50;
            display.placeholder = opts.placeholder || '';
            display.value = value ?? '';
            display.oninput = () => { dd.dataset.value = display.value; onChange(display.value, null); renderMenu(display.value); openMenu(); };
            display.onfocus = () => { renderMenu(display.value); openMenu(); };
        } else {
            display = el('div', 'dd-value');
            const cur = options.find(o => String(o.value) === String(value));
            display.textContent = cur ? cur.label : (opts.placeholder || '');
            dd.onmousedown = e => {
                if (e.target.closest('.dd-menu')) return;
                e.preventDefault();
                dd.classList.contains('open') ? closeDd() : (renderMenu(''), openMenu());
            };
        }
        const arrow = el('span', 'dd-arrow', '▾');
        const menu = el('div', 'dd-menu');
        dd.append(display, arrow, menu);

        function renderMenu(q) {
            menu.innerHTML = '';
            const query = (q || '').toLowerCase();
            const shown = opts.editable && query
                ? options.filter(o => o.label.toLowerCase().includes(query) || String(o.value).toLowerCase().includes(query))
                : options;
            if (!shown.length) { menu.appendChild(el('div', 'dd-empty', opts.emptyText || '—')); return; }
            shown.forEach(o => {
                const row = el('div', 'dd-opt' + (String(o.value) === String(dd.dataset.value) ? ' selected' : ''));
                row.appendChild(el('span', null, o.label));
                if (o.sub) row.appendChild(el('span', 'dd-sub', o.sub));
                row.onmousedown = e => {
                    e.preventDefault(); // keep the pick when an editable input would blur
                    dd.dataset.value = o.value;
                    if (opts.editable) display.value = o.value; else display.textContent = o.label;
                    closeDd();
                    onChange(o.value, o);
                };
                menu.appendChild(row);
            });
        }
        function openMenu() {
            if (openDd && openDd !== dd) openDd.classList.remove('open');
            // open upwards when there isn't room below inside the scrolling editor
            const box = dd.closest('.adm-editor') || document.body;
            const below = box.getBoundingClientRect().bottom - dd.getBoundingClientRect().bottom;
            dd.classList.toggle('up', below < 210);
            dd.classList.add('open');
            openDd = dd;
        }
        return dd;
    }

    function closeDd() {
        if (openDd) openDd.classList.remove('open');
        openDd = null;
    }

    document.addEventListener('mousedown', e => { if (openDd && !e.target.closest('.dd')) closeDd(); });

    function loadHolders() {
        const job = selected;
        holders = null;
        renderEditor();
        post('admin:holders', { job }).then(res => {
            if (job !== selected || tab !== 'employees') return;
            if (!res || !res.ok) { toast(res && res.message ? res.message : t('adm_ui_error'), 'error'); holders = []; }
            else { holders = asArray(res.holders); onlinePlayers = asArray(res.players); }
            renderEditor();
        });
    }

    function applyEmployees(res) {
        busy = false;
        if (!res || !res.ok) {
            toast(res && res.message ? res.message : t('adm_ui_error'), 'error');
            renderEditor();
            return false;
        }
        holders = asArray(res.holders);
        onlinePlayers = asArray(res.players);
        if (res.jobs) jobs = normalise(res.jobs);
        toast(res.message, 'success');
        renderList();
        renderEditor();
        return true;
    }

    // form state survives re-renders
    const giveForm = { player: '', grade: 0, makeActive: true, bypassMax: false };

    function renderEmployees(ed) {
        const grades = gradeOptions();
        if (!grades.find(g => g.value === giveForm.grade)) giveForm.grade = 0;

        // give job form
        ed.appendChild(el('div', 'adm-sub adm-section', t('adm_ui_give_job')));
        const form = el('div', 'adm-give');

        const playerOpts = onlinePlayers.map(p => ({ value: String(p.id), label: `${p.name} (ID ${p.id})`, sub: p.citizenid }));
        const playerDd = setupDd(playerOpts, giveForm.player, v => { giveForm.player = String(v); updateAssign(); },
            { editable: true, placeholder: t('adm_ui_player_ph'), emptyText: t('adm_ui_no_online') });
        form.appendChild(field('adm_ui_player', playerDd, 'adm_ui_player_hint'));

        const gradeDd = setupDd(grades, giveForm.grade, v => { giveForm.grade = Number(v); });
        form.appendChild(field('adm_ui_grade', gradeDd));

        const toggles = el('div', 'adm-toggles');
        const mkToggle = (key, labelKey) => {
            const row = el('div', 'adm-toggle');
            row.appendChild(el('span', null, t(labelKey)));
            const sw = el('div', 'adm-switch' + (giveForm[key] ? ' on' : ''));
            row.appendChild(sw);
            row.onclick = () => { giveForm[key] = !giveForm[key]; sw.classList.toggle('on', giveForm[key]); };
            return row;
        };
        toggles.append(mkToggle('makeActive', 'adm_ui_make_active'), mkToggle('bypassMax', 'adm_ui_bypass_max'));
        form.appendChild(toggles);

        const assign = button('wood-btn', 'fa-solid fa-user-plus', t('adm_ui_assign'), () => {
            if (busy || !giveForm.player.trim()) return;
            busy = true; updateAssign();
            post('admin:assign', { job: selected, player: giveForm.player.trim(), grade: giveForm.grade, makeActive: giveForm.makeActive, bypassMax: giveForm.bypassMax })
                .then(res => { if (applyEmployees(res)) giveForm.player = ''; });
        });
        const updateAssign = () => { assign.disabled = busy || !giveForm.player.trim(); };
        updateAssign();
        const actions = el('div', 'adm-give-actions');
        actions.appendChild(assign);
        form.appendChild(actions);
        ed.appendChild(form);

        // employees list
        const count = holders ? holders.length : 0;
        ed.appendChild(el('div', 'adm-sub adm-section', `${t('adm_ui_employees')} (${count})`));

        if (holders === null) {
            ed.appendChild(el('div', 'adm-note', t('adm_ui_loading')));
            return;
        }
        if (!holders.length) {
            ed.appendChild(el('div', 'adm-note', t('adm_ui_no_employees')));
            return;
        }

        const cols = el('div', 'adm-emp-cols');
        ['', t('adm_ui_player'), t('adm_ui_grade'), ''].forEach(c => cols.appendChild(el('span', null, c)));
        ed.appendChild(cols);

        const list = el('div', 'adm-grades');
        holders.forEach(h => {
            const row = el('div', 'adm-emp');
            const dot = el('span', 'adm-dot' + (h.online ? ' on' : ''));
            dot.title = h.online ? t('adm_ui_online') : t('adm_ui_offline');

            const who = el('div', 'row-main');
            const title = el('span', 'row-title', h.name);
            if (h.active) title.appendChild(el('span', 'pill', t('adm_ui_active_job')));
            who.append(title, el('span', 'row-desc', `${h.citizenid}${h.online ? ` · ID ${h.id}` : ''}`));

            const gdd = setupDd(grades, h.grade, v => {
                if (busy || Number(v) === h.grade) return;
                busy = true;
                post('admin:setGrade', { job: selected, citizenid: h.citizenid, grade: Number(v) }).then(applyEmployees);
            });

            const rm = el('button', 'circle-btn sm'); rm.appendChild(iconEl('fa-solid fa-user-minus'));
            rm.title = t('adm_ui_remove_title');
            rm.onclick = () => {
                const j = jobs.find(x => x.name === selected);
                confirmBox(t('adm_ui_remove_title'), t('adm_ui_remove_text', h.name, j ? j.label : selected), () => {
                    if (busy) return;
                    busy = true;
                    post('admin:removeHolder', { job: selected, citizenid: h.citizenid }).then(applyEmployees);
                });
            };

            row.append(dot, who, gdd, rm);
            list.appendChild(row);
        });
        ed.appendChild(list);
    }

    function valid() {
        if (!draft) return false;
        if (!/^[a-z0-9_]{2,50}$/.test(draft.name)) return false;
        if (!draft.label.trim()) return false;
        if (!draft.grades.length) return false;
        return draft.grades.every(g => g.name.trim() && typeof g.payment === 'number' && g.payment >= 0);
    }

    function updateFooter() {
        if (!footerSave) return;
        const dirty = isDirty();
        footerSave.disabled = busy || !valid() || (!isNew && !dirty);
        footerRevert.disabled = busy || (!isNew && !dirty);
        footerDirty.textContent = dirty && !isNew ? '●' : '';
    }

    // ---------- server actions ----------
    function applyResult(res, keepName) {
        busy = false;
        if (!res || !res.ok) {
            toast(res && res.message ? res.message : t('adm_ui_error'), 'error');
            updateFooter();
            return;
        }
        jobs = normalise(res.jobs);
        toast(res.message, 'success');
        if (keepName && jobs.find(j => j.name === keepName)) select(keepName);
        else if (draft && !isNew && selected && jobs.find(j => j.name === selected)) { renderList(); }
        else { selected = null; isNew = false; draft = null; renderList(); renderEditor(); }
    }

    function doSave() {
        if (busy || !valid()) return;
        busy = true; updateFooter();
        const payload = {
            name: draft.name, label: draft.label.trim(), type: draft.type.trim(), icon: draft.icon.trim(),
            defaultDuty: draft.defaultDuty, offDutyPay: draft.offDutyPay,
            grades: draft.grades.map(g => ({ name: g.name.trim(), payment: g.payment, isboss: g.isboss })),
        };
        post('admin:save', { job: payload, isNew }).then(res => applyResult(res, res && res.saved));
    }

    function doDelete() {
        if (busy || !selected) return;
        busy = true;
        post('admin:delete', { name: selected }).then(res => applyResult(res, null));
    }

    function doImport() {
        if (busy) return;
        busy = true;
        post('admin:import').then(res => applyResult(res, null));
    }

    // ---------- open / close ----------
    function open(data) {
        L = data.locales || {};
        jobs = normalise(data.jobs);
        selected = null; isNew = false; draft = null; busy = false;
        tab = 'details'; holders = null; onlinePlayers = [];
        buildShell();
        renderList();
        renderEditor();
        root.classList.remove('hidden');
    }

    function hide() {
        closeDd();
        root.classList.add('hidden');
        root.innerHTML = '';
        draft = null;
        modal = null;
        toastWrap = null;
    }

    function requestClose() {
        guard(() => { draft = null; post('admin:close'); hide(); });
    }

    window.addEventListener('message', e => {
        const d = e.data || {};
        if (d.action === 'admin:open') open(d);
        else if (d.action === 'admin:close') hide();
    });

    document.addEventListener('keydown', e => {
        if (e.key !== 'Escape' || root.classList.contains('hidden')) return;
        if (openDd) { closeDd(); return; }
        if (modal && !modal.classList.contains('hidden')) closeModal();
        else requestClose();
    });
})();
