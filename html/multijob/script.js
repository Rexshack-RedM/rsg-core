let selectedJob = null;
let confirmCallback = null;

// Filled from locales/<lang>.json (ui_* keys) via the 'open' NUI message.
let L = {};

function fmt(str, value) {
    return (str || '').replace('%s', value);
}

function post(endpoint, data) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).catch(function() {});
}

// Elements whose text comes straight from a locale key
const TEXT_BINDINGS = {
    panelTitle: 'ui_my_jobs',
    panelSubtitle: 'ui_subtitle',
    dutyLabel: 'ui_duty_label',
    capacityLabel: 'ui_capacity_label',
    maxJobsFooterLabel: 'ui_max_jobs_footer',
    choiceTitle: 'ui_job_actions',
    choiceSubtitle: 'ui_select_action',
    switchJobTitle: 'ui_switch_job',
    switchJobDesc: 'ui_switch_desc',
    deleteJobTitle: 'ui_delete_job',
    deleteJobDesc: 'ui_delete_desc',
    confirmTitle: 'ui_confirm_title',
    confirmText: 'ui_confirm_text',
    confirmYesLabel: 'ui_confirm',
    confirmNoLabel: 'ui_cancel'
};

const TITLE_BINDINGS = {
    closeBtn: 'ui_close',
    choiceCloseBtn: 'ui_close',
    backBtn: 'ui_back',
    dragHandle: 'ui_drag_hint',
    choiceDragHandle: 'ui_drag_hint'
};

function t(key) {
    return L[key] || '';
}

function applyLocale(locales) {
    if (!locales) return;
    L = locales;

    document.title = t('ui_page_title');
    Object.keys(TEXT_BINDINGS).forEach(function(id) {
        const el = document.getElementById(id);
        if (el) el.textContent = t(TEXT_BINDINGS[id]);
    });
    Object.keys(TITLE_BINDINGS).forEach(function(id) {
        const el = document.getElementById(id);
        if (el) el.title = t(TITLE_BINDINGS[id]);
    });
}

function show(el) { el.classList.remove('hidden'); }
function hide(el) { el.classList.add('hidden'); }
function isVisible(el) { return !el.classList.contains('hidden'); }

// ==================== DRAG FUNCTIONALITY ====================
// Both panels share one offset (applied as a transform), so the menu stays
// where the player left it when switching panels or reopening.
const DRAG_KEY = 'rsg-core:multijob:offset';
let dragOffset = { x: 0, y: 0 };

try {
    const saved = JSON.parse(localStorage.getItem(DRAG_KEY));
    if (saved && isFinite(saved.x) && isFinite(saved.y)) dragOffset = saved;
} catch (e) {}

function panels() {
    return [document.getElementById('mainContainer'), document.getElementById('choiceContainer')];
}

function applyOffset() {
    panels().forEach(function(el) {
        el.style.transform = `translate(${dragOffset.x}px, ${dragOffset.y}px)`;
    });
}

// Keep at least part of the header on screen
function clampOffset(el) {
    el.style.transform = 'none';
    const r = el.getBoundingClientRect();
    const margin = 60;
    const minX = margin - r.right, maxX = window.innerWidth - margin - r.left;
    const minY = -r.top, maxY = window.innerHeight - margin - r.top;
    dragOffset.x = Math.min(maxX, Math.max(minX, dragOffset.x));
    dragOffset.y = Math.min(maxY, Math.max(minY, dragOffset.y));
}

function saveOffset() {
    try { localStorage.setItem(DRAG_KEY, JSON.stringify(dragOffset)); } catch (e) {}
}

function makeDraggable(element, handle) {
    let startX = 0, startY = 0, baseX = 0, baseY = 0;

    handle.addEventListener('mousedown', function(e) {
        if (e.button !== 0 || e.target.closest('.circle-btn')) return;
        e.preventDefault();
        startX = e.clientX;
        startY = e.clientY;
        baseX = dragOffset.x;
        baseY = dragOffset.y;
        element.classList.add('dragging');
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onUp);
    });

    function onMove(e) {
        dragOffset.x = baseX + (e.clientX - startX);
        dragOffset.y = baseY + (e.clientY - startY);
        clampOffset(element);
        applyOffset();
    }

    function onUp() {
        element.classList.remove('dragging');
        document.removeEventListener('mousemove', onMove);
        document.removeEventListener('mouseup', onUp);
        saveOffset();
    }
}

// Double-click a header to put the menu back in the centre
function resetOffset() {
    dragOffset = { x: 0, y: 0 };
    applyOffset();
    saveOffset();
}

document.addEventListener('DOMContentLoaded', function() {
    makeDraggable(document.getElementById('mainContainer'), document.getElementById('dragHandle'));
    makeDraggable(document.getElementById('choiceContainer'), document.getElementById('choiceDragHandle'));
    document.getElementById('dragHandle').addEventListener('dblclick', resetOffset);
    document.getElementById('choiceDragHandle').addEventListener('dblclick', resetOffset);
    applyOffset();
});

// ==================== UI UPDATES ====================
function updateDutyStatus(onDuty) {
    const dutyIcon = document.getElementById('dutyIcon');
    const dutyStatus = document.getElementById('dutyStatus');
    const dutyIndicator = document.getElementById('dutyIndicator');

    if (onDuty) {
        dutyIcon.innerHTML = '<i class="fa-solid fa-toggle-on"></i>';
        dutyStatus.textContent = t('ui_on_duty');
        dutyStatus.className = 'row-desc duty-status on-duty';
        dutyIndicator.className = 'duty-indicator on-duty';
    } else {
        dutyIcon.innerHTML = '<i class="fa-solid fa-toggle-off"></i>';
        dutyStatus.textContent = t('ui_off_duty');
        dutyStatus.className = 'row-desc duty-status off-duty';
        dutyIndicator.className = 'duty-indicator off-duty';
    }
}

function updateCapacity(count, max) {
    const safeMax = Math.max(1, parseInt(max, 10) || 6);
    const safeCount = Math.max(0, parseInt(count, 10) || 0);
    const pct = Math.min(100, (safeCount / safeMax) * 100);

    document.getElementById('jobCount').textContent = safeCount;
    document.getElementById('maxJobs').textContent = safeMax;
    document.getElementById('maxJobsFooter').textContent = safeMax;

    const fill = document.getElementById('capacityFill');
    fill.style.width = pct + '%';
    fill.classList.remove('stat-good', 'stat-warn', 'stat-bad');
    if (pct >= 85) fill.classList.add('stat-bad');
    else if (pct >= 60) fill.classList.add('stat-warn');
    else fill.classList.add('stat-good');
}

function createJobCard(job, isCurrentJob) {
    const card = document.createElement('div');
    card.className = 'row-card job-card' + (isCurrentJob ? ' current-job' : '');
    card.dataset.job = job.job;
    card.dataset.jobLabel = job.jobLabel;
    card.dataset.grade = job.grade;

    const iconBadge = document.createElement('div');
    iconBadge.className = 'icon-badge';
    const icon = document.createElement('i');
    icon.className = job.icon || 'fa-solid fa-briefcase';
    iconBadge.appendChild(icon);

    const rowMain = document.createElement('div');
    rowMain.className = 'row-main';

    const title = document.createElement('div');
    title.className = 'row-title';
    title.textContent = job.jobLabel;

    const gradeDesc = document.createElement('div');
    gradeDesc.className = 'row-desc';
    const gradeEm = document.createElement('i');
    gradeEm.textContent = `${t('ui_grade')}: ${job.gradeLabel} [${job.grade}]`;
    gradeDesc.appendChild(gradeEm);

    const salaryDesc = document.createElement('div');
    salaryDesc.className = 'row-desc job-salary';
    salaryDesc.textContent = `${t('ui_salary')}: $${job.salary}`;

    rowMain.appendChild(title);
    rowMain.appendChild(gradeDesc);
    rowMain.appendChild(salaryDesc);

    card.appendChild(iconBadge);
    card.appendChild(rowMain);

    if (isCurrentJob) {
        const pill = document.createElement('span');
        pill.className = 'pill';
        pill.textContent = t('ui_current_pill');
        card.appendChild(pill);
    }

    const arrow = document.createElement('div');
    arrow.className = 'row-arrow';
    arrow.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
    card.appendChild(arrow);

    // The current job can still be opened so it can be resigned (deleted)
    card.addEventListener('click', function() {
        openChoiceMenu(job, isCurrentJob);
    });

    return card;
}

let lastJobs = [];
let lastCurrentJob = null;

function renderJobs(jobs, currentJobName) {
    lastJobs = jobs || [];
    lastCurrentJob = currentJobName;
    const container = document.getElementById('jobsContainer');
    container.innerHTML = '';

    if (!jobs || jobs.length === 0) {
        const noJobs = document.createElement('div');
        noJobs.className = 'no-jobs';

        const noJobsIcon = document.createElement('div');
        noJobsIcon.className = 'no-jobs-icon';
        noJobsIcon.innerHTML = '<i class="fa-solid fa-briefcase"></i>';

        const noJobsText = document.createElement('div');
        noJobsText.className = 'no-jobs-text';
        noJobsText.textContent = t('ui_no_jobs_title');

        const noJobsSubtext = document.createElement('div');
        noJobsSubtext.className = 'no-jobs-subtext';
        const noJobsSubtextEm = document.createElement('i');
        noJobsSubtextEm.textContent = t('ui_no_jobs_sub');
        noJobsSubtext.appendChild(noJobsSubtextEm);

        noJobs.appendChild(noJobsIcon);
        noJobs.appendChild(noJobsText);
        noJobs.appendChild(noJobsSubtext);
        container.appendChild(noJobs);

        const maxEl = document.getElementById('maxJobs');
        updateCapacity(0, maxEl ? maxEl.textContent : 6);
        return;
    }

    jobs.forEach((job, index) => {
        const isCurrentJob = job.job === currentJobName;
        const card = createJobCard(job, isCurrentJob);
        card.style.animationDelay = (index * 0.05) + 's';
        container.appendChild(card);
    });

    const maxEl = document.getElementById('maxJobs');
    updateCapacity(jobs.length, maxEl ? maxEl.textContent : 6);
}

// ==================== CHOICE MENU ====================
function openChoiceMenu(job, isCurrentJob) {
    selectedJob = job;
    document.getElementById('switchJobBtn').classList.toggle('hidden', !!isCurrentJob);

    hide(document.getElementById('mainContainer'));
    const choice = document.getElementById('choiceContainer');
    show(choice);
    document.getElementById('choiceJobName').textContent = job.jobLabel;
}

function closeChoiceMenu() {
    hide(document.getElementById('choiceContainer'));
    const main = document.getElementById('mainContainer');
    show(main);
    selectedJob = null;
}

// ==================== CONFIRM MODAL ====================
function showConfirm(title, text, callback) {
    confirmCallback = callback;
    document.getElementById('confirmTitle').textContent = title;
    document.getElementById('confirmText').textContent = text;
    show(document.getElementById('confirmModal'));
}

function hideConfirm() {
    hide(document.getElementById('confirmModal'));
    confirmCallback = null;
    document.getElementById('confirmTitle').textContent = t('ui_confirm_title');
    document.getElementById('confirmText').textContent = t('ui_confirm_text');
}

// ==================== EVENT LISTENERS ====================
document.getElementById('closeBtn').addEventListener('click', function() {
    closeUI();
});

document.getElementById('choiceCloseBtn').addEventListener('click', function() {
    closeUI();
});

document.getElementById('backBtn').addEventListener('click', function() {
    closeChoiceMenu();
});

document.getElementById('dutyToggle').addEventListener('click', function() {
    post('multijob:toggleDuty');
});

document.getElementById('switchJobBtn').addEventListener('click', function() {
    if (!selectedJob) return;

    showConfirm(
        t('ui_switch_confirm_title'),
        fmt(t('ui_switch_confirm_text'), selectedJob.jobLabel),
        function() {
            const newJob = selectedJob.job;
            post('multijob:switchJob', { job: newJob });
            // Update the highlight straight away; the server refresh confirms it
            renderJobs(lastJobs, newJob);
            hideConfirm();
            closeChoiceMenu();
        }
    );
});

document.getElementById('deleteJobBtn').addEventListener('click', function() {
    if (!selectedJob) return;

    showConfirm(
        t('ui_delete_confirm_title'),
        fmt(t('ui_delete_confirm_text'), selectedJob.jobLabel),
        function() {
            post('multijob:deleteJob', { job: selectedJob.job });
            hideConfirm();
            closeChoiceMenu();
        }
    );
});

document.getElementById('confirmYes').addEventListener('click', function() {
    const cb = confirmCallback;
    confirmCallback = null; // prevent double-submit
    if (cb) cb();
});

document.getElementById('confirmNo').addEventListener('click', function() {
    hideConfirm();
});

// Close on escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && isVisible(document.getElementById('app'))) {
        if (isVisible(document.getElementById('confirmModal'))) {
            hideConfirm();
        } else if (isVisible(document.getElementById('choiceContainer'))) {
            closeChoiceMenu();
        } else {
            closeUI();
        }
    }
});

// ==================== NUI CALLBACKS ====================
function openUI() {
    show(document.getElementById('app'));
    show(document.getElementById('mainContainer'));
    hide(document.getElementById('choiceContainer'));
    hide(document.getElementById('confirmModal'));
    applyOffset();
}

function closeUI() {
    hide(document.getElementById('mainContainer'));
    hide(document.getElementById('choiceContainer'));
    hideConfirm();
    hide(document.getElementById('app'));

    post('multijob:closeUI');
}

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'multijob:open') {
        applyLocale(data.locales);
        openUI();

        updateDutyStatus(data.onDuty);
        document.getElementById('maxJobs').textContent = data.maxJobs || 6;
        document.getElementById('maxJobsFooter').textContent = data.maxJobs || 6;
        renderJobs(data.jobs, data.currentJob);
    }

    if (data.action === 'multijob:updateDuty') {
        updateDutyStatus(data.onDuty);
        if (data.currentJob && data.currentJob !== lastCurrentJob) {
            renderJobs(lastJobs, data.currentJob);
        }
    }

    if (data.action === 'multijob:refreshJobs') {
        renderJobs(data.jobs, data.currentJob);
    }
});
